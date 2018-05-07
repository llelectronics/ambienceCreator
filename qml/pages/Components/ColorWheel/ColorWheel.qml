import QtQuick 2.2
import QtQuick.Window 2.0
import Sailfish.Silica 1.0
import "content"
import "content/ColorUtils.js" as ColorUtils

Item {
    id: root
    focus: true

    signal wheelAreaPressed
    signal wheelAreaReleased
    signal colorSelected(color col)

    // Color value in RGBA with floating point values between 0.0 and 1.0.

    property vector4d colorHSVA: Qt.vector4d(1, 0, 1, 1)
    QtObject {
        id: m
        // Color value in HSVA with floating point values between 0.0 and 1.0.
        property vector4d colorRGBA: ColorUtils.hsva2rgba(root.colorHSVA)
    }

    signal accepted

    onAccepted: {
        console.debug("DATA => accepted")
    }

    Column {
        spacing: Theme.paddingLarge
        width: parent.width
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: Theme.paddingLarge
        anchors.rightMargin: Theme.paddingLarge
        anchors.topMargin: Theme.paddingLarge


        // current color value
        Row {
            width:parent.width
            height: Theme.itemSizeMedium
            spacing: Theme.paddingMedium

            // current color display
            Rectangle {
                width: Theme.itemSizeLarge
                height: Theme.itemSizeMedium
                CheckerBoard {
                    cellSide: 5
                }
                Rectangle {
                    id: colorDisplay
                    width: parent.width
                    height: parent.height
                    border.width: 1
                    border.color: "black"
                    color: Qt.rgba(m.colorRGBA.x, m.colorRGBA.y, m.colorRGBA.z)
                    onColorChanged: colorSelected(color)
                    opacity: m.colorRGBA.w
                }
            }
            Item {
                height: parent.height
                width: parent.width
                anchors.verticalCenter: parent.verticalCenter
                Label {
                    id: captionBox
                    text: "#"
                    height: parent.height
                    font.bold: true
                    anchors.verticalCenter: currentColor.verticalCenter
                }
                TextField {
                    id: currentColor
                    font.capitalization: "AllUppercase"
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: captionBox.right
                    anchors.leftMargin: 2
                    height: parent.height
                    width: parent.width - captionBox.width
                    maximumLength: 9
                    focus: true
                    background: null
                    text: ColorUtils.hexaFromRGBA(m.colorRGBA.x, m.colorRGBA.y,
                                                  m.colorRGBA.z, m.colorRGBA.w)
                    validator: RegExpValidator {
                        regExp: /^([A-Fa-f0-9]{6})$/
                    }
                    Keys.onReturnPressed: {
                        var colorTmp = Qt.vector4d( parseInt(text.substr(0, 2), 16) / 255,
                                                   parseInt(text.substr(2, 2), 16) / 255,
                                                   parseInt(text.substr(4, 2), 16) / 255,
                                                   colorHSVA.w) ;
                        colorHSVA = ColorUtils.rgba2hsva(colorTmp)
                    }
                }
            }
        }


        Row {
            width: parent.width
            height: wheel.height
            spacing: Theme.paddingLarge * 2

            Wheel {
                id: wheel
                width: parent.width - (2 * Theme.paddingLarge) - Theme.itemSizeHuge
                height: width
                hue: colorHSVA.x
                saturation: colorHSVA.y
                onUpdateHS: {
                    colorHSVA = Qt.vector4d(hueSignal,saturationSignal, colorHSVA.z, colorHSVA.w)
                }
                onAccepted: {
                    root.accepted()
                }
                _wheelArea.onPressed: {
                    wheelAreaPressed();
                }
                _wheelArea.onReleased: {
                    wheelAreaReleased();
                }
                _wheelArea.onCanceled: {
                    wheelAreaReleased();
                }
            }

            // brightness picker slider
            Item {
                width: Theme.itemSizeLarge
                height: wheel.height

                //Brightness background
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop {
                            id: brightnessBeginColor
                            position: 0.0
                            color: {
                                var rgba = ColorUtils.hsva2rgba(
                                            Qt.vector4d(colorHSVA.x,
                                                        colorHSVA.y, 1, 1))
                                return Qt.rgba(rgba.x, rgba.y, rgba.z, rgba.w)
                            }
                        }
                        GradientStop {
                            position: 1.0
                            color: "#000000"
                        }
                    }
                }

                VerticalSlider {
                    id: brigthnessSlider
                    anchors.fill: parent
                    value: colorHSVA.z
                    onValueChanged: {
                        colorHSVA = Qt.vector4d(colorHSVA.x, colorHSVA.y, value, colorHSVA.w)
                    }
                    onAccepted: {
                        root.accepted()
                    }
                    onStateChanged: {
                        if (state == "editing") {
                            wheelAreaPressed();
                        }
                        else wheelAreaReleased();
                    }
                }
            }
        }
    }
}
