# This Python file uses the following encoding: utf-8

import sys
from PySide6.QtCore import QObject, Slot
from PySide6.QtWidgets import QApplication
from PySide6.QtQuick import QQuickView
from PySide6.QtCore import QUrl
import webbrowser

class Backend(QObject):
    @Slot(str)
    def performSearch(self, keyword):
        if keyword.strip():
            search_url = f"https://openknowledgemaps.org/index#?q={keyword}"
            print(f"Performing search for: {keyword}")
            webbrowser.open(search_url)  # Open the search result in the default browser
        else:
            print("No keyword provided.")

# Initialize the Qt application
app = QApplication(sys.argv)
view = QQuickView()

# Load the QML file
qml_file = QUrl("main.qml")
view.setSource(qml_file)

# Set up the backend and expose it to QML
backend = Backend()
context = view.rootContext()
context.setContextProperty("backend", backend)

# Show the window
view.show()
sys.exit(app.exec())
