#!/usr/bin/env bash
set -Eeuo pipefail

# Idempotent, user-local SKY130 coursework toolchain installer.
# Supported package-manager families:
#   apt      : Debian / Ubuntu / Mint / WSL2 Ubuntu
#   pacman   : Arch / EndeavourOS / Manjaro
#   dnf      : Fedora / Rocky / Alma / RHEL-family
#   zypper   : openSUSE Leap / Tumbleweed
#
# Re-running this script is safe:
#   * distro package managers skip already-installed dependencies
#   * source repositories are reused
#   * tools are rebuilt only when the requested Git commit changes,
#     their install is missing, or --force is supplied
#   * SKY130/Open_PDKs is skipped when the installed PDK is complete and
#     already matches the requested Open_PDKs commit

PREFIX="${VLSI_PREFIX:-$HOME/.local/vlsi-rc}"
SRC_DIR="${VLSI_SRC_DIR:-$HOME/.cache/vlsi-rc-src}"
CONFIG_DIR="${VLSI_CONFIG_DIR:-$HOME/.config/vlsi-rc}"
LOG_DIR="$CONFIG_DIR/logs"
STAMP_DIR="$CONFIG_DIR/stamps"
LOCAL_BIN="${VLSI_LOCAL_BIN:-$HOME/.local/bin}"
JOBS="${VLSI_JOBS:-}"

XSCHEM_REF="${XSCHEM_REF:-master}"
MAGIC_REF="${MAGIC_REF:-master}"
NETGEN_REF="${NETGEN_REF:-master}"
NGSPICE_REF="${NGSPICE_REF:-master}"
OPEN_PDKS_REF="${OPEN_PDKS_REF:-master}"

XSCHEM_URL="https://github.com/StefanSchippers/xschem.git"
MAGIC_URL="https://github.com/RTimothyEdwards/magic.git"
NETGEN_URL="https://github.com/RTimothyEdwards/netgen.git"
NGSPICE_URL="https://github.com/ngspice/ngspice.git"
OPEN_PDKS_URL="https://github.com/fossi-foundation/open-pdks.git"

NO_PACKAGES=0
NO_PDK=0
FORCE=0
OFFLINE=0

usage() {
  cat <<'USAGE'
Usage: install_vlsi_rc.sh [options]

Options:
  --force         Rebuild/reinstall all requested components even when the
                  installed revision already matches.
  --offline       Do not fetch from Git remotes. Existing source checkouts
                  must already contain the requested refs/commits.
  --no-packages   Do not install OS build dependencies.
  --no-pdk        Install/update tools only; skip SKY130/Open_PDKs.
  -h, --help      Show this help.

Environment overrides:
  VLSI_PREFIX       Install prefix (default: ~/.local/vlsi-rc)
  VLSI_SRC_DIR      Source/build directory (default: ~/.cache/vlsi-rc-src)
  VLSI_CONFIG_DIR   State/config directory (default: ~/.config/vlsi-rc)
  VLSI_JOBS         Parallel build jobs (default: min(nproc, 4))
  XSCHEM_REF        Git ref/commit for xschem (default: master)
  MAGIC_REF         Git ref/commit for magic (default: master)
  NETGEN_REF        Git ref/commit for netgen (default: master)
  NGSPICE_REF       Git ref/commit for ngspice (default: master)
  OPEN_PDKS_REF     Git ref/commit for open_pdks (default: master)

Examples:
  ./install_vlsi_rc.sh
  ./install_vlsi_rc.sh --force
  ./install_vlsi_rc.sh --no-pdk
  NGSPICE_REF=<commit> ./install_vlsi_rc.sh
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force) FORCE=1 ;;
    --offline) OFFLINE=1 ;;
    --no-packages) NO_PACKAGES=1 ;;
    --no-pdk) NO_PDK=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
  shift
done

mkdir -p "$PREFIX" "$SRC_DIR" "$CONFIG_DIR" "$LOG_DIR" "$STAMP_DIR" "$LOCAL_BIN"
# Ownership marker used by rollback to avoid deleting an unrelated directory.
touch "$PREFIX/.vlsi-rc-owned"

LOG_FILE="$LOG_DIR/install-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1
trap 'rc=$?; echo; echo "ERROR: installation stopped at line $LINENO (exit $rc)."; echo "Log: $LOG_FILE"; echo "Installed components are left intact; rerun the installer after fixing the issue."; exit $rc' ERR

