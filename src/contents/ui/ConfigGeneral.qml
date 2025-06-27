import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {

    property alias cfg_showLyrics: showLyrics.checked
    property bool cfg_showLyricsDefault: true

    property alias cfg_highlightCurrentLine: highlightCurrentLine.checked
    property bool cfg_highlightCurrentLineDefault: true

    ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Heading {
            text: "Lyrics"
            level: 3
            Layout.alignment: Qt.AlignLeft
        }

        CheckBox {
            id: showLyrics
            text: "Show lyrics"
            checked: cfg_showLyrics
            Layout.alignment: Qt.AlignLeft
        }

        CheckBox {
            id: highlightCurrentLine
            text: "Highlight current line"
            checked: cfg_highlightCurrentLine
            Layout.alignment: Qt.AlignLeft
        }
    }
}