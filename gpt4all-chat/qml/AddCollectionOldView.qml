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
            text: qsTr("Add Document Collection from Open Knowledge Maps")
            font.pixelSize: theme.fontSizeBanner
            color: theme.titleTextColor
        }

        Text {
            Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
            Layout.maximumWidth: addDocBanner.width
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignJustify
            text: qsTr("Insert the keywords to feed the AI-based search model. Then a collection folder with the top 100 most relevant papers (html format) is created.")
            font.pixelSize: theme.fontSizeLarger
            color: theme.titleInfoTextColor
        }

        GridLayout {
            id: root
            Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
            rowSpacing: 50
            columnSpacing: 20

            property alias collection: collection.text
            // property alias folder_path: folderEdit.text

            FolderDialog {
                id: folderDialog
                title: qsTr("Please choose a directory")
            }

            function openFolderDialog(currentFolder, onAccepted) {
                folderDialog.currentFolder = currentFolder;
                folderDialog.accepted.connect(function() { onAccepted(folderDialog.selectedFolder); });
                folderDialog.open();
            }

            Label {
                Layout.row: 2
                Layout.column: 0
                text: qsTr("Name")
                font.bold: true
                font.pixelSize: theme.fontSizeLarger
                color: theme.settingsTitleTextColor
            }

            MyTextField {
                id: collection
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
                Accessible.role: Accessible.EditableText
                Accessible.name: collection.text
                Accessible.description: ToolTip.text
                function showError() {
                    collection.placeholderTextColor = theme.textErrorColor
                }
                onTextChanged: {
                    collection.placeholderTextColor = theme.mutedTextColor
                }
            }

            Label {
                Layout.row: 3
                Layout.column: 0
                text: qsTr("Keywords")
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
                // MyDirectoryField {
                //     id: folderEdit
                //     Layout.fillWidth: true
                //     text: root.folder_path
                //     placeholderText: qsTr("Insert keywords...")
                //     font.pixelSize: theme.fontSizeLarge
                //     placeholderTextColor: theme.mutedTextColor
                //     ToolTip.text: qsTr("Keywords to feed AI model (Required)")
                //     ToolTip.visible: hovered
                //     function showError() {
                //         folderEdit.placeholderTextColor = theme.textErrorColor
                //     }
                //     onTextChanged: {
                //         folderEdit.placeholderTextColor = theme.mutedTextColor
                //     }
                // }

                TextField {
                    id: keywordField
                    Layout.fillWidth: true
                    placeholderText: qsTr("Insert keywords...")
                    font.pixelSize: theme.fontSizeLarge
                    placeholderTextColor: theme.mutedTextColor
                    ToolTip.text: qsTr("Keywords to feed AI model (Required)")
                    ToolTip.visible: hovered
                }

                MySettingsButton {
                    id: browseButton
                    text: qsTr("Browse")
                    // When the button is clicked, fetch data using the search term
                    onClicked: {
                        // Retrieve the text from keywordField
                        var searchTerm = keywordField.text;

                        if (searchTerm.length > 0) {
                            // Call the C++ function to fetch search results
                            networkManager.fetchSearchResults(searchTerm);
                        } else {
                            console.log("Please enter a keyword to search.");
                        }
                    }
                }

                TextArea {
                    id: resultArea
                    width: parent.width
                    height: parent.height / 2
                    readOnly: true
                    placeholderText: "Results will appear here..."
                }

                // Capture the signal from the NetworkManager when search results are ready
                Connections {
                    target: networkManager
                    onSearchResultsReady: {
                        resultArea.text = data;  // Display the results in the TextArea
                    }
                }


                // MySettingsButton {
                //     id: browseButton
                //     text: qsTr("Browse")
                //     // When the button is clicked, open the Open Knowledge Maps homepage
                //     onClicked: {
                //         // Retrieve the text from keywordField and encode it for the URL
                //         var searchTerm = keywordField.text;
                //         var encodedSearchTerm = encodeURIComponent(searchTerm); // URL-encode the search term
                //         var searchUrl = "https://openknowledgemaps.org/search?service=base&type=get&sorting=most-relevant&min_descsize=300&q=" + encodedSearchTerm;
                //         Qt.openUrlExternally(searchUrl);  // Open the URL in the default browser
                //     }
                // }

                // TextField {
                //     id: keywordField
                //     Layout.fillWidth: true
                //     placeholderText: qsTr("Insert keywords...")
                //     font.pixelSize: theme.fontSizeLarge
                //     placeholderTextColor: theme.mutedTextColor
                //     ToolTip.text: qsTr("Keywords to feed AI model (Required)")
                //     ToolTip.visible: hovered
                // }

                // // Button to trigger the search in Python
                // Button {
                //     text: qsTr("Search")
                //     onClicked: {
                //         // Call Python function to handle the search
                //         backend.performSearch(keywordField.text)
                //     }
                // }
            }

            // MyButton {
            //     Layout.row: 4
            //     Layout.column: 1
            //     Layout.alignment: Qt.AlignRight
            //     text: qsTr("Create Collection")
            //     onClicked: {
            //         var isError = false;
            //         if (root.collection === "") {
            //             isError = true;
            //             collection.showError();
            //         }
            //         if (root.folder_path === "" || !folderEdit.isValid) {
            //             isError = true;
            //             folderEdit.showError();
            //         }
            //         if (isError)
            //             return;
            //         LocalDocs.addFolder(root.collection, root.folder_path)
            //         root.collection = ""
            //         root.folder_path = ""
            //         collection.clear()
            //         localDocsViewRequested()
            //     }
            // }
        }
    }
}
