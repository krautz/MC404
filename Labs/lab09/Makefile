ra165457.o: ra165457.s
	arm-eabi-as -g ra165457.s -o ra165457.o
	
ra165457: ra165457.o
	arm-eabi-ld ra165457.o -o ra165457 -g --section-start=.iv=0x778005e0 -Ttext=0x77800700 -Tdata=0x77801800 -e 0x778005e0
	
disk.img: ra165457
	mksd.sh --so ra165457 --user faz_nada

SIM: disk.img
	arm-sim --rom=/home/specg12-1/mc404/simulador/simulador_player/bin/dumboot.bin --sd=disk.img -g
