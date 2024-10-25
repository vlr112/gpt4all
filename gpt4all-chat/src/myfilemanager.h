#ifndef MYFILEMANAGER_H
#define MYFILEMANAGER_H

#include <QObject>
#include <QVariantList>
#include <QString>

class MyFileManager : public QObject
{
    Q_OBJECT

    public:
        explicit MyFileManager(QObject *parent = nullptr);  // Constructor

        // Expose this function to QML to save HTML files
        Q_INVOKABLE void saveHtmlFiles(const QString &collectionName, const QString &baseFolderPath, const QVariantList &linksData);

    signals:
        void successSaving();      // Signal to indicate success
        void errorSaving(QString); // Signal to indicate error with a message

};

#endif // MYFILEMANAGER_H
