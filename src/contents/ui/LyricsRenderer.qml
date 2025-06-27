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
    textFormat: Text.RichText

    text: "Lyrics"
    color: "white"
    font: Kirigami.Theme.defaultFont
    lineHeight: 0.8

    onWidthChanged: updateTargetPosition(false)
    onHeightChanged: updateTargetPosition(false)

    property var lyrics: null
    property var spotify: null
    property var transitionDuration: 1000
    property var lineCount: 0
    property var currentLineIndex: 0
    property var hasHighlighted: false

    onLyricsChanged: {
        if (!plasmoid.configuration.highlightCurrentLine) {
            updateText();
        }
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

    function updateText() {
        let builder = "";
        let lines = 0;

        let currentLineIndex = getCurrentLineIndex();

        if (lyrics !== null && lyrics) {
            lyrics.forEach((line, i) => {
                if (i === currentLineIndex || !plasmoid.configuration.highlightCurrentLine) {
                    builder += line.text;
                } else {
                    builder += `<span style="color:gray">${line.text}</span>`;
                }

                if (i < lyrics.length - 1) {
                    builder += "<br/>";
                }
                lines++;
            });
        }

        lineCount = lines;
        textElement.text = builder;
    }

    function updateTargetPosition(animated = true) {
        let currentY = y;

        let newValue = plasmoid.configuration.highlightCurrentLine;
        if (hasHighlighted !== newValue || newValue) {
            hasHighlighted = newValue;
            updateText();
        }

        if (textElement.parent !== null && lineCount > 0) {
            if (animated) {
                animation.from = currentY;
                animation.to = calculateTargetY();
                animation.start()
            } else {
                animation.stop()
                y = calculateTargetY()
            }
        }
    }

    function getCurrentLineIndex(offset = 0) {
        let position = spotify.getDaemonPosition() / 1_000_000 + offset;
        let target = -1;
        for (let i = 0; i < lyrics.length; i++) {
            if (lyrics[i].time <= position) {
                target = i;
            } else {
                break;
            }
        }
        return target;
    }

    function calculateTargetY() {
        let offsetY = 0;
        let lineHeight = (textElement.contentHeight - 3) / textElement.lineCount;
        let currentLineIndex = getCurrentLineIndex(transitionDuration / 1000);
        if (lyrics !== null && currentLineIndex >= 0) {
            offsetY = lineHeight * (currentLineIndex + 1);
        }
        return textElement.parent.height / 2 - offsetY + lineHeight / 2 - 3;
    }

}
