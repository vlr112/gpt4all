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


// Constructor
// SearchManager::SearchManager(QObject *parent) : QObject(parent) {}

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

    QProcess process;
    QString pythonScript =  QString("/mnt/c/Users/franc/Github/gpt4all/gpt4all-chat/%1.py").arg(scriptName);


    // Construct the command arguments
    QStringList arguments;
    arguments << "--" << "/home/franky/miniconda3/bin/python3"
              << pythonScript
              << "--query" << searchTerm
              << "--output" << fullPath;

    // Use wsl as the executable and pass the arguments
    process.start("wsl", arguments);
    process.waitForFinished(-1); // Wait until the process is finished

    // Handle the output and errors
    if (process.exitCode() == 0) {
        qDebug() << "MHTML file saved successfully:" << fullPath;
        qDebug() << "Output:" << process.readAllStandardOutput();
    } else {
        qWarning() << "Failed to save MHTML. Error:" << process.readAllStandardError();
    }
}




