#include "api_robot2.h"

#define SYSTEM_UNITY_TIME 8000

int k, time, i, system_unity_time = 10000;

motor_cfg_t motor0, motor1;

void roda_direita();
void alarm();
void roda_90_graus();
void inicializa_motor();
void restaura_velocidae();

void _start () {
	
	inicializa_motor();
	
	//register_proximity_callback(3, 1200, roda_direita);
	//caso a register esteja descomentada o programa nao funciona corretamente...
	
	while(1) {
		for (i = 1; i <= 50; i++) {
			restaura_velocidade();
			alarm ();
		}
	}
	
}

void roda_direita() {
	int j;
	motor0.speed = 5;
	motor1.speed = 0;
	for (j = 0; j < 6000000; j++);
	set_motors_speed (&motor0, &motor1);	
}

void alarm () {
	set_time(0);
	add_alarm(roda_90_graus, i*system_unity_time);
	k = 1;
	while (k);	
}

void roda_90_graus() {
	int j;
	k = 0;
	motor0.speed = 30;
	motor1.speed = 0;
	set_motors_speed (&motor0, &motor1);
	for (j = 0; j < 1000000; j++);
}

void restaura_velocidade() {
	motor0.speed = 25;
	motor1.speed = 25;
	set_motors_speed (&motor0, &motor1);
}

void inicializa_motor() {
	motor0.id = 0;
	motor1.id = 1;
	motor0.speed = 25;
	motor1.speed = 25;
	set_motors_speed (&motor0, &motor1);
}
