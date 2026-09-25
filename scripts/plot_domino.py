import matplotlib
matplotlib.use("Agg")

import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path

# ------------------------------------------------------------
# Project paths
# ------------------------------------------------------------

PROJECT_DIR = Path(__file__).resolve().parent.parent
DATA_FILE = PROJECT_DIR / "data" / "domino_waveforms.dat"
PLOT_DIR = PROJECT_DIR / "plots"

PLOT_DIR.mkdir(parents=True, exist_ok=True)

# ------------------------------------------------------------
# Load ngspice wrdata output
# Expected columns:
# time, CLK, A, B, X, OUT
# ------------------------------------------------------------

data = np.loadtxt(DATA_FILE, skiprows=1)

time_ns = data[:, 0] * 1e9
clk = data[:, 1]
a = data[:, 2]
b = data[:, 3]
x = data[:, 4]
out = data[:, 5]

# ------------------------------------------------------------
# Professional stacked timing plot
# ------------------------------------------------------------

fig, axes = plt.subplots(
    5,
    1,
    figsize=(11, 8),
    sharex=True,
)

signals = [
    ("CLK", clk),
    ("A", a),
    ("B", b),
    ("Dynamic node X", x),
    ("OUT", out),
]

evaluation_edges = [4, 12, 20, 28]

for ax, (name, signal) in zip(axes, signals):

    ax.plot(time_ns, signal, linewidth=1.6)

    ax.set_ylabel(f"{name}\n(V)")
    ax.set_ylim(-0.15, 2.15)
    ax.grid(True, alpha=0.3)

    for edge in evaluation_edges:
        ax.axvline(edge, linestyle="--", linewidth=0.8, alpha=0.7)

axes[-1].set_xlabel("Time (ns)")
axes[-1].set_xlim(0, 32)

# Truth-table labels
axes[0].text(
    6, 2.0, "A B = 0 0",
    horizontalalignment="center",
    fontsize=9,
    fontweight="bold",
)

axes[0].text(
    14, 2.0, "A B = 0 1",
    horizontalalignment="center",
    fontsize=9,
    fontweight="bold",
)

axes[0].text(
    22, 2.0, "A B = 1 0",
    horizontalalignment="center",
    fontsize=9,
    fontweight="bold",
)

axes[0].text(
    30, 2.0, "A B = 1 1",
    horizontalalignment="center",
    fontsize=9,
    fontweight="bold",
)

fig.suptitle(
    "Pre-Layout Transient Response of 2-Input Domino AND Gate\n"
    "SKY130A, VDD = 1.8 V, TT Process Corner",
    fontsize=14,
    fontweight="bold",
)

fig.tight_layout(rect=[0, 0, 1, 0.94])

fig.savefig(
    PLOT_DIR / "domino_timing.png",
    dpi=600,
    bbox_inches="tight",
)

fig.savefig(
    PLOT_DIR / "domino_timing.pdf",
    bbox_inches="tight",
)

fig.savefig(
    PLOT_DIR / "domino_timing.svg",
    bbox_inches="tight",
)

plt.close(fig)

# ------------------------------------------------------------
# Dynamic-node focused plot
# ------------------------------------------------------------

fig, ax = plt.subplots(figsize=(11, 5))

ax.plot(
    time_ns,
    x,
    linewidth=1.6,
    label="Dynamic node X",
)

ax.plot(
    time_ns,
    out,
    linewidth=1.6,
    label="OUT",
)

ax.axhline(
    1.8,
    linestyle="--",
    linewidth=1,
    label="VDD = 1.8 V",
)

for edge in evaluation_edges:
    ax.axvline(
        edge,
        linestyle="--",
        linewidth=0.8,
        alpha=0.7,
    )

ax.set_xlabel("Time (ns)")
ax.set_ylabel("Voltage (V)")
ax.set_xlim(0, 32)
ax.set_ylim(-0.15, 2.15)

ax.set_title(
    "Dynamic Node and Output Response of Domino AND Gate"
)

ax.grid(True, alpha=0.3)
ax.legend()

fig.tight_layout()

fig.savefig(
    PLOT_DIR / "dynamic_node_response.png",
    dpi=600,
    bbox_inches="tight",
)

fig.savefig(
    PLOT_DIR / "dynamic_node_response.pdf",
    bbox_inches="tight",
)

fig.savefig(
    PLOT_DIR / "dynamic_node_response.svg",
    bbox_inches="tight",
)

plt.close(fig)

print("Generated:")
print(" plots/domino_timing.png")
print(" plots/domino_timing.pdf")
print(" plots/domino_timing.svg")
print(" plots/dynamic_node_response.png")
print(" plots/dynamic_node_response.pdf")
print(" plots/dynamic_node_response.svg")
