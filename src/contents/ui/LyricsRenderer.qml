import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

Text {
    id: textElement
    Layout.fillWidth: true
    Layout.preferredHeight: parent.height
    Layout.rightMargin: 15
    Layout.leftMargin: 15
    wrapMode: Text.NoWrap
    horizontalAlignment: Text.AlignRight

    text: "Lyrics"
    color: "white"
    font: Kirigami.Theme.defaultFont
    lineHeight: 0.8

    property var lyrics: null
    property var spotify: null
    property var transitionDuration: 1000

    onLyricsChanged: {
        let builder = ""
        if (lyrics !== null) {
            for (let i = 0; i < lyrics.length; i++) {
                builder += lyrics[i].text + "\n"
            }
        }
        textElement.text = builder
        updateTargetPosition(false)
    }

    Timer {
        interval: transitionDuration
        running: spotify.ready && spotify.playing && lyrics !== null
        repeat: true
        onTriggered: {
            updateTargetPosition()
        }
    }

    NumberAnimation on y {
        id: animation
        duration: transitionDuration
        easing.type: Easing.InOutQuad
    }

    function updateTargetPosition(animated = true) {
        if (animated) {
            animation.to = calculateTargetY()
            animation.start()
        } else {
            y = calculateTargetY()
            animation.stop()
        }
    }

    function calculateTargetY() {
        let offsetY = 0;
        let lineHeight = getLineHeight();
        if (lyrics !== null) {
            let position = spotify.getDaemonPosition() / 1_000_000 + transitionDuration / 1000;
            for (let i = 0; i < lyrics.length; i++) {
                let line = lyrics[i];
                let timeAtLine = line.time;
                if (timeAtLine > position) {
                    break;
                }

                offsetY += lineHeight;
            }
        }
        return lineHeight * 2 - 2 - offsetY;
    }

    function getLineHeight() {
        return textElement.lineHeight * textElement.font.pixelSize * 1.389;
    }

}
