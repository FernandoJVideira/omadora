import QtQuick
import QtQuick.Controls
import SddmComponents 2.0

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: config.background

    property string accent: config.accent
    property string fg: config.foreground
    property string bg: config.background
    property string muted: config.muted
    property string selected: config.selection
    property string errorColor: config.error

    Image {
        anchors.fill: parent
        source: "background"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    Rectangle {
        anchors.fill: parent
        color: root.bg
        opacity: 0.55
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        spacing: 14

        Text {
            id: clock
            anchors.horizontalCenter: parent.horizontalCenter
            color: root.fg
            font.pixelSize: 84
            font.bold: true
            text: Qt.formatTime(new Date(), "HH:mm")
        }

        Text {
            id: date
            anchors.horizontalCenter: parent.horizontalCenter
            color: root.muted === root.bg ? root.fg : Qt.lighter(root.muted, 1.6)
            font.pixelSize: 20
            text: Qt.formatDate(new Date(), "dddd, d MMMM")
        }

        Item { width: 1; height: 24 }

        ComboBox {
            id: user
            width: 320
            anchors.horizontalCenter: parent.horizontalCenter
            model: userModel
            textRole: "name"
            currentIndex: userModel.lastIndex
            font.pixelSize: 18
            background: Rectangle {
                color: root.bg
                border.color: user.activeFocus ? root.accent : root.muted
                border.width: 2
                opacity: 0.9
            }
            contentItem: Text {
                leftPadding: 12
                text: user.displayText
                color: root.fg
                font: user.font
                verticalAlignment: Text.AlignVCenter
            }
            popup.background: Rectangle { color: root.bg; border.color: root.muted }
            delegate: ItemDelegate {
                width: user.width
                contentItem: Text { text: model.name; color: root.fg; font: user.font }
                background: Rectangle { color: highlighted ? root.selected : root.bg }
                highlighted: user.highlightedIndex === index
            }
        }

        TextField {
            id: password
            width: 320
            anchors.horizontalCenter: parent.horizontalCenter
            echoMode: TextInput.Password
            placeholderText: "Password"
            placeholderTextColor: root.muted
            color: root.fg
            font.pixelSize: 18
            focus: true
            leftPadding: 12
            background: Rectangle {
                color: root.bg
                border.color: password.activeFocus ? root.accent : root.muted
                border.width: 2
                opacity: 0.9
            }
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    sddm.login(user.currentText, password.text, session.currentIndex)
                    event.accepted = true
                }
            }
        }

        Text {
            id: message
            anchors.horizontalCenter: parent.horizontalCenter
            color: root.errorColor
            font.pixelSize: 15
            text: ""
        }
    }

    ComboBox {
        id: session
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 24
        width: 200
        model: sessionModel
        textRole: "name"
        currentIndex: sessionModel.lastIndex
        font.pixelSize: 15
        background: Rectangle { color: root.bg; border.color: root.muted; border.width: 1; opacity: 0.9 }
        contentItem: Text {
            leftPadding: 10
            text: session.displayText
            color: root.fg
            font: session.font
            verticalAlignment: Text.AlignVCenter
        }
        popup.background: Rectangle { color: root.bg; border.color: root.muted }
        delegate: ItemDelegate {
            width: session.width
            contentItem: Text { text: model.name; color: root.fg; font: session.font }
            background: Rectangle { color: highlighted ? root.selected : root.bg }
            highlighted: session.highlightedIndex === index
        }
    }

    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 24
        spacing: 12

        Button {
            visible: sddm.canSuspend
            text: "Suspend"
            onClicked: sddm.suspend()
            contentItem: Text { text: parent.text; color: root.fg; font.pixelSize: 15 }
            background: Rectangle { color: root.bg; border.color: root.muted; opacity: 0.9 }
        }
        Button {
            visible: sddm.canReboot
            text: "Reboot"
            onClicked: sddm.reboot()
            contentItem: Text { text: parent.text; color: root.fg; font.pixelSize: 15 }
            background: Rectangle { color: root.bg; border.color: root.muted; opacity: 0.9 }
        }
        Button {
            visible: sddm.canPowerOff
            text: "Shutdown"
            onClicked: sddm.powerOff()
            contentItem: Text { text: parent.text; color: root.fg; font.pixelSize: 15 }
            background: Rectangle { color: root.bg; border.color: root.muted; opacity: 0.9 }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            clock.text = Qt.formatTime(new Date(), "HH:mm")
            date.text = Qt.formatDate(new Date(), "dddd, d MMMM")
        }
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            message.text = "Login failed"
            password.text = ""
            password.forceActiveFocus()
        }
    }

    Component.onCompleted: password.forceActiveFocus()
}
