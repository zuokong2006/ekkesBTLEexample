// ekke (Ekkehard Gentz) @ekkescorner
import QtQuick 2.9
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0
import "../common"
import "../popups"
import org.ekkescorner.btle 1.0

Page {
    id: btRunAddimatPage
    property AddimatMapping currentAddimatMapping
    property MyBluetoothDeviceInfo deviceInfo
    property bool isSearchRunning: discoverDevicesPopup.isActive

    focus: true
    property string name: "BTRunAddimatPage"

    header: Pane {
        leftPadding: 24
        rightPadding: 8
        Material.elevation: 4
        RowLayout {
            width: appWindow.width - 32
            Column {
                Layout.fillWidth: true
                Row {
                    spacing: 6
                    IconActive {
                        imageName: "key.png"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    LabelHeadline {
                        text: deviceInfo? deviceInfo.deviceName : qsTr("no device")
                        color: primaryColor
                        wrapMode: Label.WordWrap
                        maximumLineCount: 2
                        elide: Label.ElideRight
                        anchors.verticalCenter: parent.verticalCenter
                    } // name
                    ButtonFlat {
                        visible: !deviceInfo
                        text: qsTr("Search Device")
                        textColor: accentColor
                        textAlignment: Text.AlignRight
                        anchors.verticalCenter: parent.verticalCenter
                        onClicked: {
                            btRunAddimatPage.searchDevice()
                        }
                    } // search devices button
                } // first row
                Row {
                    visible: deviceInfo
                    Column {
                        width: appWindow.width - 32 - 160 - 12
                        anchors.verticalCenter: parent.verticalCenter
                        LabelSubheading {
                            visible: Qt.platform.os != "ios" && !appWindow.isSmallDevice
                            width: parent.width
                            text: deviceInfo? deviceInfo.deviceAddress : ""
                            wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                            maximumLineCount: 2
                            elide: Label.ElideRight
                        } // address
                        LabelBody {
                            visible: Qt.platform.os == "ios" || appWindow.isSmallDevice
                            width: parent.width
                            text: deviceInfo? deviceInfo.deviceAddress : ""
                            wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                            maximumLineCount: 3
                            elide: Label.ElideRight
                        } // address
                        LabelBody {
                            width: parent.width
                            text: deviceInfo? deviceInfo.controllerStateDescription : ""
                            wrapMode: Label.WordWrap
                            maximumLineCount: 2
                            elide: Label.ElideRight
                        } // address
                    }
                    // retry if services hang in discovering
                    ButtonFlat {
                        visible: deviceInfo
                        width: 160
                        text: lockManager.featuresPrepared? qsTr("Disconnect") : qsTr("Initialize")
                        textColor: accentColor
                        textAlignment: Text.AlignRight
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: 12
                        onClicked: {
                            if(lockManager.featuresPrepared) {
                                btRunAddimatPage.showDisconnectMessage = false
                                btRunAddimatPage.disconnectFromDevice()
                            } else {
                                // search the device, connect and create expected services if needed
                                btRunAddimatPage.searchDevice()
                            }
                        }
                    } // connect disconnect button
                } // 2nd row
            }// header main col
            DotMarker {
                width: 12
                height: 12
                color: deviceInfo? (deviceInfo.deviceIsConnected? "green":"red") : "transparent"
                anchors.rightMargin: 0
                anchors.bottom: undefined
                anchors.bottomMargin: undefined
                anchors.top: parent.top
            } // indicator top-right at row
        } // header row layout
    } // header pane

    Flickable {
        id: flickable
        contentHeight: root.implicitHeight + 60
        anchors.fill: parent
        Pane {
            id: root
            anchors.fill: parent
            ColumnLayout {
                Layout.fillWidth: true
                anchors.right: parent.right
                anchors.left: parent.left
                RowLayout {
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    Layout.bottomMargin: 12
                    LabelSubheading {
                        id: batteryLabel
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 1
                        text: qsTr("Battery")
                        color: primaryColor
                        DotMarker {
                            anchors.rightMargin: 4
                            anchors.bottomMargin: 14
                            visible: lockManager.featuresPrepared && lockManager.batteryLevelValue >=0
                            color: lockManager.batteryLevelValue > lockManager.settingsBatteryLevelInfo? "green" : (lockManager.batteryLevelValue > lockManager.settingsBatteryLevelWarning? "orange" : "red")
                        }
                    }
                    LabelSubheading {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 3
                        leftPadding: 16
                        rightPadding: 10
                        wrapMode: Text.WrapAnywhere
                        text:lockManager.batteryLevelValue >=0? (lockManager.batteryLevelValue + " %") : qsTr("n/a")
                    }
                    ItemDelegate {
                        id: btSettingsMenuButton
                        anchors.top: parent.top
                        anchors.right: parent.right
                        visible: lockManager.featuresPrepared || (deviceInfo && deviceInfo.controllerState >=3)
                        focusPolicy: Qt.NoFocus
                        Image {
                            opacity: 0.6
                            anchors.centerIn: parent
                            source: "qrc:/images/black/more_vert.png"
                        }
                        onClicked: {
                            openSettingsMenu()
                        }
                    } // btSettingsMenuButton
                } // battery level
                RowLayout {
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    LabelSubheading {
                        Layout.alignment: Qt.AlignTop
                        Layout.preferredWidth: 1
                        text: qsTr("Key")
                        color: primaryColor
                    }
                    LabelSubheading {
                        Layout.alignment: Qt.AlignTop
                        Layout.preferredWidth: 3
                        leftPadding: 16
                        rightPadding: 10
                        wrapMode: Text.WrapAnywhere
                        text:lockManager.keyIdValue.length >0 && lockManager.keyIdValue != "0000000000000000"? lockManager.keyIdValue : qsTr("no key")
                    }
                } // key
                RowLayout {
                    visible: lockManager.keyNotificationsActive
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    Layout.bottomMargin: 12
                    LabelSubheading {
                        Layout.alignment: Qt.AlignTop
                        Layout.preferredWidth: 1
                        text: " "
                        color: primaryColor
                    }
                    ProgressBar {
                        id: commandProgressBar
                        Layout.preferredWidth: 3
                        Layout.fillWidth: true
                        leftPadding: 16
                        rightPadding: 10
                        indeterminate: true
                    }
                }

                RowLayout {
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    Layout.bottomMargin: 12
                    LabelHeadline {
                        id: greetingsLabel
                        text: ""
                        color: accentColor
                        wrapMode: Text.WordWrap
                    }
                } // key
            } // main column
        } // root pane
    } // flickable

    FloatingActionButton {
        id: startKeyNotificationsButton
        visible: lockManager.featuresPrepared
        backgroundColor: primaryColor
        imageSource: lockManager.keyNotificationsActive? "qrc:/images/"+iconOnPrimaryFolder+"/stop.png" : "qrc:/images/"+iconOnPrimaryFolder+"/play.png"
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 12
        anchors.horizontalCenter: parent.horizontalCenter
        onClicked: {
            if(lockManager.keyNotificationsActive) {
                lockManager.stopKeyNotifications()
            } else {
                lockManager.startKeyNotifications()
            }
        }
    } // FloatingActionButton

    // C O N N E C T - D I S C O N N E C T
    function disconnectFromDevice() {
        deviceInfo.disconnectFromDevice()
    }
    ReconnectYesNo {
        id: reconnectDialog
        parent: rootPane
        text: deviceInfo? qsTr("%1 is disconnected.\nTry to reconnect now ?\n\nCheck Device is ON, Battery OK\nBluetooth is On\n").arg(deviceInfo.deviceName) : "Reconnect"
        onIsYesChanged: {
            if(isYes) {
                isYes = false
                searchDevice()
            }
        }
    } // reconnectDialog
    // if disconnecting using the Button we don't want a dialog asking for reconnect
    property bool showDisconnectMessage: true
    function onDeviceDisconnected() {
        greetingsLabel.text = ""
        if(!showDisconnectMessage) {
            showDisconnectMessage = true
            return
        }
        // got the signal from elsewhere, so we ask user for reconnect
        // if this is our current tab
        if(appWindow.isWaiterLockCurrentTab() && !isSearchRunning) {
            reconnectDialog.open()
        }
    }
    Connections {
        target: deviceInfo
        onDisconnected: onDeviceDisconnected()
    }

    // S E A R C H, DISCOVER, CONNECT, PREPARE
    Timer {
        id: reconnectDelayTimer
        interval: 1000
        repeat: false
        onTriggered: {
            deviceInfo.connectToDeviceAgain()
        }
    } // reconnectDelayTimer
    function startReconnectDelayTimer() {
        reconnectDelayTimer.start()
    }
    Timer {
        id: waitServicesDiscoveredTimer
        interval: 1000
        repeat: false
        onTriggered: {
            console.log("retry prepare services")
            lockManager.prepareServices()
        }
    } // waitServicesDiscoveredTimer
    function startWaitServicesDiscoveredTimer() {
        waitServicesDiscoveredTimer.start()
    }
    function onRetryDeviceConnectChanged() {
        if(!discoverDevicesPopup.isActive) {
            return
        }
        if(!deviceInfo.retryDeviceConnect) {
            console.log("we don't want to retry now")
            return
        }
        // check if user clicks STOP button
        if(discoverDevicesPopup.stopClicked) {
            discoverDevicesPopup.stopClicked = false
            discoverDevicesPopup.close()
            return
        }
        console.log("RETRY detected: YES #"+deviceInfo.retryCounter)
        discoverDevicesPopup.infoText = qsTr("Try to connect again: %1 of 5").arg(deviceInfo.retryCounter)
        discoverDevicesPopup.from = 0
        discoverDevicesPopup.to = 30
        discoverDevicesPopup.max = 60
        discoverDevicesPopup.showStopButton = true
        discoverDevicesPopup.startTimer()
        startReconnectDelayTimer()
    }
    Connections {
        target: deviceInfo
        onRetryDeviceConnectChanged: onRetryDeviceConnectChanged()
    }
    function isSearchRunning() {
        return discoverDevicesPopup.isActive
    }

    BTScanPopup {
        id: discoverDevicesPopup
        property bool isActive: false
        text: qsTr("Search Device, connect, prepare Services. Please wait ...")
        textTimeout: qsTr("Waited too long for end of discovering devices")
        imageSource: "qrc:/images/extra/scan.png"
        from: 0
        to: 30
        max: 45
        showStopButton: true
        function onDeviceDiscoveryActiveChanged() {
            console.log("DeviceDiscoveryActive changed: "+ btManager.deviceDiscoveryActive)
            if(!btManager.deviceDiscoveryActive) {
                if(btManager.devicesList.length === 0) {
                    // Close this Popup
                    discoverDevicesPopup.close()
                    appWindow.showInfo(qsTr("No Devices found. Switch Devices Off/On or Settings Bluetooth Off/On to clear cache."))
                    return
                }
                // we discovered devices - check if favorite device is there
                deviceInfo = btManager.searchDevice(lockManager.settingsFavoriteAddress)
                lockManager.setCurrentDevice(deviceInfo)
                if(lockManager.settingsFavoriteAddress.length > 0 && !lockManager.hasDevice) {
                    // Close this Popup
                    discoverDevicesPopup.close()
                    appWindow.showInfo(qsTr("%1 Devices found, but not Device %2.").arg(btManager.devicesList.length).arg(lockManager.settingsFavoriteAddress))
                    return
                }
                // we found the already known device
                // now connect and create expected services
                showStopButton = false
                deviceInfo.createExpectedServices()
                return
            }
        } // onDeviceDiscoveryActiveChanged
        function onCreateServicesActiveChanged() {
            if(!deviceInfo.createServicesActive) {
                // services are created
                if(deviceInfo.controllerState == 4) {
                    // all services discovered
                    lockManager.prepareServices()
                } else if(deviceInfo.controllerState == 3) {
                    // Attention: on some devices (Samsung Xvover 3 getting some errors 133 while connecting)
                    // later on those devices hang a while before getting state 4 (all services discovered)
                    // instead getting state 3 (discovering) - this can cause a timing problem and missing the correct state
                    // we wait a short moment and try again - this normaly fixes this
                    startWaitServicesDiscoveredTimer()
                }
            }
        } // onCreateServicesActiveChanged
        function onFeaturesPreparedChanged() {
            // Close this Popup
            discoverDevicesPopup.close()
        }

        Connections {
            target: discoverDevicesPopup.isActive? lockManager : null
            onFeaturesPreparedChanged: discoverDevicesPopup.onFeaturesPreparedChanged()
        }

        Connections {
            target: discoverDevicesPopup.isActive? deviceInfo : null
            onCreateServicesActiveChanged: discoverDevicesPopup.onCreateServicesActiveChanged()
        }
        Connections {
            target:discoverDevicesPopup.isActive? btManager : null
            onDeviceDiscoveryActiveChanged: discoverDevicesPopup.onDeviceDiscoveryActiveChanged()
        }
        onOpened: {
            isActive = true
            infoText = ""
            if(!lockManager.hasDevice) {
                btManager.startDeviceDiscovery()
            } else {
                if(deviceInfo.controllerState == 4 && !lockManager.featuresPrepared) {
                    // all services discovered
                    lockManager.prepareServices()
                } else {
                    deviceInfo.createExpectedServices()
                }
            }
        } // on opened
        onStopClickedChanged: {
            if(stopClicked) {
                btManager.stopDeviceDiscovery()
            }
        } // on stop clicked
        onClosed: {
            isActive = false
            showStopButton = true
        } // on closed
    }// discoverDevicesPopup
    // search device, connect and create expected services if known device
    function searchDevice() {
        // reset to initial values
        discoverDevicesPopup.from = 0
        discoverDevicesPopup.to = 30
        discoverDevicesPopup.max = 45
        discoverDevicesPopup.stopClicked = false
        console.log("search device")
        if(lockManager.hasDevice) {
            console.log("We already have a device")
            deviceInfo = lockManager.currentDevice()
            if(!lockManager.featuresPrepared) {
                discoverDevicesPopup.open()
            }
            return
        }
        // do we have a favorite ?
        if(lockManager.settingsFavoriteAddress.length > 0) {
            console.log("searching..."+lockManager.settingsFavoriteAddress)
            // search favorite in already scanned devices
            deviceInfo = btManager.searchDevice(lockManager.settingsFavoriteAddress)
            lockManager.setCurrentDevice(deviceInfo)
            if(!lockManager.hasDevice) {
                // not found - try to scan new
                btManager.searchAddress = lockManager.settingsFavoriteAddress
            }
            discoverDevicesPopup.open()
        } else {
            appWindow.gotoDeviceList()
        }
    } // searchDevice

    //  S E R V I C E S   and   C H A R A C T E R I S T I C S
    // Notifications new or empty Keys
    function onKeyIdValueChanged() {
        if(appWindow.configuringAddimatActive) {
            console.log("ignore key ID changes while configuring")
            return
        }
        if(lockManager.keyIdValue.length > 0 && lockManager.keyIdValue != "0000000000000000") {
            currentAddimatMapping = lockManager.findFromMapping(lockManager.keyIdValue)
            if(!currentAddimatMapping) {
                greetingsLabel.text = qsTr("User not found :(\nIs the Key mapped to a User ?")
                greetingsLabel.color = "red"
                return
            } else {
                greetingsLabel.text = qsTr("Welcome %1").arg(currentAddimatMapping.userName)
                greetingsLabel.color = "green"
            }
        } else {
            if(lockManager.keyIdValue.length === 0) {
                currentAddimatMapping = null
                greetingsLabel.text = ""
                return
            }
            if(currentAddimatMapping) {
                greetingsLabel.text = qsTr("Goodbye %1").arg(currentAddimatMapping.userName)
                greetingsLabel.color = "black"
            } else {
                greetingsLabel.text = ""
            }
        }
    }
    Connections {
        target: lockManager
        onKeyIdValueChanged: onKeyIdValueChanged()
    }
    // autostart notifications when all is prepared
    function onFeaturesPreparedChanged() {
        if(lockManager.featuresPrepared) {
            if(!lockManager.keyNotificationsActive) {
                lockManager.startKeyNotifications()
            }
        }
    }
    Connections {
        target: lockManager
        onFeaturesPreparedChanged: onFeaturesPreparedChanged()
    }
    // M A P P I N G S
    BTConfigureAddimat {
        id: configureAddimat
    }
    // S E T T I N G S
    BTSettingsAddimat {
        id: mySettings
    }
    function openSettingsMenu() {
        btSettingsMenu.open()
    }
    Menu {
        id: btSettingsMenu
        modal:true
        dim: false
        closePolicy: Popup.CloseOnPressOutside | Popup.CloseOnEscape
        parent: btSettingsMenuButton
        x: parent.width - width
        transformOrigin: Menu.TopRight
        MenuItemWithIcon {
            itemText: qsTr("Settings")
            imageName: "settings.png"
            onTriggered: {
                mySettings.open()
            }
        }
        MenuSeparator {}
        MenuItemWithIcon {
            itemText: qsTr("Mapping")
            imageName: "speaker.png"
            onTriggered: {
                configureAddimat.open()
            }
        }
        MenuSeparator {}
        MenuItemWithIcon {
            enabled: lockManager.featuresPrepared
            itemText: qsTr("Refresh Battery")
            imageName: "refresh.png"
            onTriggered: {
                lockManager.updateBatteryLevel()
            }
        }
        MenuSeparator {}
        MenuItemWithIcon {
            itemText: qsTr("Disconnect")
            imageName: "remove.png"
            onTriggered: {
                btRunAddimatPage.showDisconnectMessage = false
                btRunAddimatPage.disconnectFromDevice()
            }
        }
        onAboutToShow: {
            appWindow.modalMenuOpen = true
        }
        onAboutToHide: {
            appWindow.modalMenuOpen = false
            appWindow.resetFocus()
        }
    } // btSettingsMenu

    function onHasDeviceChanged() {
        deviceInfo = lockManager.currentDevice()
    }
    Connections {
        target: lockManager
        onHasDeviceChanged: btRunAddimatPage.onHasDeviceChanged()
    }

    // I N I T   and   C L E A N U P
    // called immediately after Loader.loaded
    function init() {
        console.log("Init from btRunAddimatPage")
    }
    // don't forget to adjust main.qml replaceDestination() !
    function destinationChanged() {
        console.log("DESTINATION changed to btRunAddimatPage")
        // coming from scanner a device can be stored at appWindow
        // if there's currently no or another device used by this controlle, we overwrite with the one from appWindow
        if (appWindow.currentWaiterLockDeviceInfo && (btRunAddimatPage.deviceInfo !== appWindow.currentWaiterLockDeviceInfo)) {
            console.log("addimat device not the same")
            lockManager.setCurrentDevice(appWindow.currentWaiterLockDeviceInfo)
            btRunAddimatPage.deviceInfo = appWindow.currentWaiterLockDeviceInfo
        } else if(!appWindow.currentWaiterLockDeviceInfo &&!lockManager.hasDevice && btRunAddimatPage.deviceInfo) {
            // if scanner rebuilds all devices new we must delete the current one
            appWindow.showToast(qsTr("current device removed"))
            btRunAddimatPage.deviceInfo = null
        }
        searchDevice()
    }

    // called from Component.destruction
    function cleanup() {
        console.log("Cleanup done from btRunAddimatPage")
    }

} // btRunAddimatPage
