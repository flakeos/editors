{ config, lib, pkgs, ... }:

let
  inherit (lib) types mkIf mkOption mkEnableOption hasSuffix removeSuffix;

  cfg = config.programs.editors;

  editorsInfo = lib.importJSON ../editors.json;

  isEditorSpecific = name:
    hasSuffix ".json" name && editorsInfo ? ${removeSuffix ".json" name};

  loadSettings = dir:
    let
      files = builtins.attrNames (builtins.readDir dir);
      common = builtins.filter (f: !isEditorSpecific f) files;
    in map (f: lib.importJSON "${dir}/${f}") common;

  buildEditorConfig = { editorName, editorInfo, mergedDefaults }:
    let
      ec = cfg.editors.${editorName} or { };
      userDir = "${cfg.configDir}/${editorInfo.dir}/User";
      settings = lib.recursiveUpdate mergedDefaults (ec.settings or { });
      keybindings = (lib.importJSON cfg.keybindingsFile) ++ (ec.keybindings or [ ]);
    in lib.optionalAttrs (ec.enable or false) {
      "${userDir}/settings.json".text = builtins.toJSON settings;
      "${userDir}/keybindings.json".text = builtins.toJSON keybindings;
      "${userDir}/tasks.json".source = cfg.tasksFile;
      "${userDir}/launch.json".source = cfg.launchFile;
    } // lib.optionalAttrs (ec.enable or false) (
      builtins.listToAttrs (map (sn: {
        name = "${userDir}/snippets/${sn}";
        value.source = "${cfg.snippetsDir}/${sn}";
      }) (builtins.attrNames (builtins.readDir cfg.snippetsDir)))
    );
in {
  options.programs.editors = {
    enable = mkEnableOption "editor configuration manager";

    enableAll = mkOption {
      type = types.bool;
      default = false;
      description = "Enable for all known editors";
    };

    configDir = mkOption {
      type = types.str;
      default = if pkgs.stdenv.isDarwin
        then "Library/Application Support"
        else ".config";
      description = "Editor config directory relative to $HOME";
    };

    settingsDir = mkOption {
      type = types.path;
      default = ../config/settings;
      description = "Directory with JSON settings files to merge";
    };

    keybindingsFile = mkOption {
      type = types.path;
      default = ../config/keybindings.json;
      description = "Path to default keybindings JSON";
    };

    tasksFile = mkOption {
      type = types.path;
      default = ../config/tasks.json;
      description = "Path to tasks JSON";
    };

    launchFile = mkOption {
      type = types.path;
      default = ../config/launch.json;
      description = "Path to launch configuration JSON";
    };

    snippetsDir = mkOption {
      type = types.path;
      default = ../config/snippets;
      description = "Directory with snippet JSON files";
    };

    defaultSettings = mkOption {
      type = types.attrs;
      readOnly = true;
      internal = true;
      description = "Merged default settings from settingsDir";
    };

    editors = mkOption {
      description = "Per-editor configuration";
      default = { };
      type = types.attrsOf (types.submodule {
        options = {
          enable = mkEnableOption "this editor's configuration";
          settings = mkOption {
            type = types.attrs;
            default = { };
            description = "Settings merged on top of defaults";
          };
          keybindings = mkOption {
            type = types.listOf types.attrs;
            default = [ ];
            description = "Extra keybindings appended to defaults";
          };
        };
      });
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (let
      mergedDefaults = lib.foldl lib.recursiveUpdate { } (loadSettings cfg.settingsDir);
    in {
      home.file = builtins.foldl' lib.recursiveUpdate { }
        (map (name: buildEditorConfig {
          inherit name;
          editorInfo = editorsInfo.${name};
          mergedDefaults = mergedDefaults;
        }) (builtins.attrNames editorsInfo));

      programs.editors.defaultSettings = mergedDefaults;
    })

    (mkIf cfg.enableAll {
      programs.editors.editors = builtins.listToAttrs (map (name: {
        inherit name;
        value = { enable = true; };
      }) (builtins.attrNames editorsInfo));
    })
  ]);
}
