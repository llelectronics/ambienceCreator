#ifndef AMBIENCECREATOR_H
#define AMBIENCECREATOR_H

#include <QtCore/QObject>
#include <QtCore/QFile>
#include <QDir>
#include <QFileInfo>
#include <QString>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>

#include <QDebug>

class ambienceCreator : public QObject
{   Q_OBJECT

private:
    QString ambienceTempDir;
    QString ambienceName;
    QByteArray fileData;
    QFile file;
    QJsonDocument jsonDoc;
    QJsonObject json;

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
                if (!cpFile(newSrcFilePath, newTgtFilePath))
                    return false;
            }
        }
        else return QFile(source).copy(target);
        return true;
    }
    bool replaceText(const QString &fileName, const QString &txt, const QString &replaceTxt)
    {
        QByteArray fileData;
        QFile file(fileName);
        file.open(stderr, QIODevice::ReadWrite); // open for read and write
        fileData = file.readAll(); // read all the data into the byte array
        QString text(fileData); // add to text string for easy string replace

        text.replace(txt, replaceTxt); // replace text in string

        file.seek(0); // go to the beginning of the file
        if (file.write(text.toUtf8()) == -1) return false; // write the new text back to the file

        file.close(); // close the file handle.
        return true;
    }
    bool loadJson(const QString &fileName)
    {
        file.setFileName(fileName);
        if (!file.open(stderr, QIODevice::ReadWrite)) return false; // open for read and write
        fileData = file.readAll(); // read all the data into the byte array

        jsonDoc = QJsonDocument::fromJson(fileData); // TODO: Error handling
        json = jsonDoc.object();
        return true;
    }
    bool writeJson()
    {
        if (file.write(jsonDoc.toJson()) == -1) return false;
        file.close();
        return true;
    }
    bool replaceJson(const QString &fileName, const QString &key, const QString &value)
    {
        if (!loadJson(fileName)) return false;
        json[key] = value;
        if (!writeJson()) return false;
        return true;
    }
    bool copyTemplate()
    {
        QDir aTD = ambienceTempDir;
        if (!aTD.exists()) aTD.mkdir(ambienceTempDir);
        if (!cpFile("/usr/share/harbour-ambianceCreator/qml/pages/ambience-template", ambienceTempDir)) return false;
        if (!QDir(ambienceTempDir+ "/sounds").exists()) QDir(ambienceTempDir).mkdir("sounds");
        return true;
    }
    bool renameFiles()
    {
        if (!QFile::rename(ambienceTempDir + "/ambience-template.spec", ambienceTempDir + "/ambiance-"+ambienceName + ".spec")) return false;
        if (!QFile::rename(ambienceTempDir + "/ambience-template.ambience", ambienceTempDir + "/ambience-"+ambienceName + ".ambience")) return false;
        if (!QFile::rename(ambienceTempDir + "/images/ambience-template.jpg", ambienceTempDir + "/images/ambience-"+ambienceName + ".jpg")) return false;
        return true;
    }
    bool copySound(const QString &source, const QString &soundName)
    {
        //Copy source to ambiencTempDir + "/sounds/" + ambienceName + "-" + type
        if (!cpFile(source,ambienceTempDir + "/sounds/" + soundName)) return false;
        return true;
    }
    QString getSoundName(const QString &type, const QString &source)
    {
        // Get suffix of source
        QFileInfo fi(source);
        QString ext = fi.completeSuffix();  // ext = "flac"
        return "ambience-" + ambienceName + "-" + type + "." + ext;
    }
    bool setAmbienceName()
    {
        if (!replaceText(ambienceTempDir + "/"+ambienceName + ".spec", "ambience-template", "ambience-" + ambienceName)) return false;
        if (!replaceText(ambienceTempDir + "/sounds.index", "ambience-template", "ambience-" + ambienceName)) return false;
        // Json stuff (key, value)
        if (!replaceJson(ambienceTempDir + "/"+ambienceName + ".ambience", "translationCatalog", "ambience-" + ambienceName)) return false;
        if (!replaceJson(ambienceTempDir + "/"+ambienceName + ".ambience", "displayName", "ambience-" + ambienceName)) return false;
        return true;
    }
    bool JsonSetColor(const QString key, const QString col)
    {
        if (!replaceJson(ambienceTempDir + "/"+ambienceName + ".ambience", key, col)) return false;
        return true;
    }
    bool JsonSetSound(const QString key, const QString sound)
    {
        loadJson(ambienceTempDir + "/sounds.index");
        if (json.contains("files") && json["files"].isArray()) {
            QJsonArray filesArray = json["files"].toArray();
            for (int filesIndex = 0; filesIndex < filesArray.size(); ++filesIndex) {
                QJsonObject filesObject = filesArray[filesIndex].toObject();
                if (filesObject.contains("displayName")) {
                    if (filesObject["displayName"] == key) {
                        filesObject["fileName"] = sound;
                    }
                }
            }
        }
        if (!writeJson()) return false;
        return true;
    }