if [[ -z "$JOBS" ]]; then
  if command -v nproc >/dev/null 2>&1; then n="$(nproc)"; else n=2; fi
  (( n > 4 )) && n=4
  (( n < 1 )) && n=1
  JOBS="$n"
fi

echo "== VLSI RC toolchain installer v2 =="
echo "Prefix : $PREFIX"
echo "Sources: $SRC_DIR"
echo "State  : $CONFIG_DIR"
echo "Jobs   : $JOBS"
echo "Force  : $FORCE"
echo "Offline: $OFFLINE"
echo "Log    : $LOG_FILE"
if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  echo "OS     : ${PRETTY_NAME:-${NAME:-unknown}}"
fi

detect_pm() {
  if command -v apt-get >/dev/null 2>&1; then echo apt
  elif command -v pacman >/dev/null 2>&1; then echo pacman
  elif command -v dnf >/dev/null 2>&1; then echo dnf
  elif command -v zypper >/dev/null 2>&1; then echo zypper
  else echo unsupported
  fi
}

sudo_cmd() {
  if (( EUID == 0 )); then
    "$@"
  else
    command -v sudo >/dev/null 2>&1 || { echo "sudo is required to install OS packages." >&2; exit 3; }
    sudo "$@"
  fi
}

install_packages() {
  local pm
  pm="$(detect_pm)"
  echo
  echo "== OS dependencies ($pm) =="
  case "$pm" in
    apt)
      sudo_cmd apt-get update
      sudo_cmd env DEBIAN_FRONTEND=noninteractive apt-get install -y \
        build-essential git autoconf automake libtool pkg-config \
        flex bison m4 gawk tcsh csh ca-certificates curl \
        tcl-dev tk-dev libx11-dev libxpm-dev libxext-dev libxrender-dev \
        libcairo2-dev libxft-dev libreadline-dev libncurses-dev zlib1g-dev \
        libglu1-mesa-dev freeglut3-dev mesa-common-dev libfftw3-dev \
        python3 python3-pip python3-venv
      ;;
    pacman)
      # Do not run a full system upgrade from a project installer.
      sudo_cmd pacman -S --needed --noconfirm \
        base-devel git autoconf automake libtool pkgconf \
        flex bison m4 gawk tcsh ca-certificates curl \
        tcl tk libx11 libxpm libxext libxrender cairo libxft \
        readline ncurses zlib glu freeglut fftw python python-pip
      ;;
    dnf)
      sudo_cmd dnf install -y \
        gcc gcc-c++ make git autoconf automake libtool pkgconf-pkg-config \
        flex bison m4 gawk tcsh ca-certificates curl \
        tcl-devel tk-devel libX11-devel libXpm-devel libXext-devel libXrender-devel \
        cairo-devel libXft-devel readline-devel ncurses-devel zlib-devel \
        mesa-libGLU-devel freeglut-devel fftw-devel python3 python3-pip
      ;;
    zypper)
      sudo_cmd zypper --non-interactive install \
        gcc gcc-c++ make git autoconf automake libtool pkg-config \
        flex bison m4 gawk tcsh ca-certificates curl \
        tcl-devel tk-devel libX11-devel libXpm-devel libXext-devel libXrender-devel \
        cairo-devel libXft-devel readline-devel ncurses-devel zlib-devel \
        Mesa-libGLU-devel freeglut-devel fftw3-devel python3 python3-pip
      ;;
    *)
      echo "Unsupported package manager. Supported: apt, pacman, dnf, zypper." >&2
      echo "Use a supported distro/WSL2 image, or install dependencies manually and rerun with --no-packages." >&2
      exit 3
      ;;
  esac
}

if (( NO_PACKAGES == 0 )); then
  install_packages
else
  echo "Skipping OS package installation (--no-packages)."
fi

export PATH="$PREFIX/bin:$PATH"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/lib64/pkgconfig:${PKG_CONFIG_PATH:-}"

ensure_repo() {
  local name="$1" url="$2" dir="$SRC_DIR/$name"
  if [[ ! -d "$dir/.git" ]]; then
    (( OFFLINE == 0 )) || { echo "[FAIL] $name source is missing and --offline was requested." >&2; exit 4; }
    echo "[CLONE] $name"
    rm -rf "$dir"
    git clone "$url" "$dir"
  fi
  if (( OFFLINE == 0 )); then
    echo "[FETCH] $name"
    git -C "$dir" fetch --tags --prune origin
  fi
}

