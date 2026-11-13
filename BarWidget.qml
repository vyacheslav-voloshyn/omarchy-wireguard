import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

// Left click brings the connection up or down; right click opens nmtui.
// State follows `nmcli monitor` events, so there is no polling.
BarWidget {
  id: root
  moduleName: "amsi.wireguard"

  // Empty means the first WireGuard connection NetworkManager knows, so a
  // single tunnel works without any setup.
  readonly property string configured: String(setting("connection", ""))
  property string detected: ""
  readonly property string connection: configured !== "" ? configured : detected
  // "activated", "activating", "deactivating", or "" when down or missing.
  property string vpnState: ""

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function refresh() {
    // Re-detect on every event: the tunnel may be imported after the bar starts.
    if (root.configured === "" && !detectProc.running) detectProc.running = true
    if (root.connection === "") {
      root.vpnState = ""
      return
    }
    if (!stateProc.running) stateProc.running = true
    else refreshDebounce.restart()
  }

  onConnectionChanged: refresh()

  Process {
    id: detectProc
    command: ["nmcli", "-g", "TYPE,NAME", "connection", "show"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var lines = String(text || "").split("\n")
        var found = ""
        for (var i = 0; i < lines.length && found === ""; i++)
          // Terse output escapes a colon inside a name as "\:".
          if (lines[i].indexOf("wireguard:") === 0)
            found = lines[i].slice("wireguard:".length).replace(/\\(.)/g, "$1")
        root.detected = found
      }
    }
  }

  Timer {
    id: refreshDebounce
    interval: 300
    onTriggered: root.refresh()
  }

  Process {
    id: stateProc
    command: ["nmcli", "-g", "GENERAL.STATE", "connection", "show", root.connection]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.vpnState = String(text || "").trim()
    }
    onExited: function(exitCode) { if (exitCode !== 0) root.vpnState = "" }
  }

  Process {
    id: monitorProc
    running: true
    command: ["nmcli", "monitor"]
    stdout: SplitParser { onRead: function() { refreshDebounce.restart() } }
    // nmcli monitor exits when NetworkManager restarts; reattach.
    onExited: restartMonitor.start()
  }

  Timer {
    id: restartMonitor
    interval: 3000
    onTriggered: { monitorProc.running = true; root.refresh() }
  }

  Component.onCompleted: refresh()

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰦝"
    dimmed: root.vpnState !== "activated"
    active: root.vpnState === "activating" || root.vpnState === "deactivating"
    tooltipText: root.connection === ""
      ? "No WireGuard connection in NetworkManager"
      : root.connection + ": " + (root.vpnState || "down")
    onPressed: function(b) {
      if (!root.bar) return
      if (b !== Qt.RightButton && root.connection === "") return
      if (b === Qt.RightButton) root.bar.run("xdg-terminal-exec nmtui")
      else {
        root.bar.run("nmcli connection " + (root.vpnState === "activated" ? "down" : "up") + " id " + Util.shellQuote(root.connection))
        refreshDebounce.restart()
      }
    }
  }
}
