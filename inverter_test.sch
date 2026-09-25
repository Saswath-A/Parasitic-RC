v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
N 50 -20 50 20 {lab=OUT}
N 50 -190 50 -160 {lab=0}
N 50 -100 50 -80 {lab=#net1}
N 50 80 50 100 {lab=0}
N -60 30 -60 80 {lab=0}
N -60 80 50 80 {lab=0}
N -60 -50 -60 -30 {lab=Vin}
N -60 -50 10 -50 {lab=Vin}
N -20 -50 10 -50 {lab=Vin}
N -20 -50 -20 50 {lab=Vin}
N -20 50 10 50 {lab=Vin}
N 50 -0 150 -0 {lab=OUT}
N 50 -50 120 -50 {lab=#net1}
N 120 -90 120 -50 {lab=#net1}
N 110 -90 120 -90 {lab=#net1}
N 50 -90 110 -90 {lab=#net1}
N 50 50 120 50 {lab=0}
N 120 50 120 90 {lab=0}
N 50 90 120 90 {lab=0}
C {sky130_fd_pr/pfet_01v8.sym} 30 -50 0 0 {name=M1
W=2
L=0.15
nf=1
mult=1
ad="expr('int((@nf + 1)/2) * @W / @nf * 0.29')"
pd="expr('2*int((@nf + 1)/2) * (@W / @nf + 0.29)')"
as="expr('int((@nf + 2)/2) * @W / @nf * 0.29')"
ps="expr('2*int((@nf + 2)/2) * (@W / @nf + 0.29)')"
nrd="expr('0.29 / @W ')" nrs="expr('0.29 / @W ')"
sa=0 sb=0 sd=0
model=pfet_01v8
spiceprefix=X
}
C {sky130_fd_pr/nfet_01v8.sym} 30 50 0 0 {name=M2
W=1
L=0.15
nf=1 
mult=1
ad="expr('int((@nf + 1)/2) * @W / @nf * 0.29')"
pd="expr('2*int((@nf + 1)/2) * (@W / @nf + 0.29)')"
as="expr('int((@nf + 2)/2) * @W / @nf * 0.29')"
ps="expr('2*int((@nf + 2)/2) * (@W / @nf + 0.29)')"
nrd="expr('0.29 / @W ')" nrs="expr('0.29 / @W ')"
sa=0 sb=0 sd=0
model=nfet_01v8
spiceprefix=X
}
C {vsource.sym} 50 -130 2 0 {name=V1 value=1.8 savecurrent=false}
C {vsource.sym} -60 0 0 0 {name=V2 value="PULSE(0 1.8 0 50p 50p 2n 4n)" savecurrent=false
}
C {gnd.sym} 50 -190 2 0 {name=l1 lab=0}
C {gnd.sym} 50 100 0 0 {name=l2 lab=0}
C {lab_pin.sym} 150 0 0 0 {name=p1 sig_type=std_logic lab=OUT
}
C {lab_pin.sym} -60 -50 0 0 {name=p2 sig_type=std_logic lab=Vin
}
C {code_shown.sym} -480 180 0 0 {name=MODEL only_toplevel=false value=".lib /usr/local/share/pdk/sky130A/libs.tech/ngspice/sky130.lib.spice tt"}
C {code_shown.sym} -430 20 0 0 {name=NGSPICE only_toplevel=false value=".control
save all
tran 5p 20n
plot v(Vin) v(OUT)
.endc"}
