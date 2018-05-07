import QtQuick 2.0
import Sailfish.Silica 1.0
import "Components/ColorWheel"

Dialog {
    id: colorChooser

    property color currentColor

    DialogHeader {
        id: header
        title: qsTr("Choose Highlight Color")
    }

    ColorWheel{
        anchors.top: header.bottom
        width: parent.width
        height: parent.height - header.height

        onWheelAreaPressed: {
            colorChooser.backNavigation = false
            colorChooser.canAccept = false
            colorChooser.forwardNavigation = false
        }
        onWheelAreaReleased: {
            colorChooser.backNavigation = true
            colorChooser.canAccept = true
            colorChooser.forwardNavigation = true
        }
        onColorSelected: {
            currentColor = col
        }
    }

}
