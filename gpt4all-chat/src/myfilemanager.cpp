#include "myfilemanager.h"

#include <QFile>
#include <QDir>
#include <QTextStream>
#include <QStringList>
#include <QDebug>

// Constructor implementation
MyFileManager::MyFileManager(QObject *parent) : QObject(parent) {}

// Implementation of saveHtmlFiles function
void MyFileManager::saveHtmlFiles(const QString &collectionName, const QString &baseFolderPath, const QVariantList &linksData) {
    // Construct the full path
    QString fullPath = baseFolderPath + "/" + collectionName;

    // Check if the directory exists; if not, create it
    QDir dir(fullPath);
    if (!dir.exists()) {
        if (!dir.mkpath(fullPath)) {
            qWarning() << "Failed to create directory:" << fullPath;
            emit errorSaving("Failed to create directory");
            return;
        }
    }

    // Iterate over the HTML content and save each to a separate file
    for (int i = 0; i < linksData.size(); ++i) {
        QVariantMap item = linksData[i].toMap();
        QString htmlContent = item["html"].toString();
        QString fileName = QString("page_%1.html").arg(i + 1);
        QString filePath = fullPath + "/" + fileName;

        QFile file(filePath);
        if (file.open(QIODevice::WriteOnly | QIODevice::Text)) {
            QTextStream stream(&file);
            stream.setCodec("UTF-8");
            stream << htmlContent;
            file.close();
            qDebug() << "Saved HTML file:" << filePath;
        } else {
            qWarning() << "Failed to open file for writing:" << filePath;
            emit errorSaving("Failed to open file for writing");
        }
    }

    qDebug() << "HTML files saved in directory:" << fullPath;
    emit successSaving(); // Emit success signal
}

