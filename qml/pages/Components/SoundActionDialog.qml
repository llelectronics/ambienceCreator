import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: root

    signal soundActionClicked(string ident, string path)

    PageHeader {
        id: head
        title: qsTr("Choose Soundaction")
    }
    SilicaListView {
        anchors {
            left: parent.left
            right: parent.right
            top: head.bottom
            bottom: parent.bottom
            margins: Theme.horizontalPageMargin
        }
        model: ListModel {
            id: soundActionList
            ListElement {
                label: qsTr("Ringtone")
                ident: "ringerTone"
            }
            ListElement {
                label: qsTr("Message")
                ident: "messageTone"
            }
            ListElement {
                label: qsTr("Chat")
                ident: "chatTone"
            }
            ListElement {
                label: qsTr("Mail")
                ident: "mailTone"
            }
            ListElement {
                label: qsTr("Calendar")
                ident: "calendarTone"
            }
            ListElement {
                label: qsTr("Alarm")
                ident: "clockAlarmTone"
            }
        }
        delegate: BackgroundItem {
            width: parent.width
            contentHeight: Theme.itemSizeSmall

            onClicked: {
                console.log("clicked on: " + ident)
                var opendialog = pageStack.push(Qt.resolvedUrl("../OpenDialog.qml"), {path: StandardPaths.music, filter: mainWindow.audioFilter});
                opendialog.openFile.connect(function(path) {
                    soundActionClicked(ident, path)
                })
            }

            Label {
                text: label
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                color: highlighted ? Theme.highlightColor : Theme.primaryColor
            }
        }
    }
}

