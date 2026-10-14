{
  inputs,
  pkgs,
  ...
}:
let
  sessionDesktop = pkgs.callPackage ./packages/session-desktop.nix { };
  vesperStartpage = inputs.self.packages.${pkgs.system}.vesper-startpage;
  staticStartpage = "file://${vesperStartpage}/share/vesper-startpage/index.html";
  heliumPackage = inputs.helium.packages.${pkgs.system}.default;
  torBrowserPackage = pkgs.tor-browser;
  heliumStartpage = pkgs.writeShellApplication {
    name = "helium";
    text = ''
      if [ "$#" -eq 0 ]; then
        set -- "${staticStartpage}"
      fi
      exec ${heliumPackage}/bin/helium \
        "--homepage=${staticStartpage}" \
        "--custom-ntp=${staticStartpage}" \
        "$@"
    '';
  };
  torBrowserStartpage = pkgs.writeShellApplication {
    name = "tor-browser";
    text = ''
      if [ "$#" -eq 0 ]; then
        exec ${torBrowserPackage}/bin/tor-browser "${staticStartpage}"
      fi
      exec ${torBrowserPackage}/bin/tor-browser "$@"
    '';
  };
in
{
  imports = [ inputs.zen-browser.homeModules.beta ];

  xdg.configFile."helium-browser-flags.conf".text = ''
    # Vesper standalone startpage for startup and every new tab.
    --homepage=${staticStartpage}
    --custom-ntp=${staticStartpage}
  '';

  programs.zen-browser = {
    enable = true;
    setAsDefaultBrowser = true;
    profiles.default.name = "default";
    profiles.default.isDefault = true;
    policies.Homepage = {
      URL = staticStartpage;
      Locked = true;
      StartPage = "homepage";
    };
  };

  xdg.desktopEntries.helium = {
    name = "Helium";
    genericName = "Web Browser";
    comment = "Helium with the Vesper local startpage";
    exec = "${heliumStartpage}/bin/helium %U";
    icon = "web-browser";
    terminal = false;
    categories = [ "Network" "WebBrowser" ];
    mimeType = [ "text/html" "application/xhtml+xml" "x-scheme-handler/http" "x-scheme-handler/https" ];
  };

  xdg.desktopEntries.tor-browser = {
    name = "Tor Browser";
    genericName = "Privacy Web Browser";
    comment = "Tor Browser with the Vesper local startpage";
    exec = "${torBrowserStartpage}/bin/tor-browser %U";
    icon = "${torBrowserPackage}/share/icons/hicolor/128x128/apps/tor-browser.png";
    terminal = false;
    categories = [ "Network" "WebBrowser" "Security" ];
    mimeType = [
      "text/html"
      "text/xml"
      "application/xhtml+xml"
      "application/vnd.mozilla.xul+xml"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
    ];
  };

  programs.vicinae = {
    enable = true;
    systemd = {
      enable = true;
      autoStart = true;
    };
    settings = {
      imports = [ "vesper.json" ];
    };
  };

  # Script commands are indexed by Vicinae's root search. They are discovery
  # entries, not desktop applications, so neither app is installed by default.
  home.file.".local/share/vicinae/scripts/vesper-store-chatgpt".text = ''
    # @vicinae.schemaVersion 1
    # @vicinae.title Get ChatGPT
    # @vicinae.mode silent
    # @vicinae.icon ✨
    # @vicinae.description Recommended app · opens Vesper Store
    # @vicinae.keywords ["chatgpt", "openai", "ai", "recommended", "store"]
    # @vicinae.exec ["vesper-store", "--search", "ChatGPT"]
  '';

  home.file.".local/share/vicinae/scripts/vesper-store-claude".text = ''
    # @vicinae.schemaVersion 1
    # @vicinae.title Get Claude
    # @vicinae.mode silent
    # @vicinae.icon 🤖
    # @vicinae.description Recommended app · opens Vesper Store
    # @vicinae.keywords ["claude", "anthropic", "ai", "recommended", "store"]
    # @vicinae.exec ["vesper-store", "--search", "Claude Desktop"]
  '';

  programs.vesktop = {
    enable = true;
    vencord.useSystem = true;

    settings = {
      appBadge = true;
      arRPC = true;
      checkUpdates = false;
      customTitleBar = false;
      disableMinSize = true;
      hardwareAcceleration = true;
      minimizeToTray = true;
      tray = true;
      discordBranch = "stable";
    };

    vencord.settings = {
      autoUpdate = false;
      autoUpdateNotification = false;
      notifyAboutUpdates = false;
    };
  };

  home.packages = with pkgs; [
    heliumStartpage
    vesperStartpage
    torBrowserStartpage

    sessionDesktop
    telegram-desktop

    ghostty
    thunar
    tumbler
    file-roller
    imv

    bottles

    obsidian
    inputs.self.packages.${pkgs.system}.t3code-nightly
    inputs.vesper-store.packages.${pkgs.system}.vesper-store
  ];

  # Keep Store-owned binaries and desktop entries visible after a transaction
  # without replacing the system's existing PATH or XDG data directories.
  home.sessionPath = [ "$HOME/.local/state/vesper/store/profile/bin" ];
  home.sessionSearchVariables.XDG_DATA_DIRS = [
    "$HOME/.local/state/vesper/store/profile/share"
  ];

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = [ "zen-beta.desktop" ];
      "application/xhtml+xml" = [ "zen-beta.desktop" ];
      "x-scheme-handler/http" = [ "zen-beta.desktop" ];
      "x-scheme-handler/https" = [ "zen-beta.desktop" ];

      "audio/mpeg" = [ "mpv.desktop" ];
      "audio/flac" = [ "mpv.desktop" ];
      "audio/ogg" = [ "mpv.desktop" ];
      "audio/x-wav" = [ "mpv.desktop" ];
      "video/mp4" = [ "mpv.desktop" ];
      "video/webm" = [ "mpv.desktop" ];
      "video/x-matroska" = [ "mpv.desktop" ];
    };
  };
}
