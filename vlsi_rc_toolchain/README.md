# VLSI RC / SKY130 team toolchain — v2

This bundle is for the assignment **Interconnect RC Parasitic Extraction and Its Post-Layout Impact on Dynamic Logic Path Delay**.

It installs a consistent open-source flow:

- **Xschem** — transistor-level schematic entry
- **ngspice** — pre-layout and post-layout transient simulation
- **Magic** — SKY130 layout, DRC, and parasitic extraction
- **Netgen** — LVS support
- **Open_PDKs / SKY130A** — device models, xschem symbols, Magic technology files, and extraction setup

## What changed in v2

The installer is now **idempotent**. Re-running it does not blindly rebuild everything.

Normal behavior:

```text
[SKIP]  xschem already installed at <same commit>
[SKIP]  magic already installed at <same commit>
[BUILD] ngspice (revision changed: old -> new)
[SKIP]  open_pdks/SKY130A already installed at <same commit>
```

A component is rebuilt only when:

1. it is missing,
2. its requested Git commit changed,
3. its revision stamp is missing (one-time rebuild/adoption after upgrading from v1), or
4. you run with `--force`.

The installer still fetches Git metadata on a normal online run so it can determine what `master` or another moving ref currently points to. Use `--offline` to avoid network access and work from the already-cloned source trees.

## Supported systems

The package installer supports these families:

- Debian / Ubuntu / Linux Mint / **WSL2 Ubuntu** (`apt`)
- Arch / EndeavourOS / Manjaro (`pacman`)
- Fedora / Rocky / Alma / RHEL-family (`dnf`)
- openSUSE Leap / Tumbleweed (`zypper`)

For native Windows teammates, use **WSL2 Ubuntu** for the full Xschem + Magic + SKY130 flow.

## Install / update

```bash
chmod +x install_vlsi_rc.sh rollback_vlsi_rc.sh
./install_vlsi_rc.sh
```

On the first run this may take considerable time and disk space, especially Open_PDKs/SKY130A. On later runs, unchanged components are skipped.

### Force a full rebuild

```bash
./install_vlsi_rc.sh --force
```

### Install tools without the PDK

Useful for a teammate who only needs some schematic/simulation tooling:

```bash
./install_vlsi_rc.sh --no-pdk
```

### Skip distro package installation

```bash
./install_vlsi_rc.sh --no-packages
```

Use this only when the required build dependencies are already present.

### Offline rerun

```bash
./install_vlsi_rc.sh --offline
```

All source checkouts and requested refs/commits must already exist locally.

## Install locations

Everything source-built by this bundle lives under:

```text
~/.local/vlsi-rc
```

Source/build trees are kept under:

```text
~/.cache/vlsi-rc-src
```

State, logs, stamps, environment configuration, and the lock file are under:

```text
~/.config/vlsi-rc
```

SKY130A becomes:

```text
~/.local/vlsi-rc/share/pdk/sky130A
```

This user-local layout keeps the coursework toolchain separate from `/usr` and `/usr/local`.

## Activate and verify

```bash
source ~/.config/vlsi-rc/env.sh
vlsi-rc-doctor
```

Open an xschem project with the correct SKY130 rcfile:

```bash
vlsi-xschem domino_AND.sch
```

Open Magic with the SKY130A technology setup:

```bash
vlsi-magic
```

## ngspice compatibility

The installer adds only this marked block to `~/.spiceinit`:

```text
# BEGIN VLSI_RC_TOOLCHAIN
set ngbehavior=hsa
set ng_nomodcheck
# END VLSI_RC_TOOLCHAIN
```

Existing `.spiceinit` content is preserved. Rollback removes only this marked block, so later user edits are not overwritten.

## Reproducibility for the five-member team

After the first successful installation, copy:

```text
~/.config/vlsi-rc/toolchain.lock
```

into the team Git repository. It records the exact commits that were resolved for each component.

To make another teammate use exactly those revisions, set the refs to the commits from the lock file, for example:

```bash
XSCHEM_REF=<xschem-commit> \
MAGIC_REF=<magic-commit> \
NETGEN_REF=<netgen-commit> \
NGSPICE_REF=<ngspice-commit> \
OPEN_PDKS_REF=<open-pdks-commit> \
./install_vlsi_rc.sh
```

Because v2 compares the resolved commit against local stamps, rerunning that command later will skip every component already at the correct revision.

## Rollback

```bash
./rollback_vlsi_rc.sh
```

This removes the user-local VLSI toolchain, its state/config, launcher symlinks, source trees, and only the marked ngspice block.

Keep the source trees if you may reinstall later:

```bash
./rollback_vlsi_rc.sh --keep-sources
```

The rollback checks for an ownership marker before deleting the install prefix. This protects against accidentally deleting an unrelated directory. `--force` bypasses that check and should be used only when you know the configured prefix is disposable.

### Why rollback does not uninstall distro packages

The installer requests general packages such as compilers, Tcl/Tk, X11 libraries, Cairo, Python, and build tools. Those packages may have existed before this project or may be used by other software. Automatically removing them would not be a safe rollback. The project-owned source-built toolchain itself is removed cleanly.

## Useful SKY130 model line

With this user-local installation, the PDK root is exported as `$PDK_ROOT`. For a generated/portable SPICE netlist you can resolve the path from the environment. In xschem `code_shown.sym`, if environment-variable expansion is not behaving as desired, use the resolved absolute path from:

```bash
echo "$PDK_ROOT/sky130A/libs.tech/ngspice/sky130.lib.spice"
```

## Suggested project structure

```text
parasitic-rc/
├── README.md
├── schematics/
│   ├── inverter_working.sch
│   └── domino_AND.sch
├── layout/
├── spice/
├── results/
├── report/
└── toolchain.lock
```
