import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    width: 1440
    height: 900

    readonly property color ink: "#c5cbd6"
    readonly property color muted: "#8a98aa"
    readonly property color blue: "#8aafd0"
    readonly property color lavender: "#ada0d5"
    readonly property string mono: regularFont.name
    readonly property real uiScale: Math.min(width / 1440, height / 900)
    property date now: new Date()
    property bool busy: false
    property string errorMessage: ""

    FontLoader { id: regularFont; source: "JetBrainsMono-Regular.ttf" }
    FontLoader { id: lightFont; source: "JetBrainsMono-Light.ttf" }

    function signIn() {
        if (busy || username.text.trim() === "" || sessions.currentIndex < 0)
            return;
        errorMessage = "";
        busy = true;
        sddm.login(username.text.trim(), password.text, sessions.currentIndex);
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }
    Connections {
        target: sddm
        function onLoginFailed() {
            root.busy = false;
            root.errorMessage = "Sign-in failed. Check your credentials and try again.";
            password.clear();
            password.forceActiveFocus();
        }
    }
    Component.onCompleted: password.forceActiveFocus()

    Image {
        anchors.fill: parent
        source: Qt.resolvedUrl(config.Background || "background.png")
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        mipmap: true
    }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: "#55090c14" }
            GradientStop { position: 0.55; color: "#10090c14" }
            GradientStop { position: 1; color: "#b3090c14" }
        }
    }

    component Caption: Text {
        color: root.muted
        font.family: root.mono
        font.pixelSize: 11
        font.letterSpacing: 2
    }
    component Field: TextField {
        implicitHeight: 52
        color: root.ink
        placeholderTextColor: "#536479"
        font.family: root.mono
        font.pixelSize: 15
        leftPadding: 16
        rightPadding: 16
        selectByMouse: true
        selectionColor: root.blue
        selectedTextColor: "#090c14"
        background: Rectangle {
            color: "#121824"
            border.width: 1
            border.color: parent.activeFocus ? root.blue : "#26364b"
            Behavior on border.color { ColorAnimation { duration: 150 } }
        }
    }
    component QuietButton: Button {
        id: quietButton
        implicitHeight: 40
        leftPadding: 14
        rightPadding: 14
        hoverEnabled: true
        contentItem: Text {
            text: quietButton.text
            color: quietButton.enabled ? (quietButton.hovered ? root.blue : root.ink) : "#536479"
            font.family: root.mono
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            color: quietButton.down ? "#26364b" : quietButton.hovered ? "#d9121824" : "#99090c14"
            border.width: 1
            border.color: quietButton.activeFocus ? root.blue : "#26364b"
            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }

    Item {
        id: canvas
        width: root.width / root.uiScale
        height: root.height / root.uiScale
        scale: root.uiScale
        transformOrigin: Item.TopLeft
        opacity: 0
        Component.onCompleted: intro.start()
        NumberAnimation { id: intro; target: canvas; property: "opacity"; to: 1; duration: 550; easing.type: Easing.OutCubic }

        Row {
            anchors { left: parent.left; top: parent.top; leftMargin: 80; topMargin: 54 }
            spacing: 16
            Rectangle { width: 3; height: 18; color: root.blue }
            Caption { text: "Z E P H Y R U S"; color: root.ink; font.pixelSize: 14 }
        }
        Caption {
            anchors { right: parent.right; top: parent.top; rightMargin: 80; topMargin: 57 }
            text: "NIXOS  /  WAYLAND"
        }

        Column {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 80; verticalCenterOffset: -45 }
            spacing: 18
            Caption { text: "M I D N I G H T   B L U E"; color: root.lavender }
            Text {
                text: Qt.formatTime(root.now, "HH:mm")
                color: "#ecf0f6"
                font.family: root.mono
                font.pixelSize: 112
                font.weight: Font.Light
                font.letterSpacing: -6
            }
            Rectangle { width: 52; height: 2; color: root.blue }
            Text {
                text: Qt.formatDate(root.now, "dddd, MMMM d")
                color: root.ink
                font.family: root.mono
                font.pixelSize: 17
            }
        }

        Rectangle {
            id: card
            anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 80 }
            width: 440
            height: 440
            color: "#eb090c14"
            border.color: "#34465b"
            border.width: 1

            Rectangle { x: 36; y: 0; width: 56; height: 2; color: root.blue }
            ColumnLayout {
                anchors { fill: parent; margins: 36; topMargin: 32; bottomMargin: 28 }
                spacing: 0
                Caption { text: "USERNAME"; Layout.bottomMargin: 9 }
                Field {
                    id: username
                    objectName: "username"
                    Layout.fillWidth: true
                    Layout.bottomMargin: 20
                    text: userModel.lastUser || "malikk"
                    enabled: !root.busy
                    Accessible.name: "Username"
                    onAccepted: password.forceActiveFocus()
                }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 9
                    Caption { text: "PASSWORD" }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: keyboard.capsLock ? "CAPS LOCK" : ""
                        font.family: root.mono
                        font.pixelSize: 10
                        color: "#c9bc8b"
                    }
                }
                Field {
                    id: password
                    objectName: "password"
                    Layout.fillWidth: true
                    Layout.bottomMargin: 20
                    placeholderText: "Enter your password"
                    echoMode: TextInput.Password
                    passwordMaskDelay: 0
                    enabled: !root.busy
                    Accessible.name: "Password"
                    onAccepted: root.signIn()
                    Keys.onEscapePressed: clear()
                }
                Caption { text: "SESSION"; Layout.bottomMargin: 9 }
                ComboBox {
                    id: sessions
                    objectName: "sessions"
                    Layout.fillWidth: true
                    implicitHeight: 46
                    model: sessionModel
                    textRole: "name"
                    currentIndex: sessionModel.lastIndex
                    enabled: !root.busy
                    Accessible.name: "Desktop session"
                    leftPadding: 16
                    rightPadding: 38
                    contentItem: Text {
                        text: sessions.displayText
                        color: root.ink
                        font.family: root.mono
                        font.pixelSize: 13
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                    indicator: Text {
                        x: sessions.width - width - 16
                        anchors.verticalCenter: parent.verticalCenter
                        text: "⌄"
                        color: root.blue
                        font.pixelSize: 20
                    }
                    background: Rectangle {
                        color: "#121824"
                        border.color: sessions.activeFocus ? root.blue : "#26364b"
                    }
                    delegate: ItemDelegate {
                        width: sessions.width - 2
                        text: model.name
                        highlighted: sessions.highlightedIndex === index
                        contentItem: Text {
                            text: parent.text
                            color: parent.highlighted ? root.blue : root.ink
                            font.family: root.mono
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }
                        background: Rectangle { color: parent.highlighted ? "#26364b" : "#121824" }
                    }
                    popup: Popup {
                        y: sessions.height + 4
                        width: sessions.width
                        padding: 1
                        implicitHeight: Math.min(contentItem.implicitHeight + 2, 190)
                        contentItem: ListView {
                            clip: true
                            implicitHeight: contentHeight
                            model: sessions.popup.visible ? sessions.delegateModel : null
                            currentIndex: sessions.highlightedIndex
                            ScrollIndicator.vertical: ScrollIndicator { }
                        }
                        background: Rectangle { color: "#121824"; border.color: root.blue }
                    }
                }
                Text {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    text: root.errorMessage
                    color: "#cf8993"
                    font.family: root.mono
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                    verticalAlignment: Text.AlignVCenter
                    Accessible.role: Accessible.AlertMessage
                }
                Button {
                    id: login
                    objectName: "login"
                    Layout.fillWidth: true
                    implicitHeight: 52
                    enabled: !root.busy && username.text.trim() !== "" && sessions.currentIndex >= 0
                    hoverEnabled: true
                    text: root.busy ? "Signing in…" : "Sign in  →"
                    contentItem: Text {
                        text: login.text
                        color: "#090c14"
                        font.family: root.mono
                        font.pixelSize: 15
                        font.weight: Font.Medium
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: !login.enabled ? "#536479" : login.down ? root.lavender : login.hovered ? "#b2cce2" : root.blue
                        border.width: login.activeFocus ? 2 : 0
                        border.color: "#ecf0f6"
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    onClicked: root.signIn()
                }
                Item { Layout.fillHeight: true }
            }
        }

        Caption {
            anchors { left: parent.left; bottom: parent.bottom; leftMargin: 80; bottomMargin: 55 }
            text: "A QUIET PLACE TO THINK."
            font.pixelSize: 10
        }
        Row {
            anchors { right: parent.right; bottom: parent.bottom; rightMargin: 80; bottomMargin: 42 }
            spacing: 10
            QuietButton { text: "Sleep"; enabled: sddm.canSuspend && !root.busy; onClicked: sddm.suspend() }
            QuietButton { text: "Restart"; enabled: sddm.canReboot && !root.busy; onClicked: { powerDialog.action = "restart"; powerDialog.open(); } }
            QuietButton { text: "Power off"; enabled: sddm.canPowerOff && !root.busy; onClicked: { powerDialog.action = "power off"; powerDialog.open(); } }
        }
    }

    Dialog {
        id: powerDialog
        objectName: "powerDialog"
        property string action: "restart"
        anchors.centerIn: parent
        width: Math.min(400, root.width - 40)
        modal: true
        padding: 28
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle { color: "#121824"; border.color: "#34465b" }
        Overlay.modal: Rectangle { color: "#aa090c14" }
        contentItem: ColumnLayout {
            spacing: 24
            Text { text: "Ready to " + powerDialog.action + "?"; color: root.ink; font.family: root.mono; font.pixelSize: 18 }
            RowLayout {
                spacing: 12
                QuietButton { text: "Cancel"; onClicked: powerDialog.close() }
                QuietButton {
                    text: powerDialog.action === "restart" ? "Restart" : "Power off"
                    onClicked: {
                        powerDialog.close();
                        if (powerDialog.action === "restart") sddm.reboot();
                        else sddm.powerOff();
                    }
                }
            }
        }
    }
}
