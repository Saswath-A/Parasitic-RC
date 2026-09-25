#!/usr/bin/env bash
set -Eeuo pipefail

PREFIX="${VLSI_PREFIX:-$HOME/.local/vlsi-rc}"
SRC_DIR="${VLSI_SRC_DIR:-$HOME/.cache/vlsi-rc-src}"
CONFIG_DIR="${VLSI_CONFIG_DIR:-$HOME/.config/vlsi-rc}"
LOCAL_BIN="${VLSI_LOCAL_BIN:-$HOME/.local/bin}"
KEEP_SOURCES=0
FORCE=0

usage() {
  cat <<USAGE
Usage: $0 [options]

Options:
  --keep-sources   Keep Git source/build trees under ~/.cache/vlsi-rc-src.
  --force          Remove the configured prefix even if its ownership marker
                   is missing. Use only if you know the prefix is disposable.
  -h, --help       Show this help.

Rollback removes only files owned by this toolchain. It deliberately does not
uninstall distro packages because they may be shared with unrelated software.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep-sources) KEEP_SOURCES=1 ;;
    --force) FORCE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
  shift
done

echo "== VLSI RC toolchain rollback v2 =="
echo "Prefix : $PREFIX"
echo "Sources: $SRC_DIR"
echo "State  : $CONFIG_DIR"

# Remove only launcher symlinks that resolve into our prefix.
for f in vlsi-xschem vlsi-magic vlsi-rc-doctor; do
  p="$LOCAL_BIN/$f"
  if [[ -L "$p" ]]; then
    target="$(readlink "$p")"
    if [[ "$target" == "$PREFIX"/* ]]; then
      rm -f "$p"
      echo "Removed $p"
    fi
  fi
done

# Remove only our marked block from ~/.spiceinit. This preserves changes the
# user may have made after installation. If we created the file and it becomes
# empty afterwards, remove it.
SPICEINIT="$HOME/.spiceinit"
if [[ -f "$SPICEINIT" ]]; then
  python3 - "$SPICEINIT" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
text = p.read_text()
start = "# BEGIN VLSI_RC_TOOLCHAIN"
end = "# END VLSI_RC_TOOLCHAIN"
if start in text and end in text:
    before = text.split(start, 1)[0]
    after = text.split(end, 1)[1]
    out = before.rstrip() + ("\n\n" if before.rstrip() and after.lstrip("\n") else "") + after.lstrip("\n")
    p.write_text(out.rstrip() + ("\n" if out.strip() else ""))
PY
  if [[ -f "$CONFIG_DIR/spiceinit.created-by-installer" ]] && [[ ! -s "$SPICEINIT" ]]; then
    rm -f "$SPICEINIT"
    echo "Removed installer-created empty ~/.spiceinit"
  fi
fi

if [[ -d "$PREFIX" ]]; then
  if [[ -f "$PREFIX/.vlsi-rc-owned" || $FORCE -eq 1 ]]; then
    rm -rf "$PREFIX"
    echo "Removed $PREFIX"
  else
    echo "REFUSING to remove $PREFIX: ownership marker is missing." >&2
    echo "If this directory is definitely the VLSI RC prefix, rerun with --force." >&2
    exit 4
  fi
fi

if (( KEEP_SOURCES == 0 )); then
  if [[ -d "$SRC_DIR" ]]; then
    rm -rf "$SRC_DIR"
    echo "Removed $SRC_DIR"
  fi
else
  echo "Kept source directory: $SRC_DIR"
fi

if [[ -d "$CONFIG_DIR" ]]; then
  rm -rf "$CONFIG_DIR"
  echo "Removed $CONFIG_DIR"
fi

echo
echo "Rollback complete."
echo "OS build dependencies were intentionally left installed."
echo "That is safer than removing shared compiler/X11/Tcl/Tk/Python packages."
