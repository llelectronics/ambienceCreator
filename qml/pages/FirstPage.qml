/*
  Copyright (C) 2013 Jolla Ltd.
  Contact: Thomas Perl <thomas.perl@jollamobile.com>
  All rights reserved.

  You may use this file under the terms of BSD license as follows:

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Jolla Ltd nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR
  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import QtQuick 2.0
import Sailfish.Silica 1.0
import "Components"


Page {
    id: page

    property string wallpaperUrl
    property string wallpaperTemplate: "img/ambience-template.png"
    property string highlightColor: Theme.highlightColor
    property string _originalHighlightColor: Theme.secondaryHighlightColor

    // Sound Actions
    property string ringerTone
    property string messageTone
    property string chatTone
    property string mailTone
    property string calendarTone
    property string clockAlarmTone

    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    allowedOrientations: mainWindow.orient

    // To enable PullDownMenu, place our content in a SilicaFlickable
    SilicaFlickable {
        anchors.fill: parent

        // PullDownMenu and PushUpMenu must be declared in SilicaFlickable, SilicaListView or SilicaGridView
        PullDownMenu {
            MenuItem {
                text: qsTr("Create shareable RPM")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("SecondPage.qml"))
                    console.log("Wallpaper: " + wallpaperUrl);
                    console.log("ringerTone: " + ringerTone);
                    console.log("messageTone: " + messageTone);
                    console.log("chatTone: " + chatTone);
                    console.log("mailTone: " + mailTone);
                    console.log("calendarTone: " + calendarTone);
                    console.log("clockAlarmTone: " + clockAlarmTone);
                }
            }
        }

        // Tell SilicaFlickable the height of its content.
        contentHeight: column.height

        // Place our content in a Column.  The PageHeader is always placed at the top
        // of the page, followed by our content.
        Column {
            id: column

            width: page.width
            //spacing: Theme.paddingLarge
            MouseArea {
                width: parent.width
                height: 2 * (Screen.sizeCategory >= Screen.Large
                             ? Theme.itemSizeExtraLarge + (2 * Theme.paddingLarge)
                             : Screen.height / 5)

                Image {
                    id: image
                    anchors.fill: parent
                    source: {
                        if (wallpaperUrl != "") return wallpaperUrl
                        else return wallpaperTemplate
                    }
                    fillMode: Image.PreserveAspectCrop
                }

                OpacityRampEffect {
                    offset: 0.5
                    slope: 2.0
                    direction: OpacityRamp.BottomToTop
                    sourceItem: image
                }
                onClicked: {
                    var opendialog = pageStack.push(Qt.resolvedUrl("OpenDialog.qml"), {path: StandardPaths.pictures, filter: mainWindow.imageFilter});
                    opendialog.openFile.connect(function(path) {
                        wallpaperUrl = path;
                        pageStack.pop(page);
                    })
                }
            }
            MouseArea {
                id: highlightColorSelect

                width: parent.width
                height: Theme.itemSizeLarge

                clip: true
                enabled: true
                onClicked: {
                    // Open Color Page with selected color as highlight
                    console.log("Open Highlight Color Chooser")
                    var dialog = pageStack.push(Qt.resolvedUrl("ColorChooser.qml"))
                    dialog.accepted.connect(function() {
                        highlightColor = dialog.currentColor
                    })
                }

                Wallpaper {
                    id: wallpaper
                    anchors.fill: highlightColorSelect
                    verticalOffset: (Screen.height + image.height) / 2
                    source: {
                        if (wallpaperUrl != "") return wallpaperUrl
                        else return wallpaperTemplate
                    }

                    windowRotation: page.rotation
                }

                ShaderEffect {
                    id: dot

                    x: Theme.horizontalPageMargin
                    width: dotImage.width
                    height: dotImage.height
                    anchors.verticalCenter: highlightColorSelect.verticalCenter

                    property color color: highlightColorSelect.pressed
                                          ? page._originalHighlightColor
                                          : highlightColor
                    property Image source: Image {
                        id: dotImage
                        source: "image://theme/icon-m-dot"
                    }

                    fragmentShader: "
                                    varying highp vec2 qt_TexCoord0;
                                    uniform sampler2D source;
                                    uniform lowp vec4 color;
                                    uniform lowp float qt_Opacity;

                                    void main() {
                                        lowp vec4 tex = texture2D(source, qt_TexCoord0);
                                        gl_FragColor = color * tex.a * qt_Opacity;
                                    }"
                }

                Label {
                    id: colorLabel
                    anchors {
                        left: dot.right
                        leftMargin: Theme.paddingMedium
                        verticalCenter: highlightColorSelect.verticalCenter
                    }

                    //: Text to indicate color changes
                    //% "Ambience color"
                    text: qsTr("Highlight Color")
                    color: Theme.rgba(
                               highlightColorSelect.pressed
                               ? page._originalHighlightColor
                               : highlightColor,
                                 0.7)

                    states: State {
                        when: highlightColorSelect.enabled
                        AnchorChanges {
                            target: colorLabel
                            anchors {
                                baseline: highlightColorSelect.verticalCenter
                                verticalCenter: undefined
                            }
                        }
                        PropertyChanges {
                            target: changeLabel
                            opacity: 1
                        }
                    }

                    transitions: [
                        Transition {
                            AnchorAnimation { duration: 100 }
                            FadeAnimation { target: changeLabel; duration: 100 }
                        }
                    ]
                }

                Label {
                    id: changeLabel
                    anchors {
                        left: dot.right
                        leftMargin: Theme.paddingMedium
                        top: colorLabel.bottom
                    }
                    //: Text to indicate color changes
                    //% "Tap to reset"
                    text: qsTr("Choose highlight color for Ambience")
                    color: Theme.rgba(
                               highlightColorSelect.pressed
                               ? page._originalHighlightColor
                               : Theme.primaryColor,
                                 0.7)
                    font.pixelSize: Theme.fontSizeSmall
                    opacity: 0
                }

            }
            Rectangle {
                width: parent.width
                height: Theme.paddingLarge
                color: "transparent"
            }

            TextField {
                id: ambienceName
                width: parent.width
                height: Theme.itemSizeMedium
                label: qsTr("Ambience Name")
                placeholderText: label
            }

            Slider {
                id: volumeSlider
                label: qsTr("Ringtone volume")
                width: parent.width
                height: Theme.itemSizeMedium
                stepSize: 2
                minimumValue: 0
                maximumValue: 100
                value: 80
                valueText: value + "%"
            }
            SectionHeader {
                text: qsTr("Actions")
            }
            Label {
                width: parent.width
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.horizontalPageMargin
                }
                font.pixelSize: Theme.fontSizeExtraSmall
                wrapMode: Text.Wrap
                color: Theme.highlightColor
                text: qsTr("You can define a set of actions to trigger when this ambience is selected")
            }
            SilicaListView {
                width: parent.width
                height: model.count * Theme.itemSizeSmall + Theme.paddingMedium
                model: ListModel {
                    id: soundActionList
                    ListElement {
                        lbl: qsTr("Ringtone")
                        ident: "ringerTone"
                        path: ""
                    }
                    ListElement {
                        lbl: qsTr("Message")
                        ident: "messageTone"
                        path: ""
                    }
                    ListElement {
                        lbl: qsTr("Chat")
                        ident: "chatTone"
                        path: ""
                    }
                    ListElement {
                        lbl: qsTr("Mail")
                        ident: "mailTone"
                        path: ""
                    }
                    ListElement {
                        lbl: qsTr("Calendar")
                        ident: "calendarTone"
                        path: ""
                    }
                    ListElement {
                        lbl: qsTr("Alarm")
                        ident: "clockAlarmTone"
                        path: ""
                    }
                }
                delegate: ValueButton {
                    id: delegateBtn
                    label: lbl
                    value: (path != "") ? path : qsTr("Select tone")
                }
            }
        }
    }
}

