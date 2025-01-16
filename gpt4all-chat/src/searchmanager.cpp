#include "SearchManager.h"
#include <QWebEngineView>
#include <QWebEnginePage>
#include <QWebEngineProfile>
#include <QApplication>
#include <QFile>
#include <QDir>
#include <QDebug>
#include <QAuthenticator>

#include <QNetworkRequest>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUrl>
#include <QDesktopServices>
#include <QApplication>
#include <QFile>
#include <QDir>
#include <QWebEnginePage>
#include <QProcess>
#include <QAuthenticator>
#include <QWebEngineSettings>
#include "SearchManager.h"
#include <QDir>
#include <QRegularExpression>
#include <QTimer>

SearchManager::SearchManager(QObject *parent)
    : QObject(parent) {}

void SearchManager::fetchAndSave(const QString &searchTerm, const QString &collectionName, const QString &baseFolderPath, const QString &scriptName) {
    QString fullPath = baseFolderPath + "/" + collectionName;

    // Ensure the target directory exists
    QDir dir(fullPath);
    if (!dir.exists() && !dir.mkpath(fullPath)) {
        qWarning() << "Failed to create directory:" << fullPath;
        return;
    }

    QProcess *process = new QProcess(this); // Create QProcess instance
    QString pythonScript = QString("/mnt/c/Users/franc/Github/gpt4all/gpt4all-chat/%1.py").arg(scriptName);

    // Construct the command arguments
    QStringList arguments;
    arguments << "/home/franky/miniconda3/bin/python3" // Path to Python in WSL
              << pythonScript
              << "--query" << searchTerm
              << "--output" << fullPath;

    // Use WSL as the executable
    process->setProgram("wsl");
    process->setArguments(arguments);

    // Connect signals for real-time updates
    connect(process, &QProcess::readyReadStandardOutput, [process, this]() {
        // Read and parse the JSON progress output
        while (process->canReadLine()) {
            QByteArray outputLine = process->readLine().trimmed();
            QJsonDocument jsonDoc = QJsonDocument::fromJson(outputLine);
            if (!jsonDoc.isNull() && jsonDoc.isObject()) {
                QJsonObject jsonObj = jsonDoc.object();
                int progress = jsonObj.value("progress").toInt();
                QString status = jsonObj.value("status").toString();

                // Extract failedLinks and failedPercentage if available
                QStringList failedLinks;
                int failedPercentage = 0;

                if (jsonObj.contains("failed_links")) {
                    QJsonArray failedArray = jsonObj["failed_links"].toArray();
                    for (const auto &link : failedArray) {
                        failedLinks.append(link.toString());
                    }
                }

                if (jsonObj.contains("failed_percentage")) {
                    failedPercentage = jsonObj["failed_percentage"].toInt();
                }

                // Emit signal to update progress in UI or logs
                emit progressUpdated(progress, status, failedLinks, failedPercentage);

                qDebug() << "Progress:" << progress << "% -" << status;
            }
        }
    });

    // Handle process completion
    connect(process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            [process](int exitCode, QProcess::ExitStatus exitStatus) {
                if (exitCode == 0 && exitStatus == QProcess::NormalExit) {
                    qDebug() << "Python script completed successfully.";
                } else {
                    qWarning() << "Python script failed with exit code:" << exitCode;
                    qWarning() << "Error:" << process->readAllStandardError();
                }
                process->deleteLater();
            });

    // Start the process
    process->start();

    if (!process->waitForStarted()) {
        qWarning() << "Failed to start Python script.";
        process->deleteLater();
        return;
    }

    qDebug() << "Python script started successfully.";
}

