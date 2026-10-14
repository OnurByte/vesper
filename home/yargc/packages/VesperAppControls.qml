pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus.common

ColumnLayout {
    id: root

    property var app
    property var status: ({ sandbox: "unknown", owner: "unresolved", desktopPath: "", flatpakScope: "", flatpakId: "", permissions: "", removable: false, todaySeconds: 0 })
    property var liquidGlass: ({ cache: "missing", managed: false })
    property string message: ""
    property bool messageOk: false
    property bool removalArmed: false

    Layout.fillWidth: true
    spacing: Tokens.spacing.extraSmall / 2

    readonly property bool flatpak: status.sandbox === "flatpak"
    readonly property bool ownershipUnknown: status.sandbox === "unknown"
    readonly property bool networkAllowed: flatpak && status.permissions.includes("shared=network")
    readonly property bool homeAllowed: flatpak && (status.permissions.includes("filesystems=home") || status.permissions.includes(";home;") || status.permissions.includes(";home:"))

    function duration(seconds) {
        const minutes = Math.floor((seconds || 0) / 60);
        if (minutes < 60)
            return qsTr("%1 min").arg(minutes);
        return qsTr("%1 h %2 min").arg(Math.floor(minutes / 60)).arg(minutes % 60);
    }

    function commandKey(command) {
        return [...(command ?? [])].join("\u0000");
    }

    function defaultRoles() {
        if (!root.app)
            return [];

        const key = root.commandKey(root.app.command);
        const defaults = GlobalConfig.general.apps;
        const roles = [];
        if (root.commandKey(defaults.terminal) === key)
            roles.push(qsTr("Terminal"));
        if (root.commandKey(defaults.audio) === key)
            roles.push(qsTr("Audio"));
        if (root.commandKey(defaults.playback) === key)
            roles.push(qsTr("Media playback"));
        if (root.commandKey(defaults.explorer) === key)
            roles.push(qsTr("File manager"));
        return roles;
    }

    function refresh() {
        if (!root.app)
            return;
        if (!appStatus.running) {
            appStatus.command = ["@vesperControl@", "app-status", root.app.id];
            appStatus.running = true;
        }
        if (!liquidGlassStatus.running) {
            liquidGlassStatus.command = ["@vesperControl@", "liquid-glass", "status", "--desktop-id", root.app.id, "--json"];
            liquidGlassStatus.running = true;
        }
    }

    function runLiquidGlass(args, successMessage) {
        if (!root.app || iconAction.running)
            return;
        root.message = "";
        root.messageOk = false;
        iconAction.successMessage = successMessage;
        iconAction.command = ["@vesperControl@", "liquid-glass"].concat(args);
        iconAction.running = true;
    }

    onAppChanged: {
        root.removalArmed = false;
        refresh();
    }
    Component.onCompleted: refresh()

    Process {
        id: appStatus
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.status = JSON.parse(text);
                } catch (e) {
                    root.message = qsTr("Could not read app controls");
                    root.messageOk = false;
                }
            }
        }
    }

    Process {
        id: liquidGlassStatus
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.liquidGlass = JSON.parse(text).data?.[0] || ({ cache: "missing", managed: false });
                } catch (e) {
                    root.liquidGlass = ({ cache: "missing", managed: false });
                }
            }
        }
    }

    Process {
        id: permissionChange
        stderr: StdioCollector { id: permissionError }
        onExited: (code, status) => {
            root.message = code === 0 ? "" : permissionError.text.trim();
            root.messageOk = code === 0;
            root.refresh();
        }
    }

    Process {
        id: appRemove
        stderr: StdioCollector { id: appRemoveError }
        onExited: (code, status) => {
            root.removalArmed = false;
            if (code === 0) {
                root.message = qsTr("Application removed");
                root.messageOk = true;
            } else {
                root.message = appRemoveError.text.trim() || qsTr("Could not remove application");
                root.messageOk = false;
                root.refresh();
            }
        }
    }

    Process {
        id: iconAction
        property string successMessage: ""
        stderr: StdioCollector { id: iconError }
        onExited: (code, status) => {
            if (code === 0) {
                root.message = successMessage;
                root.messageOk = true;
            } else {
                root.message = iconError.text.trim();
                root.messageOk = false;
            }
            root.refresh();
        }
    }

    SectionHeader {
        text: qsTr("Application")
    }

    RowButton {
        icon: "open_in_new"
        text: qsTr("Open")
        subtext: qsTr("Launch the canonical desktop entry")
        disabled: !root.app
        onClicked: {
            if (root.app)
                root.app.execute();
        }
    }

    InfoRow {
        visible: (root.app?.categories?.length ?? 0) > 0
        icon: "category"
        label: qsTr("Categories")
        value: [...(root.app?.categories ?? [])].join(", ")
    }

    InfoRow {
        visible: (root.app?.startupClass ?? "").length > 0
        icon: "window"
        label: qsTr("Startup class")
        subtext: qsTr("window identity hint from the desktop entry")
        value: root.app?.startupClass ?? ""
    }

    InfoRow {
        visible: root.defaultRoles().length > 0
        icon: "check_circle"
        label: qsTr("Default")
        subtext: qsTr("managed by Apps → Default applications")
        value: root.defaultRoles().join(", ")
        iconColour: Colours.palette.m3primary
    }

    RowButton {
        visible: root.status.removable && !root.removalArmed
        icon: "delete"
        text: qsTr("Remove")
        subtext: qsTr("Uninstall this user Flatpak")
        disabled: appRemove.running
        onClicked: root.removalArmed = true
    }

    RowButton {
        visible: root.status.removable && root.removalArmed
        icon: "warning"
        text: qsTr("Confirm removal")
        subtext: qsTr("Uninstall %1 from this user").arg(root.app?.name ?? qsTr("this application"))
        disabled: appRemove.running
        onClicked: {
            if (!root.app || appRemove.running)
                return;
            root.message = "";
            root.messageOk = false;
            appRemove.command = ["@vesperControl@", "app-remove", root.app.id];
            appRemove.running = true;
        }
    }

    RowButton {
        visible: root.status.removable && root.removalArmed
        icon: "close"
        text: qsTr("Cancel removal")
        disabled: appRemove.running
        onClicked: root.removalArmed = false
    }

    SectionHeader {
        text: qsTr("Privacy & permissions")
    }

    InfoRow {
        icon: root.flatpak ? "deployed_code" : root.ownershipUnknown ? "help" : "warning"
        label: qsTr("Sandbox")
        subtext: root.flatpak ? root.status.flatpakId : root.ownershipUnknown ? qsTr("effective package owner could not be verified") : qsTr("native app · Flatpak overrides do not apply")
        value: root.flatpak ? qsTr("Flatpak") : root.ownershipUnknown ? qsTr("unknown") : qsTr("native")
        iconColour: root.flatpak ? Colours.palette.m3primary : Colours.palette.m3tertiary
    }

    InfoRow {
        visible: (root.status.owner || "unresolved") !== "unresolved"
        icon: "inventory_2"
        label: qsTr("Source owner")
        subtext: root.status.desktopPath || qsTr("effective desktop entry")
        value: root.status.owner || qsTr("unknown")
    }

    ToggleRow {
        visible: root.flatpak
        text: qsTr("Network access")
        subtext: qsTr("Flatpak network share override")
        checked: root.networkAllowed
        disabled: permissionChange.running
        onToggled: {
            permissionChange.command = ["@vesperControl@", "app-permission", root.app.id, "network", checked ? "on" : "off"];
            permissionChange.running = true;
        }
    }

    ToggleRow {
        visible: root.flatpak
        text: qsTr("Home folder access")
        subtext: qsTr("Flatpak home filesystem override")
        checked: root.homeAllowed
        disabled: permissionChange.running
        onToggled: {
            permissionChange.command = ["@vesperControl@", "app-permission", root.app.id, "home", checked ? "on" : "off"];
            permissionChange.running = true;
        }
    }

    RowButton {
        visible: root.flatpak
        icon: "restart_alt"
        text: qsTr("Reset Flatpak overrides")
        subtext: qsTr("return this app to its packaged permissions")
        disabled: permissionChange.running
        onClicked: {
            permissionChange.command = ["@vesperControl@", "app-reset-permissions", root.app.id];
            permissionChange.running = true;
        }
    }

    SectionHeader {
        text: qsTr("Wellbeing")
    }

    InfoRow {
        icon: "timer"
        label: qsTr("Foreground time today")
        subtext: qsTr("local Hyprland activity sample")
        value: root.duration(root.status.todaySeconds)
    }

    SectionHeader {
        text: qsTr("Liquid Glass icon")
    }

    InfoRow {
        icon: "image"
        label: qsTr("Local cache")
        subtext: root.liquidGlass.cache === "current"
            ? qsTr("canonical SVG is current")
            : root.liquidGlass.cache === "stale"
                ? qsTr("source changed · reconvert deliberately in Liquid Glass Icons")
                : qsTr("no current local conversion")
        value: root.liquidGlass.cache || qsTr("missing")
    }

    InfoRow {
        icon: root.liquidGlass.managed ? "verified" : "image_not_supported"
        label: qsTr("Desktop override")
        subtext: root.liquidGlass.managed
            ? qsTr("user hicolor override is active")
            : qsTr("original packaged icon remains active")
        value: root.liquidGlass.managed ? qsTr("managed") : qsTr("original")
        iconColour: root.liquidGlass.managed ? Colours.palette.m3primary : Colours.palette.m3tertiary
    }

    RowButton {
        icon: "sync"
        text: qsTr("Reapply this icon")
        subtext: qsTr("render the current local cache for the active appearance without AI")
        trailingIcon: "refresh"
        disabled: !root.app || iconAction.running || root.liquidGlass.cache !== "current"
        onClicked: root.runLiquidGlass(["apply", "--desktop-id", root.app.id, "--appearance", Colours.light ? "tinted-light" : "tinted-dark", "--json"], qsTr("Liquid Glass icon applied from the local cache"))
    }

    RowButton {
        icon: "restore"
        text: qsTr("Restore original icon")
        subtext: qsTr("remove only the managed user desktop override")
        trailingIcon: "restore"
        disabled: !root.app || iconAction.running || !root.liquidGlass.managed
        onClicked: root.runLiquidGlass(["restore", "--desktop-id", root.app.id, "--json"], qsTr("Original icon restored"))
    }

    StyledText {
        Layout.fillWidth: true
        Layout.leftMargin: Tokens.padding.largeIncreased
        visible: root.message
        text: root.message
        color: root.messageOk ? Colours.palette.m3primary : Colours.palette.m3error
        font: Tokens.font.label.small
        wrapMode: Text.WordWrap
    }
}
