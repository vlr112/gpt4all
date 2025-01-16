import QtCore
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Dialogs
import Qt.labs.folderlistmodel
import Qt5Compat.GraphicalEffects
import llm
import chatlistmodel
import download
import modellist
import network
import gpt4all
import mysettings
import localdocs

Rectangle {
    id: addCollectionOldView

    Theme {
        id: theme
    }

    property string targetFolder: "/mnt/c/tmp/Internship_tmp"  // Update this with your desired folder path
    property string targetFolderWindows: "C:/tmp/Internship_tmp"  // Update this with your desired folder path


    color: theme.viewBackground
    signal localDocsViewRequested()

    ColumnLayout {
        id: mainArea
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 30
        spacing: 20

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: 50

            MyButton {
                id: backOldButton
                Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                text: qsTr("\u2190 Existing Collections")
                borderWidth: 0
                backgroundColor: theme.lighterButtonBackground
                backgroundColorHovered: theme.lighterButtonBackgroundHovered
                backgroundRadius: 5
                padding: 15
                topPadding: 8
                bottomPadding: 8
                textColor: theme.lighterButtonForeground
                fontPixelSize: theme.fontSizeLarge
                fontPixelBold: true

                onClicked: {
                    localDocsViewRequested()
                }
            }
        }

        Text {
            id: addDocBanner
            Layout.alignment: Qt.AlignBottom | Qt.AlignHCenter
            horizontalAlignment: Qt.AlignHCenter
            text: qsTr("Add Document Collection from Google Scholar")
            font.pixelSize: theme.fontSizeBanner
            color: theme.titleTextColor
        }

        Text {
            Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
            Layout.maximumWidth: addDocBanner.width
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignJustify
            text: qsTr("Search on Google Schoolar and save in collection top 100 most relevant papers (mhtml format).")
            font.pixelSize: theme.fontSizeLarger
            color: theme.titleInfoTextColor
        }

        GridLayout {
            id: root
            Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
            rowSpacing: 50
            columnSpacing: 20

            property alias collectionName: collectionField.text

            Label {
                Layout.row: 2
                Layout.column: 0
                text: qsTr("Name")
                font.bold: true
                font.pixelSize: theme.fontSizeLarger
                color: theme.settingsTitleTextColor
            }

            MyTextField {
                id: collectionField
                Layout.row: 2
                Layout.column: 1
                Layout.minimumWidth: 400
                Layout.alignment: Qt.AlignRight
                horizontalAlignment: Text.AlignJustify
                color: theme.textColor
                font.pixelSize: theme.fontSizeLarge
                placeholderText: qsTr("Collection name...")
                placeholderTextColor: theme.mutedTextColor
                ToolTip.text: qsTr("Name for generated collection (Required)")
                ToolTip.visible: hovered
                onTextChanged: {
                    collectionField.placeholderTextColor = theme.mutedTextColor
                }
            }

            Label {
                Layout.row: 3
                Layout.column: 0
                text: qsTr("Query")
                font.bold: true
                font.pixelSize: theme.fontSizeLarger
                color: theme.settingsTitleTextColor
            }

            RowLayout {
                Layout.row: 3
                Layout.column: 1
                Layout.minimumWidth: 400
                Layout.maximumWidth: 400
                Layout.alignment: Qt.AlignRight
                spacing: 10

                TextField {
                    id: keywordField
                    Layout.fillWidth: true
                    placeholderText: qsTr("Insert your query...")
                    font.pixelSize: theme.fontSizeLarge
                    placeholderTextColor: theme.mutedTextColor
                    ToolTip.text: qsTr("Search on Google Scholar (Required)")
                    ToolTip.visible: hovered
                }

                Button {
                    id: fetchButton
                    text: qsTr("Fetch Results")
                    onClicked: {
                        if (keywordField.text !== "" && root.collectionName !== "") {
                            fetchButton.enabled = false;
                            createCollectionButton.enabled = false;

                            searchManager.fetchAndSave(keywordField.text, root.collectionName, targetFolder, "Backend");
                            progressBar.visible = true;
                            progressBar.value = 0;
                        } else {
                            if (keywordField.text === "") {
                                keywordField.placeholderTextColor = theme.textErrorColor;
                            }
                            if (root.collectionName === "") {
                                collectionField.placeholderTextColor = theme.textErrorColor;
                            }
                        }
                    }
                }
            }

            // Progress Bar
            ProgressBar {
                id: progressBar
                Layout.row: 4
                Layout.column: 1
                Layout.minimumWidth: 400
                Layout.alignment: Qt.AlignRight
                from: 0
                to: 100
                value: 0 // Placeholder progress value
                visible: false

            }

            MyButton {
                id: createCollectionButton
                Layout.row: 5
                Layout.column: 1
                Layout.alignment: Qt.AlignRight
                text: qsTr("Create Collection")
                enabled: false // Initially disabled
                onClicked: {

                    if (root.collectionName !== "") {
                        LocalDocs.addFolder(root.collectionName, targetFolderWindows +"/" + root.collectionName);  // Use the centralized folder path
                        collectionField.clear();
                        keywordField.clear();
                        localDocsViewRequested();  // Navigate back to the local docs view
                    } else {
                        collectionField.placeholderTextColor = theme.textErrorColor;
                    }
                }
            }
        }
    }

    Connections {
        target: searchManager
        function onProgressUpdated (progress, status, failedLinks, failedPercentage) {
            console.log("Progress Updated:", progress, "Status:", status); // Debug log
            progressBar.visible = true
            progressBar.value = progress;
            // statusText.text = status;

            if (progress === 100) {
                console.log("Fetch completed. Enabling Create Collection button."); // Debug log
                progressBar.visible = false;
                fetchButton.enabled = true;
                createCollectionButton.enabled = true;

                if (failedPercentage > 0) {
                    failedLinksLabel.text = qsTr("Failed Links: ") + failedPercentage + "% (" + failedLinks.length + ")";
                    failedLinksDetails.text = failedLinks.join("\n");
                }
            }

        }
    }
}