public slots:
    bool prepareRPM(const QString &ambienceN)
    {
        ambienceTempDir = "/tmp/" + ambienceName;
        ambienceName = ambienceN;
        if (!copyTemplate()) return false;
        if (!renameFiles()) return false;
        if (!setAmbienceName()) return false;
        return true;
    }
    bool setColor(const QString highlightColor, const QString secondaryHighlightColor, const QString primaryColor, const QString secondaryColor)
    {
        if (!JsonSetColor("highlightColor", highlightColor)) return false;
        if (!JsonSetColor("secondaryHighlightColor", secondaryHighlightColor)) return false;
        if (!JsonSetColor("primaryColor", primaryColor)) return false;
        if (!JsonSetColor("secondaryColor", secondaryColor)) return false;
        return true;
    }
    bool setSounds(const QString ringerTone, const QString messageTone, const QString chatTone, const QString imTone, const QString mailTone, const QString calendarTone, const QString clockAlarmTone)
    {

        if (!ringerTone.isEmpty()) {
            if (!copySound(ringerTone,getSoundName("ringtone", ringerTone))) return false;
            if (!JsonSetSound("ambience-" + ambienceName + "ringtone", getSoundName("ringtone", ringerTone))) return false;
        }
        if (!messageTone.isEmpty()) {
            if (!copySound(messageTone,getSoundName("messagetone", messageTone))) return false;
            if (!JsonSetSound("ambience-" + ambienceName + "messagetone", getSoundName("messagetone", messageTone))) return false;
        }
        if (!chatTone.isEmpty()) {
            if (!copySound(chatTone,getSoundName("chattone", chatTone))) return false;
            if (!JsonSetSound("ambience-" + ambienceName + "chattone", getSoundName("chattone", chatTone))) return false;
        }
        if (!imTone.isEmpty()) {
            if (!copySound(imTone,getSoundName("imtone", imTone))) return false;
            if (!JsonSetSound("ambience-" + ambienceName + "imtone", getSoundName("imtone", imTone))) return false;
        }
        if (!mailTone.isEmpty()) {
            if (!copySound(mailTone,getSoundName("mailtone", mailTone))) return false;
            if (!JsonSetSound("ambience-" + ambienceName + "mailtone", getSoundName("mailtone", mailTone))) return false;
        }
        if (!calendarTone.isEmpty()) {
            if (!copySound(calendarTone,getSoundName("calendar-alarm", calendarTone))) return false;
            if (!JsonSetSound("ambience-" + ambienceName + "calendar-alarm", getSoundName("calendar-alarm", calendarTone))) return false;
        }
        if (!clockAlarmTone.isEmpty()) {
            if (!copySound(clockAlarmTone,getSoundName("clock-alarm", clockAlarmTone))) return false;
            if (!JsonSetSound("ambience-" + ambienceName + "clock-alarm", getSoundName("clock-alarm", clockAlarmTone))) return false;
        }
        return true;

    }


};


#endif // AMBIENCECREATOR_H
