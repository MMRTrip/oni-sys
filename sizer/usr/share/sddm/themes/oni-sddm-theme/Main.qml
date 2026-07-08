import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: root
    width: 1920
    height: 1080

    // 1. Задний фон
    Image {
        id: bgImage
        anchors.fill: parent
        source: "background.jpg"
        fillMode: Image.PreserveAspectCrop
        smooth: true
    }

    // Общее затемнение фона
    Rectangle {
        anchors.fill: parent
        color: "#40000000"
    }

    // 2. Кнопка питания (Выключение, Перезагрузка) в левом верхнем углу
    ComboBox {
        id: powerSelector
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 25
        width: 160
        height: 40

        displayText: "Питание"
        currentIndex: -1

        model: ListModel {
            ListElement { text: "Выключить"; action: "poweroff" }
            ListElement { text: "Перезагрузка"; action: "reboot" }
            ListElement { text: "Режим сна"; action: "suspend" }
            ListElement { text: "Гибернация"; action: "hibernate" }
        }

        onActivated: {
            var targetAction = model.get(index).action
            if (targetAction === "poweroff") { sddm.powerOff() }
            else if (targetAction === "reboot") { sddm.reboot() }
            else if (targetAction === "suspend") { sddm.suspend() }
            else if (targetAction === "hibernate") { sddm.hibernate() }
            powerSelector.currentIndex = -1
        }

        contentItem: Text {
            text: powerSelector.displayText
            font.pixelSize: 14
            color: "#ffffff"
            verticalAlignment: Text.AlignVCenter
            leftPadding: 12
        }

        background: Rectangle {
            color: powerSelector.hovered ? "#CC242933" : "#991A1D24"
            radius: 10
            border.color: powerSelector.visualFocus ? "#ff3333" : "#25ffffff"
            border.width: 1
        }

        popup: Popup {
            y: powerSelector.height + 5
            width: powerSelector.width
            implicitHeight: contentItem.implicitHeight
            padding: 5
            contentItem: ListView {
                clip: true
                implicitHeight: contentHeight
                model: powerSelector.popup.visible ? powerSelector.delegateModel : null
                currentIndex: powerSelector.highlightedIndex
            }
            background: Rectangle { color: "#F21A1D24"; radius: 10; border.color: "#25ffffff"; border.width: 1 }
        }

        delegate: ItemDelegate {
            width: powerSelector.width - 10
            height: 35
            contentItem: Text { text: model.text; color: highlighted ? "#ffffff" : "#ffffff"; font.pixelSize: 14; verticalAlignment: Text.AlignVCenter; leftPadding: 10 }
            background: Rectangle { color: highlighted ? "#cc0000" : "transparent"; radius: 6 }
        }
    }

    // 3. Выбор графического сервера (Wayland / X11) в правом верхнем углу
    ComboBox {
        id: sessionSelector
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 25
        width: 250
        height: 40

        model: sessionModel
        textRole: "name"
        currentIndex: sessionModel.lastIndex
        onCurrentIndexChanged: sddm.lastSessionIndex = currentIndex

        contentItem: Text {
            text: sessionSelector.displayText
            font.pixelSize: 14
            color: "#ffffff"
            verticalAlignment: Text.AlignVCenter
            leftPadding: 12
        }

        background: Rectangle {
            color: sessionSelector.hovered ? "#CC242933" : "#991A1D24"
            radius: 10
            border.color: sessionSelector.visualFocus ? "#ff3333" : "#25ffffff"
            border.width: 1
        }

        popup: Popup {
            y: sessionSelector.height + 5
            width: sessionSelector.width
            implicitHeight: contentItem.implicitHeight
            padding: 5
            contentItem: ListView {
                clip: true
                implicitHeight: contentHeight
                model: sessionSelector.popup.visible ? sessionSelector.delegateModel : null
                currentIndex: sessionSelector.highlightedIndex
            }
            background: Rectangle { color: "#F21A1D24"; radius: 10; border.color: "#25ffffff"; border.width: 1 }
        }

        delegate: ItemDelegate {
            width: sessionSelector.width - 10
            height: 35
            contentItem: Text { text: model.name; color: highlighted ? "#ffffff" : "#ffffff"; font.pixelSize: 14; verticalAlignment: Text.AlignVCenter; leftPadding: 10 }
            background: Rectangle { color: highlighted ? "#cc0000" : "transparent"; radius: 6 }
        }
    }

    // Единый контейнер по центру экрана для часов и карточки
    Column {
        anchors.centerIn: parent
        spacing: 35

        // Блок с Часами и Датой
        Column {
            spacing: 8
            anchors.horizontalCenter: parent.horizontalCenter

            Text {
                id: timeText
                font.pixelSize: 84
                font.weight: Font.DemiBold
                color: "#ffffff"
                text: Qt.formatTime(new Date(), "hh:mm")
                anchors.horizontalCenter: parent.horizontalCenter
                layer.enabled: true

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: timeText.text = Qt.formatTime(new Date(), "hh:mm")
                }
            }

            Text {
                id: dateText
                font.pixelSize: 18
                font.weight: Font.Normal
                color: "#f0f0f0"
                text: Qt.formatDate(new Date(), "dd.MM.yyyy")
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        // Контейнер карточки авторизации
        Rectangle {
            id: loginCard
            width: 400
            height: 350
            color: "#CC1A1D24"
            radius: 24
            border.color: "#40ffffff"
            border.width: 1.5

            Column {
                anchors.fill: parent
                anchors.margins: 35
                spacing: 22

                Text {
                    text: "Авторизация"
                    color: "#ffffff"
                    font.pixelSize: 24
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                // Выпадающий список системных пользователей
                ComboBox {
                    id: userSelector
                    width: parent.width
                    height: 50

                    model: userModel
                    textRole: "name"
                    currentIndex: userModel.lastIndex

                    contentItem: Text {
                        text: userSelector.displayText
                        font.pixelSize: 15
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 16
                        elide: Text.ElideRight
                    }

                    background: Rectangle {
                        color: userSelector.hovered ? "#40000000" : "#25000000"
                        radius: 12
                        border.color: userSelector.visualFocus ? "#ff3333" : "#20ffffff"
                        border.width: 2
                    }

                    popup: Popup {
                        y: userSelector.height + 5
                        width: userSelector.width
                        implicitHeight: contentItem.implicitHeight > 200 ? 200 : contentItem.implicitHeight
                        padding: 5
                        contentItem: ListView {
                            clip: true
                            implicitHeight: contentHeight
                            model: userSelector.popup.visible ? userSelector.delegateModel : null
                            currentIndex: userSelector.highlightedIndex
                        }
                        background: Rectangle { color: "#F21A1D24"; radius: 12; border.color: "#40ffffff"; border.width: 1 }
                    }

                    delegate: ItemDelegate {
                        width: userSelector.width - 10
                        height: 40
                        contentItem: Text { text: model.name; color: highlighted ? "#ffffff" : "#ffffff"; font.pixelSize: 15; verticalAlignment: Text.AlignVCenter; leftPadding: 12 }
                        background: Rectangle { color: highlighted ? "#cc0000" : "transparent"; radius: 8 }
                    }
                }

                // Поле ввода пароля
                TextField {
                    id: passwordField
                    width: parent.width
                    height: 50
                    placeholderText: "Пароль"
                    echoMode: TextInput.Password
                    color: "#ffffff"
                    placeholderTextColor: "#aaaaaa"
                    font.pixelSize: 15
                    leftPadding: 16

                    background: Rectangle {
                        color: passwordField.activeFocus ? "#e0000000" : "#40000000"
                        radius: 12
                        border.color: passwordField.activeFocus ? "#ff3333" : "#20ffffff"
                        border.width: 2
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    onAccepted: sddm.login(userSelector.displayText, passwordField.text, sessionSelector.currentIndex)
                }

                // Кнопка Войти в систему
                Button {
                    id: loginButton
                    width: parent.width
                    height: 50

                    contentItem: Text {
                        text: "Войти в систему"
                        font.pixelSize: 15
                        font.bold: true
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        color: loginButton.hovered ? "#ff5555" : "#ff3333"
                        radius: 12
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    onClicked: sddm.login(userSelector.displayText, passwordField.text, sessionSelector.currentIndex)
                }
            }
        }
    }
}
