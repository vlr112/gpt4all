import QtCore
// import QFuture
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Dialogs
import Qt.labs.folderlistmodel
// import QtWebEngine // Import required for WebEngineView
import Qt5Compat.GraphicalEffects
import llm
import chatlistmodel
import download
import modellist
import network
import gpt4all
import mysettings
import localdocs
// import QtWebEngine

Rectangle {
    id: addCollectionOldView

    Theme {
        id: theme
    }

    property var linksData: []  // Initialize an empty array to store link and HTML pairs
    property int successCount: 0  // Count of successfully fetched HTML
    property int failureCount: 0  // Count of failed fetch attempts


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

                TextField {
                    id: keywordField
                    Layout.fillWidth: true
                    placeholderText: qsTr("Insert keywords...")
                    font.pixelSize: theme.fontSizeLarge
                    placeholderTextColor: theme.mutedTextColor
                    ToolTip.text: qsTr("Keywords to feed AI model (Required)")
                    ToolTip.visible: hovered
                }

                Button {
                    text: qsTr("Fetch Results")
                    onClicked: {
                        if (keywordField.text !== "") {
                            fetchSearchResults(keywordField.text, collectionField.text);
                        } else {
                            keywordField.placeholderTextColor = theme.textErrorColor;
                        }
                    }
                }
            }

            TextArea {
                id: resultArea
                Layout.row: 4
                Layout.column: 0
                Layout.columnSpan: 2
                Layout.fillWidth: true
                Layout.fillHeight: true
                placeholderText: "Search results will be displayed here..."
                readOnly: true
                wrapMode: TextArea.Wrap
                font.pixelSize: theme.fontSizeLarge
            }

            // New Create Collection Button
            MyButton {
                id: createCollectionButton
                enabled: false  // Initially disabled
                Layout.row: 5
                Layout.column: 1
                Layout.alignment: Qt.AlignRight
                text: qsTr("Create Collection")
                onClicked: {
                    var isError = false;

                    // Check if collection name is empty
                    if (root.collectionName === "") {
                        isError = true;
                        collectionField.placeholderTextColor = theme.textErrorColor;
                    } else {
                        fileManager.saveHtmlFiles(
                            collectionField.text,   // collection name
                            "C:/Users/franc/OneDrive/Francisca_Denmark/Internship",  // base folder path
                            linksData               // HTML data
                        );

                    // Call saveHtmlFiles to save HTML content in the new folder
                    saveHtmlFiles(root.collectionName);

                    // Reset fields
                    root.collectionName = "";
                    collectionField.text = "";
                    resultArea.text = "";

                    // Navigate back to local docs view
                    localDocsViewRequested();
                    }
                }
                // Enable the button when there's at least one successful result
                // onSuccessCountChanged: enabled = successCount > 0
            }
        }
    }


    // Function to fetch search results
    function fetchSearchResults(searchTerm, collectionName) {
        console.log("Fetching search results for: " + searchTerm);

        // Step 1: Fetch the unique_id by making the first request
        var baseUrl = "https://openknowledgemaps.org/search?service=base&type=get&sorting=most-relevant&min_descsize=300&q=";
        var encodedSearchTerm = encodeURIComponent(searchTerm);
        var searchUrl = baseUrl + encodedSearchTerm;

        Qt.openUrlExternally(searchUrl)

        // Create a timer
        var timer = Qt.createQmlObject('import QtQuick; Timer {}', Qt.application);
        timer.interval = 30000;  // Set the interval to 20 seconds
        timer.repeat = false;     // Ensure the timer only runs once
        timer.triggered.connect(function() {

            var xhr = new XMLHttpRequest();
            xhr.open("GET", searchUrl, true);
            console.log("searchUrl: " + searchUrl);

            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    if (xhr.status === 200) {
                        // Parse the response to extract the unique_id
                        var responseText = xhr.responseText;
                        var uniqueId = extractUniqueId(responseText);

                        if (uniqueId) {
                            console.log("Unique ID: " + uniqueId);
                            // Now that we have the unique_id, move to step 2
                            fetchPaperLinks(uniqueId);
                        } else {
                            resultArea.text = "Unique ID not found in the response.";
                        }
                    } else {
                        resultArea.text = "Error: " + xhr.statusText;
                    }
                }
            };
            xhr.send();
        });
        timer.start();
    }

    // Function to extract the unique_id from the responseText
    function extractUniqueId(responseText) {
        var uniqueIdStart = responseText.indexOf('"unique_id":"') + '"unique_id":"'.length;
        var uniqueIdEnd = responseText.indexOf('"', uniqueIdStart);
        return responseText.substring(uniqueIdStart, uniqueIdEnd);
    }


    function parseDictionariesFromString(input) {
        // Regular expression to match content within curly braces
        const regex =  /\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}/g;  ///\{[^}]*\}/g;

        // Find all dictionary-like parts
        const matches = input.match(regex);

        if (!matches) {
            return "No dictionaries found";
        }

        // For each match, try to convert to a JavaScript object
        const dictionaries = matches.map((match) => {
            // try {
            // Sanitize and clean up the match to make it valid JSON
            let sanitizedMatch = match.replace(/\\\//g, '/');  // Remove escape slashes for URLs
            sanitizedMatch = sanitizedMatch.replace(/[\n\r]/g, ''); // Remove newlines
            // console.log('sanitizedMatch', sanitizedMatch)
            var parsedObject = JSON.parse(sanitizedMatch);

            // console.log("parsedObject.id", parsedObject.id)
             // Return the parsed object or any transformation you need
            return parsedObject;

        });

        return dictionaries;  // Filter out any invalid dictionaries
    }


    // Step 2: Fetch the paper links using the unique_id
    function fetchPaperLinks(uniqueId, collectionName) {

        var paperUrl = "https://openknowledgemaps.org/search_api/server/services/getLatestRevision.php?vis_id=" + uniqueId + "&context=true&streamgraph=false";
        console.log("paperUrl", paperUrl)

        var xhr = new XMLHttpRequest();
        xhr.open("GET", paperUrl, true);
        xhr.setRequestHeader("User-Agent", "Mozilla/5.0");
        xhr.setRequestHeader("X-Requested-With", "XMLHttpRequest");
        var values = [];

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    var responseJson = JSON.parse(xhr.responseText);

                    // Check if the 'data' key exists and extract DOIs or links
                    if (responseJson.hasOwnProperty('data')) {
                        var dataArray = responseJson['data'] //.split("{");

                        const result = parseDictionariesFromString(dataArray);
                        // console.log('try to print result: ',result.id)
                        if (Array.isArray(result)) {
                            linksData = [];  // Clear the previous links data

                            result.forEach((item) => {
                                // console.log('Parsed Object ID:', item.id);
                                if (item.doi){
                                    // values.push(item.doi);
                                    fetchHtmlContent(item.doi);
                                }
                                if (item.link){
                                    // values.push(item.link);
                                    fetchHtmlContent(item.link);
                                }
                            });
                        } else {
                            console.log('Result is not an array:', result);
                        }
                        // console.log('values', values);

                        // Display the DOIs or links in the TextArea
                        resultArea.text = values.join("\n");


                    } else {
                        resultArea.text = "No data found in the response.";
                    }
                } else {
                    resultArea.text = "Error: " + xhr.statusText;
                }
            }
        };

        xhr.send();
        // return values
    }

    // Function to fetch HTML content for a given URL/DOI
    function fetchHtmlContent(url) {
        var htmlXhr = new XMLHttpRequest();
        htmlXhr.open("GET", url, true);
        htmlXhr.setRequestHeader("User-Agent", "Mozilla/5.0");
        htmlXhr.setRequestHeader("X-Requested-With", "XMLHttpRequest");

        htmlXhr.onreadystatechange = function() {
            if (htmlXhr.readyState === XMLHttpRequest.DONE) {
                if (htmlXhr.status === 200) {
                    // Store the HTML content along with the URL/DOI
                    linksData.push({
                        link: url,
                        html: htmlXhr.responseText // Store the HTML content
                    });
                    successCount++;
                    updateStatus();
                    // console.log('Fetched HTML for:', url);
                } else {
                    // Failed to fetch HTML
                    failureCount++;
                    updateStatus();
                    // console.log('Failed to fetch HTML for:', url, 'Status:', htmlXhr.statusText);
                }
            }
        };

        htmlXhr.send();
    }

    // Update the result area with success/failure count
    function updateStatus() {
        resultArea.text = `Success: ${successCount}, Failures: ${failureCount}`;
        createCollectionButton.enabled = successCount > 0;  // Enable the button only if we have successful fetches

    }

    // // Function to create the folder and save HTML files
    // function saveHtmlFiles(collectionName) {
    //     var folderPath = "C:/Users/franc/OneDrive/Francisca_Denmark/Internship/" + collectionName;

    //     var dir = new QDir(folderPath);

    //     // Create the directory if it doesn't exist
    //     if (!dir.exists()) {
    //         dir.mkpath(folderPath);  // Create the folder
    //     }

    //     // Save each HTML content in the folder
    //     linksData.forEach(function(item, index) {
    //         var fileName = folderPath + "/page_" + (index + 1) + ".html";
    //         var file = new QFile(fileName);

    //         if (file.open(QIODevice.WriteOnly | QIODevice.Text)) {
    //             var stream = new QTextStream(file);
    //             stream.writeString(item.html);  // Write the HTML content to the file
    //             file.close();
    //         }
    //     });

    //     console.log("HTML files saved in:", folderPath);
    // }

}