resolve_commit() {
  local name="$1" ref="$2" dir="$SRC_DIR/$name" candidate
  # Prefer a freshly fetched remote branch when available.
  if git -C "$dir" rev-parse --verify --quiet "origin/$ref^{commit}" >/dev/null; then
    candidate="origin/$ref"
  elif git -C "$dir" rev-parse --verify --quiet "$ref^{commit}" >/dev/null; then
    candidate="$ref"
  else
    echo "Unable to resolve Git ref '$ref' for $name." >&2
    exit 5
  fi
  git -C "$dir" rev-parse "$candidate^{commit}"
}

prepare_build_tree() {
  local name="$1" commit="$2" dir="$SRC_DIR/$name"
  git -C "$dir" checkout -f "$commit"
  git -C "$dir" clean -fdx
}

stamp_matches() {
  local name="$1" commit="$2" stamp="$STAMP_DIR/$name.commit"
  [[ -f "$stamp" ]] && [[ "$(<"$stamp")" == "$commit" ]]
}

write_stamp() {
  local name="$1" commit="$2"
  printf '%s\n' "$commit" > "$STAMP_DIR/$name.commit"
}

component_needs_build() {
  local name="$1" commit="$2" check_path="$3"
  if (( FORCE == 1 )); then
    echo "[BUILD] $name (--force)"
    return 0
  fi
  if [[ ! -e "$check_path" ]]; then
    echo "[BUILD] $name (install missing: $check_path)"
    return 0
  fi
  if ! stamp_matches "$name" "$commit"; then
    if [[ -f "$STAMP_DIR/$name.commit" ]]; then
      echo "[BUILD] $name (revision changed: $(<"$STAMP_DIR/$name.commit") -> $commit)"
    else
      echo "[BUILD] $name (no revision stamp; one-time rebuild/adoption)"
    fi
    return 0
  fi
  echo "[SKIP]  $name already installed at $commit"
  return 1
}

install_xschem() {
  ensure_repo xschem "$XSCHEM_URL"
  local commit
  commit="$(resolve_commit xschem "$XSCHEM_REF")"
  if component_needs_build xschem "$commit" "$PREFIX/bin/xschem"; then
    prepare_build_tree xschem "$commit"
    cd "$SRC_DIR/xschem"
    ./configure --prefix="$PREFIX"
    make -j"$JOBS"
    make install
    write_stamp xschem "$commit"
  fi
  XSCHEM_COMMIT="$commit"
}

install_magic() {
  ensure_repo magic "$MAGIC_URL"
  local commit
  commit="$(resolve_commit magic "$MAGIC_REF")"
  if component_needs_build magic "$commit" "$PREFIX/bin/magic"; then
    prepare_build_tree magic "$commit"
    cd "$SRC_DIR/magic"
    ./configure --prefix="$PREFIX"
    make -j"$JOBS"
    make install
    write_stamp magic "$commit"
  fi
  MAGIC_COMMIT="$commit"
}

install_netgen() {
  ensure_repo netgen "$NETGEN_URL"
  local commit
  commit="$(resolve_commit netgen "$NETGEN_REF")"
  if component_needs_build netgen "$commit" "$PREFIX/bin/netgen"; then
    prepare_build_tree netgen "$commit"
    cd "$SRC_DIR/netgen"
    ./configure --prefix="$PREFIX"
    make -j"$JOBS"
    make install
    write_stamp netgen "$commit"
  fi
  NETGEN_COMMIT="$commit"
}

install_ngspice() {
  ensure_repo ngspice "$NGSPICE_URL"
  local commit
  commit="$(resolve_commit ngspice "$NGSPICE_REF")"
  if component_needs_build ngspice "$commit" "$PREFIX/bin/ngspice"; then
    prepare_build_tree ngspice "$commit"
    cd "$SRC_DIR/ngspice"
    ./autogen.sh
    rm -rf release
    mkdir release
    cd release
    ../configure --prefix="$PREFIX" \
      --with-x --enable-xspice --disable-debug --enable-cider \
      --with-readline=yes --enable-openmp
    make -j"$JOBS"
    make install
    write_stamp ngspice "$commit"
  fi
  NGSPICE_COMMIT="$commit"
}

