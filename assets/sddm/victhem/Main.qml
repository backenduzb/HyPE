import QtQuick 2.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.15

Rectangle {
    id: container
    width: 1920
    height: 1080
    color: "#000000"

    Component.onCompleted: {
        passwordField.forceActiveFocus();
    }

    Image {
        id: bgImage
        source: "aotlevi.png"
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        smooth: true
    }

    Column {
        anchors {
            top: parent.top
            right: parent.right
            topMargin: 60
            rightMargin: 60
        }
        spacing: 8
        z: 10

        Text {
            id: clock
            font.pixelSize: 90
            font.bold: true
            color: "#ffffff"
            font.family: "SF Pro Text"
            renderType: Text.NativeRendering
            
            Timer {
                interval: 1000; running: true; repeat: true
                onTriggered: clock.text = Qt.formatDateTime(new Date(), "hh:mm")
            }
            Component.onCompleted: clock.text = Qt.formatDateTime(new Date(), "hh:mm")
        }

        Text {
            id: dateText
            font.pixelSize: 20
            font.weight: Font.Medium
            color: "#e0e0e0"
            font.family: "SF Pro Text"
            renderType: Text.NativeRendering
            
            Timer {
                interval: 60000; running: true; repeat: true
                onTriggered: dateText.text = Qt.formatDateTime(new Date(), "dddd, d MMMM")
            }
            Component.onCompleted: dateText.text = Qt.formatDateTime(new Date(), "dddd, d MMMM")
        }
    }

    Rectangle {
        id: loginBox
        width: 380
        height: 480
        anchors.centerIn: parent
        radius: 24
        color: "#22ffffff" 
        border.color: "#44ffffff"
        border.width: 1

        opacity: 0
        scale: 0.95
        ParallelAnimation {
            running: true
            NumberAnimation { target: loginBox; property: "opacity"; to: 1.0; duration: 800; easing.type: Easing.OutCubic }
            NumberAnimation { target: loginBox; property: "scale"; to: 1.0; duration: 800; easing.type: Easing.OutCubic }
        }

        Column {
            anchors.centerIn: parent
            spacing: 28
            width: parent.width - 70

            Item {
                width: 120
                height: 120
                anchors.horizontalCenter: parent.horizontalCenter

                Image {
                    id: avatar
                    source: "levi.jpeg"
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    antialiasing: true
                    visible: false
                }

                Rectangle {
                    id: mask
                    anchors.fill: parent
                    radius: 60
                    smooth: true
                    antialiasing: true
                    visible: false
                }

                OpacityMask {
                    anchors.fill: avatar
                    source: avatar
                    maskSource: mask
                    smooth: true
                    antialiasing: true
                    layer.enabled: true
                    layer.effect: Colorize { saturation: 0.0 }
                }
                
                Rectangle {
                    anchors.fill: parent
                    radius: 60
                    color: "transparent"
                    border.color: "#ffffff"
                    border.width: 1.5
                    smooth: true
                    antialiasing: true
                }
            }

            Text {
                text: userModel.lastUser
                color: "#ffffff"
                font.pixelSize: 24
                font.family: "SF Pro Text"
                font.weight: Font.Bold
                anchors.horizontalCenter: parent.horizontalCenter
                renderType: Text.NativeRendering
            }

            TextField {
                id: passwordField
                width: parent.width
                height: 48
                placeholderText: "Password"
                placeholderTextColor: "#b3ffffff"
                echoMode: TextInput.Password
                color: "#ffffff"
                font.pixelSize: 16
                font.family: "SF Pro Text"
                focus: true
                selectByMouse: true
                
                background: Rectangle {
                    color: passwordField.activeFocus ? "#44ffffff" : "#15ffffff"
                    border.color: passwordField.activeFocus ? "#ffffff" : "#44ffffff"
                    border.width: 1
                    radius: 10
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Behavior on border.color { ColorAnimation { duration: 200 } }
                }

                MouseArea {
                    anchors.fill: parent
                    propagateComposedEvents: true
                    onPressed: {
                        passwordField.forceActiveFocus();
                        mouse.accepted = false;
                    }
                    onClicked: {
                        passwordField.forceActiveFocus();
                        mouse.accepted = false;
                    }
                }

                onAccepted: sddm.login(userModel.lastUser, passwordField.text, sessionModel.defaultIndex)
            }

            Button {
                id: loginButton
                width: parent.width
                height: 48
                hoverEnabled: true 
                
                contentItem: Text {
                    text: "SIGN IN"
                    color: loginButton.hovered ? "#000000" : "#ffffff"
                    font.pixelSize: 14
                    font.family: "SF Pro Text"
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                background: Rectangle {
                    color: loginButton.hovered ? "#ffffff" : "#35ffffff"
                    border.width: 0
                    radius: 10
                    
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                onClicked: sddm.login(userModel.lastUser, passwordField.text, sessionModel.defaultIndex)
            }
        }
    }

    Rectangle {
        id: leftBottomLogo
        width: 160
        height: 60
        anchors {
            left: parent.left
            bottom: parent.bottom
            leftMargin: 50
            bottomMargin: 50
        }
        radius: 12
        color: "#22ffffff"
        border.color: "#44ffffff"
        border.width: 1

        Row {
            anchors.centerIn: parent
            spacing: 10

            Item {
                width: 32
                height: 32
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    id: miniAvatar
                    source: "levi.jpeg"
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    visible: false
                }

                Rectangle {
                    id: miniMask
                    anchors.fill: parent
                    radius: 16
                    smooth: true
                    antialiasing: true
                    visible: false
                }

                OpacityMask {
                    anchors.fill: miniAvatar
                    source: miniAvatar
                    maskSource: miniMask
                    smooth: true
                    antialiasing: true
                    layer.enabled: true
                    layer.effect: Colorize { saturation: 0.0 }
                }
            }

            Text {
                text: "Welcome!"
                color: "#ffffff"
                font.pixelSize: 14
                font.family: "SF Pro Text"
                font.bold: true
                font.letterSpacing: 2
                anchors.verticalCenter: parent.verticalCenter
                renderType: Text.NativeRendering
            }
        }
    }
}
