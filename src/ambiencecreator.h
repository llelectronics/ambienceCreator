#ifndef AMBIENCECREATOR_H
#define AMBIENCECREATOR_H

#include <QtCore/QObject>
#include <QtCore/QFile>
#include <QDir>
#include <QFileInfo>
#include <QString>

#include <QDebug>

class ambienceCreator : public QObject
{   Q_OBJECT

private:
    QString ambienceTempDir;
    QString ambienceName;
private slots:
    bool cpFile(const QString &source, const QString &target)
    {
        QFileInfo srcFileInfo(source);
        if (srcFileInfo.isDir()) {
            QDir targetDir(target);
            if (!targetDir.isRoot()) targetDir.cdUp();
            if (!targetDir.mkdir(QFileInfo(target).fileName()))
                return false;
            QDir sourceDir(source);
            QStringList fileNames = sourceDir.entryList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot | QDir::Hidden | QDir::System);
            foreach (const QString &fileName, fileNames) {
                const QString newSrcFilePath
                        = source + QLatin1Char('/') + fileName;
                const QString newTgtFilePath
                        = target + QLatin1Char('/') + fileName;
                if (!copyFile(newSrcFilePath, newTgtFilePath))
                    return false;
            }
        }
        else return QFile(source).copy(target);
        return true;
    }
    bool copyTemplate()
    {
        if (!QDir(ambienceTempDir).exists()) QDir(ambienceTempDir).mkdir();
        if (!cpFile("/usr/share/harbour-ambianceCreator/qml/pages/ambience-template", ambienceTempDir)) return false;
        if (!QDir(ambienceTempDir+ "/sounds").exists()) QDir(ambienceTempDir).mkdir("sounds");
        return true;
    }
    bool renameFiles()
    {
        if (!QFile::rename(ambienceTempDir + "/ambience-template.spec", ambienceTempDir + "/"+ambienceName + ".spec")) return false;
        if (!QFile::rename(ambienceTempDir + "/ambience-template.ambience", ambienceTempDir + "/"+ambienceName + ".ambience")) return false;
        if (!QFile::rename(ambienceTempDir + "/images/ambience-template.jpg", ambienceTempDir + "/images/"+ambienceName + ".jpg")) return false;
        return true;
    }
    bool copySound(const QString &type, const QString &source)
    {
      //Copy source to ambiencTempDir + "/sounds/" + ambienceName + "-" + type
    }

public slots:
    bool prepareRPM(const QString &ambienceN)
    {
        ambienceTempDir = "/tmp/" + ambienceName;
        ambienceName = ambienceN;
        if (!copyTemplate()) return false;
        if (!renameFiles()) return false;
    }



};


#endif // AMBIENCECREATOR_H