pdk_complete() {
  [[ -f "$PREFIX/share/pdk/sky130A/libs.tech/xschem/xschemrc" ]] &&
  [[ -f "$PREFIX/share/pdk/sky130A/libs.tech/magic/sky130A.magicrc" ]] &&
  [[ -f "$PREFIX/share/pdk/sky130A/libs.tech/ngspice/sky130.lib.spice" ]]
}

install_open_pdks() {
  ensure_repo open_pdks "$OPEN_PDKS_URL"
  local commit
  commit="$(resolve_commit open_pdks "$OPEN_PDKS_REF")"
  local check="$PREFIX/share/pdk/sky130A/libs.tech/ngspice/sky130.lib.spice"
  if (( FORCE == 1 )) || ! pdk_complete || ! stamp_matches open_pdks "$commit"; then
    if (( FORCE == 1 )); then
      echo "[BUILD] open_pdks/SKY130A (--force)"
    elif ! pdk_complete; then
      echo "[BUILD] open_pdks/SKY130A (PDK incomplete or missing)"
    elif [[ -f "$STAMP_DIR/open_pdks.commit" ]]; then
      echo "[BUILD] open_pdks/SKY130A (revision changed: $(<"$STAMP_DIR/open_pdks.commit") -> $commit)"
    else
      echo "[BUILD] open_pdks/SKY130A (no revision stamp; one-time rebuild/adoption)"
    fi
    prepare_build_tree open_pdks "$commit"
    cd "$SRC_DIR/open_pdks"
    ./configure --prefix="$PREFIX" --enable-sky130-pdk
    make -j"$JOBS"
    make install
    pdk_complete || { echo "SKY130A install finished but expected PDK files are missing." >&2; exit 6; }
    write_stamp open_pdks "$commit"
  else
    echo "[SKIP]  open_pdks/SKY130A already installed at $commit"
  fi
  OPEN_PDKS_COMMIT="$commit"
}

XSCHEM_COMMIT=""
MAGIC_COMMIT=""
NETGEN_COMMIT=""
NGSPICE_COMMIT=""
OPEN_PDKS_COMMIT=""

install_xschem
install_magic
install_netgen
install_ngspice
if (( NO_PDK == 0 )); then
  install_open_pdks
else
  echo "Skipping SKY130/Open_PDKs (--no-pdk)."
fi

# Add ngspice compatibility settings in a marked block. Existing content is
# preserved. The first pre-install copy is retained only as a reference backup;
# rollback removes the marked block instead of overwriting later user changes.
SPICEINIT="$HOME/.spiceinit"
if [[ -f "$SPICEINIT" && ! -f "$CONFIG_DIR/spiceinit.pre-vlsi-rc" ]]; then
  cp -a "$SPICEINIT" "$CONFIG_DIR/spiceinit.pre-vlsi-rc"
elif [[ ! -f "$SPICEINIT" ]]; then
  : > "$SPICEINIT"
  touch "$CONFIG_DIR/spiceinit.created-by-installer"
fi

python3 - "$SPICEINIT" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
text = p.read_text() if p.exists() else ""
start = "# BEGIN VLSI_RC_TOOLCHAIN"
end = "# END VLSI_RC_TOOLCHAIN"
block = f"{start}\nset ngbehavior=hsa\nset ng_nomodcheck\n{end}\n"
if start in text and end in text:
    before = text.split(start, 1)[0]
    after = text.split(end, 1)[1].lstrip("\n")
    text = before.rstrip() + "\n\n" + block + ("\n" + after if after else "")
else:
    text = text.rstrip() + ("\n\n" if text.strip() else "") + block
p.write_text(text)
PY

cat > "$CONFIG_DIR/env.sh" <<ENVFILE
# Activate the VLSI RC/SKY130 environment:
#   source "$CONFIG_DIR/env.sh"
export VLSI_RC_PREFIX="$PREFIX"
export PDK_ROOT="$PREFIX/share/pdk"
export PDK="sky130A"
export PATH="$PREFIX/bin:\$PATH"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/lib64/pkgconfig:\${PKG_CONFIG_PATH:-}"
ENVFILE

cat > "$PREFIX/bin/vlsi-xschem" <<'WRAPPER'
#!/usr/bin/env bash
set -e
PREFIX="${VLSI_RC_PREFIX:-$HOME/.local/vlsi-rc}"
PDK_ROOT="${PDK_ROOT:-$PREFIX/share/pdk}"
PDK="${PDK:-sky130A}"
RC="$PDK_ROOT/$PDK/libs.tech/xschem/xschemrc"
[[ -f "$RC" ]] || { echo "Missing xschemrc: $RC" >&2; exit 1; }
exec "$PREFIX/bin/xschem" --rcfile "$RC" "$@"
WRAPPER
chmod +x "$PREFIX/bin/vlsi-xschem"

