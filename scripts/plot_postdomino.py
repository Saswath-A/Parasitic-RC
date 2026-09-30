from pathlib import Path

import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt


# ------------------------------------------------------------
# Paths
# ------------------------------------------------------------

ROOT = Path(__file__).resolve().parent.parent
DATA_FILE = ROOT / "data" / "domino_postlayout_waveforms.dat"
PLOT_DIR = ROOT / "plots"

PLOT_DIR.mkdir(exist_ok=True)


# ------------------------------------------------------------
# Constants
# ------------------------------------------------------------

VDD = 1.8
V50 = 0.9


# ------------------------------------------------------------
# Load data
# ------------------------------------------------------------

data = np.loadtxt(DATA_FILE, skiprows=1)

time = data[:, 0]
clk = data[:, 1]
a = data[:, 2]
b = data[:, 3]
x = data[:, 4]
out = data[:, 5]

t_ns = time * 1e9


# ------------------------------------------------------------
# Threshold-crossing helper
# ------------------------------------------------------------

def crossing_times(t, signal, threshold, direction):
    if direction == "rise":
        idx = np.where(
            (signal[:-1] < threshold) &
            (signal[1:] >= threshold)
        )[0]
    else:
        idx = np.where(
            (signal[:-1] > threshold) &
            (signal[1:] <= threshold)
        )[0]

    crossings = []

    for i in idx:
        t1, t2 = t[i], t[i + 1]
        y1, y2 = signal[i], signal[i + 1]

        frac = (threshold - y1) / (y2 - y1)
        tcross = t1 + frac * (t2 - t1)

        crossings.append(tcross)

    return np.array(crossings)


# ------------------------------------------------------------
# Timing measurements
# ------------------------------------------------------------

clk_rise = crossing_times(time, clk, V50, "rise")
x_fall = crossing_times(time, x, V50, "fall")
out_rise = crossing_times(time, out, V50, "rise")

clk_trigger = clk_rise[3]

x_cross = x_fall[x_fall > clk_trigger][0]
out_cross = out_rise[out_rise > clk_trigger][0]

tx_ps = (x_cross - clk_trigger) * 1e12
tpd_ps = (out_cross - clk_trigger) * 1e12


print(f"CLK -> X delay   : {tx_ps:.2f} ps")
print(f"CLK -> OUT delay : {tpd_ps:.2f} ps")


# ============================================================
# 1. INPUT WAVEFORMS
# ============================================================

plt.figure(figsize=(10, 4.5))

plt.plot(t_ns, clk, label="CLK", linewidth=1.6)
plt.plot(t_ns, a, label="A", linewidth=1.6)
plt.plot(t_ns, b, label="B", linewidth=1.6)

plt.xlabel("Time (ns)")
plt.ylabel("Voltage (V)")
plt.title("Post-Layout Input Waveforms")

plt.xlim(0, 32)
plt.ylim(-0.1, 2.0)

plt.grid(True, alpha=0.3)
plt.legend()

plt.tight_layout()

plt.savefig(
    PLOT_DIR / "postlayout_inputs.png",
    dpi=300
)

plt.savefig(
    PLOT_DIR / "postlayout_inputs.pdf"
)

plt.close()


# ============================================================
# 2. DYNAMIC NODE X
# ============================================================

plt.figure(figsize=(10, 4.5))

plt.plot(
    t_ns,
    x,
    label="X",
    linewidth=1.7
)

plt.axhline(
    V50,
    linestyle="--",
    linewidth=1.0,
    label="0.9 V threshold"
)

plt.xlabel("Time (ns)")
plt.ylabel("Voltage (V)")
plt.title("Post-Layout Dynamic Node Voltage")

plt.xlim(0, 32)
plt.ylim(-0.1, 2.1)

plt.grid(True, alpha=0.3)
plt.legend()

plt.tight_layout()

plt.savefig(
    PLOT_DIR / "postlayout_dynamic_node.png",
    dpi=300
)

plt.savefig(
    PLOT_DIR / "postlayout_dynamic_node.pdf"
)

plt.close()


# ============================================================
# 3. OUTPUT WAVEFORM
# ============================================================

plt.figure(figsize=(10, 4.5))

plt.plot(
    t_ns,
    out,
    label="OUT",
    linewidth=1.7
)

plt.axhline(
    V50,
    linestyle="--",
    linewidth=1.0,
    label="0.9 V threshold"
)

plt.xlabel("Time (ns)")
plt.ylabel("Voltage (V)")
plt.title("Post-Layout Output Voltage")

plt.xlim(0, 32)
plt.ylim(-0.1, 2.0)

plt.grid(True, alpha=0.3)
plt.legend()

plt.tight_layout()

plt.savefig(
    PLOT_DIR / "postlayout_output.png",
    dpi=300
)

plt.savefig(
    PLOT_DIR / "postlayout_output.pdf"
)

plt.close()


# ============================================================
# 4. TIMING ZOOM
# ============================================================

plt.figure(figsize=(10, 4.8))

plt.plot(
    t_ns,
    clk,
    label="CLK",
    linewidth=1.5
)

plt.plot(
    t_ns,
    x,
    label="X",
    linewidth=1.7
)

plt.plot(
    t_ns,
    out,
    label="OUT",
    linewidth=1.7
)

plt.axhline(
    V50,
    linestyle="--",
    linewidth=1.0,
    label="0.9 V threshold"
)

plt.axvline(
    clk_trigger * 1e9,
    linestyle=":",
    linewidth=1.0
)

plt.axvline(
    x_cross * 1e9,
    linestyle=":",
    linewidth=1.0
)

plt.axvline(
    out_cross * 1e9,
    linestyle=":",
    linewidth=1.0
)

plt.xlabel("Time (ns)")
plt.ylabel("Voltage (V)")

plt.title(
    f"Post-Layout Timing Response "
    f"(CLK→X = {tx_ps:.2f} ps, CLK→OUT = {tpd_ps:.2f} ps)"
)

plt.xlim(27.9, 28.2)
plt.ylim(-0.1, 2.0)

plt.grid(True, alpha=0.3)
plt.legend()

plt.tight_layout()

plt.savefig(
    PLOT_DIR / "postlayout_timing_zoom.png",
    dpi=300
)

plt.savefig(
    PLOT_DIR / "postlayout_timing_zoom.pdf"
)

plt.close()


print(f"Plots saved in: {PLOT_DIR}")
