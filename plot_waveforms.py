import numpy as np
import matplotlib.pyplot as plt

# Read simulation data
data = np.loadtxt("domino_waveforms.dat", skiprows=1)

time = data[:, 0] * 1e9   # seconds -> ns
clk  = data[:, 1]
a    = data[:, 2]
b    = data[:, 3]
x    = data[:, 4]
out  = data[:, 5]

# Create output directory
import os
os.makedirs("plots", exist_ok=True)

# Plot
plt.figure(figsize=(10, 6))

plt.plot(time, clk, label="CLK", linewidth=1.5)
plt.plot(time, x, label="X (Dynamic Node)", linewidth=1.5)
plt.plot(time, out, label="OUT", linewidth=1.5)

plt.xlabel("Time (ns)")
plt.ylabel("Voltage (V)")
plt.title("Domino AND — Pre-Layout Transient Response")

plt.ylim(-0.2, 2.0)
plt.grid(True, alpha=0.3)
plt.legend()

plt.tight_layout()

plt.savefig("plots/prelayout_waveforms.png", dpi=300)
plt.show()

# Zoomed CLK-to-OUT delay plot
plt.figure(figsize=(10, 6))

plt.plot(time, clk, label="CLK", linewidth=2)
plt.plot(time, out, label="OUT", linewidth=2)

# 50% voltage level
plt.axhline(0.9, linestyle="--", linewidth=1)

# Trigger and target times
t_clk = 4.025
t_out = 28.075

plt.axvline(t_clk, linestyle="--", linewidth=1)
plt.axvline(t_out, linestyle="--", linewidth=1)

# Delay annotation
plt.annotate(
    "CLK → OUT = 24.0503 ns",
    xy=((t_clk + t_out) / 2, 0.9),
    xytext=(12, 1.3),
    arrowprops=dict(arrowstyle="<->"),
    ha="center"
)

plt.xlabel("Time (ns)")
plt.ylabel("Voltage (V)")
plt.title("Domino AND — CLK-to-OUT Propagation Delay")
plt.ylim(-0.1, 2.0)
plt.xlim(2, 30)
plt.grid(True, alpha=0.3)
plt.legend()

plt.tight_layout()
plt.savefig("plots/clk_to_out_delay.png", dpi=300)
plt.show()
