// noinspection UnnecessaryReturnStatementJS

import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

Item {
    Utils {
        id: utils
    }

    readonly property string endpoint: "https://lrclib.net"
    readonly property string url_search: endpoint + "/api/search"

    function fetchLyrics(trackName, artistName, albumName) {
        return search(trackName, artistName, albumName)
            .then(data => {
            if (data.length <= 0) {
                return null;
            }

            let text = data[0].syncedLyrics;
            if (!text) {
                return null;
            }

            return utils.parseLyrics(text);
        });
    }

    function search(trackName, artistName, albumName) {
        return searchByTrack(trackName, artistName, albumName)
            .then(data => {
                if (data.length > 0) {
                    return data;
                }
                return searchByString(trackName + " " + artistName)
                    .then(data2 => {
                        if (data2.length > 0) {
                            return data2;
                        }
                        return searchByString(trackName)
                            .then(data3 => {
                                if (data3.length > 0) {
                                    // Remove all entries with wrong artist
                                    data3 = data3.filter(item => {
                                        return item.artistName.toLowerCase() === artistName.toLowerCase();
                                    });
                                    return data3;
                                }
                                return [];
                            });
                    });
            });
    }

    function searchByTrack(trackName, artistName, albumName) {
        let url = url_search
            + "?track_name=" + encodeURIComponent(trackName)
            + "&artist_name=" + encodeURIComponent(artistName)
            + "&album_name=" + encodeURIComponent(albumName);

        return utils.fetch(url)
            .then(response => response.json());
    }

    function searchByString(query) {
        let url = url_search + "?q=" + encodeURIComponent(query);

        return utils.fetch(url)
            .then(response => response.json());
    }

}
