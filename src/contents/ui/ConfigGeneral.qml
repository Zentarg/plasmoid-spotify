import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.0

Page {
    title: "Spotify Config"

    ColumnLayout {
        spacing: Kirigami.Units.smallSpacing
        anchors.fill: parent

        CheckBox {
            text: "Show lyrics"
            checked: plasmoid.configuration.showLyrics
            onToggled: plasmoid.configuration.showLyrics = checked
        }
    }
}
