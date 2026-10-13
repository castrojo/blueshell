#!/bin/sh
# TunaOS launcher for stock upstream Ghostty (com.mitchellh.ghostty).
#
# Flatpak redirects XDG_CONFIG_HOME into ~/.var/app/<id>/config, so
# Ghostty never reads ~/.config/ghostty -- the path users are told to
# edit (tuna-os/blueshell#117). Pass the host config explicitly as
# optional config files; the leading `?` makes each one silently
# skipped when missing. These load after the default files, so the
# host config wins over the sandbox-local one.
#
# Both names are passed (legacy first) because the default filename
# changed across Ghostty versions; only existing files take effect.
host_base="${HOST_XDG_CONFIG_HOME:-$HOME/.config}/ghostty"
exec /app/bin/ghostty.bin \
    "--config-file=?$host_base/config" \
    "--config-file=?$host_base/config.ghostty" \
    "$@"
