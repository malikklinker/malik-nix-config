{ pkgs, ... }:

{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "desktop-volume";
      runtimeInputs = [ pkgs.wireplumber ];
      text = ''
        case "''${1:-}" in
          up)
            wpctl set-volume --limit 1 @DEFAULT_AUDIO_SINK@ 5%+
            wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
            ;;
          down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
          mute) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
          mic-mute) wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle ;;
          *) echo "Usage: desktop-volume {up|down|mute|mic-mute}" >&2; exit 2 ;;
        esac
      '';
    })
  ];
}
