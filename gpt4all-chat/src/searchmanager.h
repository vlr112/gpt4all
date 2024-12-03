#ifndef SEARCHMANAGER_H
#define SEARCHMANAGER_H

#include <QObject>
#include <QWebEngineView>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QVariantList>
#include <QWebEnginePage>
#include <QApplication>
#include <QWebEngineDownloadRequest>
#include <QWebEngineProfile>
#include <QString>
#include <QDebug>
#include <QStringList>

class SearchManager : public QObject {
    Q_OBJECT

public:
    explicit SearchManager(QObject *parent = nullptr);

    Q_INVOKABLE void fetchAndSave(const QString &searchTerm, const QString &collectionName, const QString &baseFolderPath, const QString &scriptName);

};


#endif // SEARCHMANAGER_H

