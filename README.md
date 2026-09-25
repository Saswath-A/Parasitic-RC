# Interconnect RC Parasitic Extraction and Its Post-Layout Impact on Dynamic Logic Path Delay

## Project Objective

This project studies the effect of physical interconnect resistance and capacitance on the propagation delay of a dynamic CMOS logic path.

The circuit is implemented using a 2-input domino AND gate using the SKY130A open-source PDK.

The complete flow is:

Schematic Design
→ Pre-Layout Simulation
→ Physical Layout
→ DRC
→ RC Parasitic Extraction
→ Post-Layout Simulation
→ Delay Comparison

---

## Technology

- PDK: SKY130A
- Supply voltage: 1.8 V
- Process corner: TT
- Schematic tool: xschem
- Simulation tool: ngspice
- Layout tool: Magic VLSI
- Parasitic extraction: Magic
- Plotting: MATLAB

---

## Transistor Dimensions

### Domino stage

| Device | Type | W | L |
|---|---|---:|---:|
| Mpre | PMOS | 2 µm | 0.15 µm |
| MA | NMOS | 2 µm | 0.15 µm |
| MB | NMOS | 2 µm | 0.15 µm |
| Meval | NMOS | 2 µm | 0.15 µm |

### Output inverter

| Device | Type | W | L |
|---|---|---:|---:|
| PMOS | PMOS | 2 µm | 0.15 µm |
| NMOS | NMOS | 1 µm | 0.15 µm |

---

## Domino AND Operation

During precharge:

CLK = 0

The dynamic node X is charged toward VDD.

During evaluation:

CLK = 1

The dynamic node discharges only when:

A = 1
B = 1

Therefore the static inverter output implements:

OUT = A AND B

Expected evaluation truth table:

| A | B | OUT |
|---|---|---|
| 0 | 0 | 0 |
| 0 | 1 | 0 |
| 1 | 0 | 0 |
| 1 | 1 | 1 |

---

# Team Responsibilities

## Member 1 — Dynamic Logic Design

Responsibilities:

- CMOS inverter verification
- Domino AND schematic
- Device sizing
- Clock and input stimulus
- Truth-table verification
- Dynamic-node analysis
- Pre-layout waveform generation

Deliverables:

- `inverter_test.sch`
- `domino_AND.sch`
- `data/domino_waveforms.dat`
- `plots/`
- MATLAB plotting scripts

Status: Completed / verification stage.

---

## Member 2 — Pre-Layout Timing Analysis

Responsibilities:

- Measure CLK-to-X delay
- Measure CLK-to-OUT propagation delay
- Measure rise/fall times
- Record baseline pre-layout timing
- Produce timing tables

Main output:

tpd_pre

This becomes the baseline for the post-layout comparison.

---

## Member 3 — Physical Layout and DRC

Tool:

Magic VLSI + SKY130A

Responsibilities:

- Implement transistor-level layout
- Connect VDD and GND rails
- Route CLK, A, B, X and OUT
- Create interconnect under study
- Run DRC
- Correct all layout violations

Deliverables:

- `.mag` layout
- DRC-clean screenshots
- layout dimensions

---

## Member 4 — RC Extraction and Post-Layout Simulation

Responsibilities:

- Extract the layout
- Generate parasitic SPICE netlist
- Determine interconnect resistance
- Determine interconnect capacitance
- Run post-layout ngspice simulation
- Measure post-layout delay

Main output:

tpd_post

---

## Member 5 — Analysis and Documentation

Responsibilities:

- Compare pre-layout and post-layout results
- Analyze parasitic RC
- Apply RC/Elmore delay theory
- Generate comparison graphs
- Assemble final report and presentation

Percentage delay increase:

Delay Increase (%) =
((tpd_post - tpd_pre) / tpd_pre) × 100

---

# Repository Structure

```text
.
├── domino_AND.sch
├── inverter_test.sch
├── data/
├── plots/
├── scripts/
├── docs/
├── vlsi_rc_toolchain/
└── README.md

---

## Tool Installation

For installation, setup, supported Linux distributions, environment configuration, and rollback instructions, see:

[`vlsi_rc_toolchain/README.md`](vlsi_rc_toolchain/README.md)
