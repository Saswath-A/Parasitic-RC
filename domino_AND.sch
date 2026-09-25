v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
N 360 -80 360 -40 {lab=OUT}
N 360 -160 360 -140 {lab=Vdd}
N 360 20 360 40 {lab=0}
N 250 -110 320 -110 {lab=X}
N 290 -110 320 -110 {lab=X}
N 290 -110 290 -10 {lab=X}
N 290 -10 320 -10 {lab=X}
N 360 -60 460 -60 {lab=OUT}
N 360 -110 430 -110 {lab=Vdd}
N 430 -150 430 -110 {lab=Vdd}
N 420 -150 430 -150 {lab=Vdd}
N 360 -150 420 -150 {lab=Vdd}
N 360 -10 430 -10 {lab=0}
N 430 -10 430 30 {lab=0}
N 360 30 430 30 {lab=0}
N 60 140 60 150 {lab=0}
N 60 150 60 160 {lab=0}
N 60 50 60 80 {lab=#net1}
N 60 -40 60 -10 {lab=#net2}
N 60 -180 60 -100 {lab=X}
N 60 -110 250 -110 {lab=X}
N 60 110 140 110 {lab=0}
N 60 150 140 150 {lab=0}
N 140 110 140 150 {lab=0}
N 60 20 140 20 {lab=0}
N 140 20 140 110 {lab=0}
N 140 -70 140 20 {lab=0}
N 60 -70 140 -70 {lab=0}
N 60 -260 60 -240 {lab=Vdd}
N 60 -210 130 -210 {lab=Vdd}
N 130 -250 130 -210 {lab=Vdd}
N 60 -250 130 -250 {lab=Vdd}
C {sky130_fd_pr/pfet_01v8.sym} 340 -110 0 0 {name=M1
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
C {sky130_fd_pr/nfet_01v8.sym} 340 -10 0 0 {name=M2
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
C {vsource.sym} -550 -110 0 0 {name=V2 value="PULSE(0 1.8 4n 50p 50p 4n 8n)" savecurrent=false
}
C {gnd.sym} 360 40 0 0 {name=l2 lab=0}
C {lab_pin.sym} 460 -60 0 0 {name=p1 sig_type=std_logic lab=OUT
}
C {code_shown.sym} -560 330 0 0 {name=MODEL only_toplevel=false value=".lib /usr/local/share/pdk/sky130A/libs.tech/ngspice/sky130.lib.spice tt"}
C {code_shown.sym} -570 -20 0 0 {name=NGSPICE only_toplevel=false value=".control
save all
tran 5p 32n

write domino_AND.raw

set wr_singlescale
set wr_vecnames
wrdata domino_waveforms.dat v(CLK) v(A) v(B) v(X) v(OUT)

plot v(CLK)
plot v(A) v(B)
plot v(X)
plot v(OUT)

.endc"}
C {vsource.sym} -250 -220 0 0 {name=V3 value=1.8 savecurrent=false}
C {gnd.sym} -250 -190 0 0 {name=l3 lab=0}
C {lab_pin.sym} -250 -250 0 0 {name=p3 sig_type=std_logic lab=Vdd

}
C {lab_pin.sym} 360 -160 0 0 {name=p4 sig_type=std_logic lab=Vdd

}
C {gnd.sym} -550 -80 0 0 {name=l1 lab=0}
C {sky130_fd_pr/pfet_01v8.sym} 40 -210 0 0 {name=M3
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
C {sky130_fd_pr/nfet_01v8.sym} 40 -70 0 0 {name=M4
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
model=nfet_01v8
spiceprefix=X
}
C {sky130_fd_pr/nfet_01v8.sym} 40 20 0 0 {name=M5
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
model=nfet_01v8
spiceprefix=X
}
C {sky130_fd_pr/nfet_01v8.sym} 40 110 0 0 {name=M6
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
model=nfet_01v8
spiceprefix=X
}
C {gnd.sym} 60 160 0 0 {name=l4 lab=0}
C {lab_pin.sym} 60 -260 0 0 {name=p2 sig_type=std_logic lab=Vdd

}
C {lab_pin.sym} -550 -140 0 0 {name=p5 sig_type=std_logic lab=CLK

}
C {lab_pin.sym} 20 -210 0 0 {name=p6 sig_type=std_logic lab=CLK

}
C {lab_pin.sym} 20 110 0 0 {name=p7 sig_type=std_logic lab=CLK

}
C {vsource.sym} -550 -340 0 0 {name=V1 value="PWL(0 0 8.5n 0 8.55n 1.8 16.5n 1.8 16.55n 0 24.5n 0 24.55n 1.8 32n 1.8)" savecurrent=false
}
C {gnd.sym} -550 -310 0 0 {name=l5 lab=0}
C {lab_pin.sym} -550 -370 0 0 {name=p8 sig_type=std_logic lab=B

}
C {vsource.sym} -550 -220 0 0 {name=V4 value="PWL(0 0 16.5n 0 16.55n 1.8 32n 1.8)" savecurrent=false
}
C {gnd.sym} -550 -190 0 0 {name=l6 lab=0}
C {lab_pin.sym} -550 -250 0 0 {name=p9 sig_type=std_logic lab=A

}
C {lab_pin.sym} 20 -70 0 0 {name=p10 sig_type=std_logic lab=A

}
C {lab_pin.sym} 20 20 0 0 {name=p11 sig_type=std_logic lab=B

}
C {lab_pin.sym} 190 -110 0 0 {name=p12 sig_type=std_logic lab=X
}
