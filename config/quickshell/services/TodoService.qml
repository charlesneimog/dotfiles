// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   T O D O   S E R V I C E                                                │
// │   Nextcloud task synchronization                                         │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

pragma Singleton

import QtQuick

QtObject {
    id: root

    property var tasks: []
    property bool loading: false

    function refresh() {
        console.log("[TodoService] refresh")
    }

    function completeTask(task) {
        console.log("[TodoService] complete:", task)
    }
}