cat > "$PREFIX/bin/vlsi-magic" <<'WRAPPER'
#!/usr/bin/env bash
set -e
PREFIX="${VLSI_RC_PREFIX:-$HOME/.local/vlsi-rc}"
PDK_ROOT="${PDK_ROOT:-$PREFIX/share/pdk}"
PDK="${PDK:-sky130A}"
RC="$PDK_ROOT/$PDK/libs.tech/magic/sky130A.magicrc"
[[ -f "$RC" ]] || { echo "Missing Magic rcfile: $RC" >&2; exit 1; }
exec "$PREFIX/bin/magic" -rcfile "$RC" "$@"
WRAPPER
chmod +x "$PREFIX/bin/vlsi-magic"

cat > "$PREFIX/bin/vlsi-rc-doctor" <<'DOCTOR'
#!/usr/bin/env bash
set -u
PREFIX="${VLSI_RC_PREFIX:-$HOME/.local/vlsi-rc}"
PDK_ROOT="${PDK_ROOT:-$PREFIX/share/pdk}"
PDK="${PDK:-sky130A}"
fail=0
check_exec() {
  if [[ -x "$PREFIX/bin/$1" ]]; then
    printf '[OK]   %-10s %s\n' "$1" "$PREFIX/bin/$1"
  else
    printf '[FAIL] %-10s missing: %s\n' "$1" "$PREFIX/bin/$1"
    fail=1
  fi
}
check_file() {
  if [[ -e "$1" ]]; then echo "[OK]   $1"; else echo "[FAIL] $1"; fail=1; fi
}
check_exec xschem
check_exec magic
check_exec netgen
check_exec ngspice
check_file "$PDK_ROOT/$PDK/libs.tech/xschem/xschemrc"
check_file "$PDK_ROOT/$PDK/libs.tech/magic/sky130A.magicrc"
check_file "$PDK_ROOT/$PDK/libs.tech/ngspice/sky130.lib.spice"
check_file "$HOME/.spiceinit"
if grep -q '^set ngbehavior=hsa$' "$HOME/.spiceinit" 2>/dev/null; then
  echo "[OK]   ngspice compatibility: hsa"
else
  echo "[WARN] ngbehavior=hsa not found in ~/.spiceinit"
fi
exit "$fail"
DOCTOR
chmod +x "$PREFIX/bin/vlsi-rc-doctor"

for f in vlsi-xschem vlsi-magic vlsi-rc-doctor; do
  ln -sfn "$PREFIX/bin/$f" "$LOCAL_BIN/$f"
done

# A shell-readable lock file that the team can commit. Pin these commits through
# the corresponding *_REF environment variables on other machines.
{
  echo "# Generated $(date -Iseconds)"
  echo "VLSI_PREFIX='$PREFIX'"
  echo "XSCHEM_COMMIT='$XSCHEM_COMMIT'"
  echo "MAGIC_COMMIT='$MAGIC_COMMIT'"
  echo "NETGEN_COMMIT='$NETGEN_COMMIT'"
  echo "NGSPICE_COMMIT='$NGSPICE_COMMIT'"
  if (( NO_PDK == 0 )); then
    echo "OPEN_PDKS_COMMIT='$OPEN_PDKS_COMMIT'"
  elif [[ -f "$STAMP_DIR/open_pdks.commit" ]]; then
    echo "OPEN_PDKS_COMMIT='$(<"$STAMP_DIR/open_pdks.commit")'"
  fi
} > "$CONFIG_DIR/toolchain.lock"

echo
echo "== Verification =="
# shellcheck disable=SC1090
source "$CONFIG_DIR/env.sh"
"$PREFIX/bin/vlsi-rc-doctor" || true

echo
echo "Installation/update complete."
echo "Activate:       source \"$CONFIG_DIR/env.sh\""
echo "Open schematic: vlsi-xschem your_file.sch"
echo "Open layout:    vlsi-magic"
echo "Lock file:      $CONFIG_DIR/toolchain.lock"
echo "Re-run normally to skip unchanged components; use --force to rebuild all."
