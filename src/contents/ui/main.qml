import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import Qt5Compat.GraphicalEffects
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: widget

    Plasmoid.status: PlasmaCore.Types.HiddenStatus

    Layout.preferredWidth: row.implicitWidth
    Layout.preferredHeight: row.implicitHeight

    readonly property int volumeStep: 2

    /* Lyrics LRC library */
    LyricsLrcLib {
        id: lyricsLrcLib
    }

    /* Spotify player */
    Spotify {
        id: spotify

        onReadyChanged: {
            Plasmoid.status = spotify.ready ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.HiddenStatus
        }

        onPositionChanged: {
            if (spotify.ready) {
                updateProgressIndicator()
            }
        }

        onArtworkUrlChanged: {
            if (spotify.ready) {
                let url = spotify.artworkUrl;
                if (url && url.startsWith("https://") && !plasmoid.configuration.fetchAlbumCoverHttps) {
                    url = url.replace("https://", "http://");
                }
                artwork.source = url || artwork.fallbackSource;

                lyricsRenderer.lyrics = null;
                lyricsLrcLib.fetchLyrics(spotify.track, spotify.artist, spotify.album).then(lyrics => {
                    lyricsRenderer.lyrics = lyrics;
                })
            }
        }
    }

    /* Progress bar updater */
    Timer {
        id: timer
        interval: 1000;
        running: spotify && spotify.playing;
        repeat: true
        onTriggered: () => {
            updateProgressIndicator()
        }
    }

    /* Mouse click handling */
    MouseArea {
        id: mouseArea
        z: 100
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        onClicked: (mouse) => {
            switch (mouse.button) {
                case Qt.MiddleButton:
                    spotify.togglePlayback()
                    break
                case Qt.LeftButton:
                    if (spotify.canRaise) {
                        spotify.raise()
                    } else if (!spotify.ready) {
                        Qt.openUrlExternally("spotify:") // Open Spotify app if not ready
                    }
                    break
            }
        }

        onWheel: (wheel) => {
            if (wheel.modifiers & Qt.ShiftModifier) {
                if (wheel.angleDelta.y > 0) {
                    spotify.nextSong()
                } else {
                    spotify.previousSong()
                }
            } else {
                if (wheel.angleDelta.y > 0) {
                    spotify.changeVolume(volumeStep / 100, true)
                } else {
                    spotify.changeVolume(-volumeStep / 100, true)
                }
            }
        }

        onExited : () => {
            title.x = 0
            artist.x = 0
        }
    }

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 0
        clip: true

        LyricsRenderer {
            id: lyricsRenderer
            lyrics: null
            spotify: spotify
            visible: plasmoid.configuration.showLyrics && spotify && spotify.ready && lyrics && lyrics.length > 0

            Layout.fillWidth: true
        }

        /* Album artwork */
        Image {
            id: artwork

            Layout.preferredWidth: parent.height
            Layout.preferredHeight: parent.height
            Layout.rightMargin: 5
            Layout.fillWidth: false
            fillMode: Image.PreserveAspectFit

            property string fallbackSource: "../assets/icon.svg"
            property string lastAttemptedSource: ""

            source: artwork.fallbackSource
            visible: plasmoid.configuration.showAlbumCover

            Timer {
                id: fallbackTimer
                interval: 1000
                repeat: false
                onTriggered: {
                    console.warn("Failed to load artwork from", artwork.lastAttemptedSource)
                    artwork.source = artwork.fallbackSource
                }
            }

            onSourceChanged: {
                if (source === fallbackSource) {
                    fallbackTimer.stop()
                } else {
                    fallbackTimer.restart()
                    lastAttemptedSource = source
                }
            }

            onStatusChanged: {
                switch (status) {
                    case Image.Ready:
                        fallbackTimer.stop()
                        break
                }
            }

            /* Border radius */
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Item {
                    width: artwork.width
                    height: artwork.height
                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                    }
                }
            }
        }

        /* Song information */
        Item {
            // Layout.preferredWidth: column.implicitWidth
            id: songInfoContainer
            Layout.preferredHeight: column.implicitHeight
            Layout.fillWidth: true
            Layout.rightMargin: 2
            clip: true
            property bool titleNeedsScroll: title.implicitWidth > width
            property bool artistNeedsScroll: artist.implicitWidth > width

            ColumnLayout {
                id: column
                anchors.fill: parent
                spacing: 0

                /* Song title */
                Text {
                    id: title
                    wrapMode: Text.NoWrap
                    elide: Text.ElideNone
                    Layout.fillWidth: true
                    Layout.rightMargin: 20

                    color: Kirigami.Theme.textColor
                    font: Qt.font(Object.assign({}, Kirigami.Theme.defaultFont, {weight: Font.Bold}))
                    text: spotify && spotify.ready ? spotify.track : "Spotify"

                    SequentialAnimation on x {
                        running: songInfoContainer.titleNeedsScroll && mouseArea.containsMouse
                        loops: Animation.Infinite
                        PauseAnimation { duration: 100 }
                        NumberAnimation { to: -title.implicitWidth + songInfoContainer.width; duration: Math.max(2000, title.implicitWidth * 10) }
                        PauseAnimation { duration: 1000 }
                        NumberAnimation { to: 0; duration: 150 }
                        PauseAnimation { duration: 1000 }
                    }


                }

                /* Artist name */
                Text {
                    id: artist
                    wrapMode: Text.NoWrap
                    elide: Text.ElideNone
                    Layout.fillWidth: true
                    Layout.rightMargin: 20

                    color: Kirigami.Theme.textColor
                    font: Kirigami.Theme.defaultFont
                    text: spotify && spotify.ready ? spotify.artist : "No song playing"


                    SequentialAnimation on x {
                        running: songInfoContainer.artistNeedsScroll && mouseArea.containsMouse
                        loops: Animation.Infinite
                        NumberAnimation { to: 0; duration: 150 }
                        PauseAnimation { duration: 100 }
                        NumberAnimation { to: -artist.implicitWidth + songInfoContainer.width; duration: Math.max(2000, artist.implicitWidth * 10) }
                        PauseAnimation { duration: 1000 }
                    }
                }
            }
        }
    }


    /* Progress bar */
    Rectangle {
        id: progress
        visible: spotify && spotify.ready

        x: 2
        height: 3
        width: parent.implicitWidth//width: artwork.width - 4
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 2
        anchors.rightMargin: 2
        color: "#282828"

        Rectangle {
            id: progressIndicator
            anchors.bottom: parent.bottom
            height: 2
            width: 0
            color: "#1db954"
        }
    }


    function updateProgressIndicator() {
        if (spotify.ready) {
            progressIndicator.width = Math.min(1, (spotify.getDaemonPosition() / spotify.length)) * progress.width
        }
    }
}
