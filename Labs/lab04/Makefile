inicio:
	source /home/specg12-1/mc404/simulador/set_path.sh

ra165457.o: ra165457.s
	arm-eabi-as ra165457.s -o ra165457.o
    
ra165457: ra165457.o
	arm-eabi-ld ra165457.o -o ra165457 -Ttext=0x77802000 -Tdata=0x77802050
    
SD: ra165457
	mksd.sh --so /home/specg12-1/mc404/simulador/dummyos.elf --user ra165457
    
SIM: disk.img
	arm-sim --rom=/home/specg12-1/mc404/simulador/dumboot.bin --sd=disk.img
	
SIMOUT:	
	(arm-sim --rom=/home/specg12-1/mc404/simulador/dumboot.bin --sd=disk.img 2>&1) > ra165457.out
    
