#include "api_robot2.h" /* Robot control API */

#define DISTANCE 1100
#define MIN_DISTANCE 900
#define MAX_DISTANCE 1200
#define GIG_DISTANCE 1600

void delay();
void little_delay ();
void inicializa_motor();
void roda_esquerda ();
void roda_direita ();
void restaura_velocidade ();

motor_cfg_t motor0, motor1;
int i, j;

/* main function */
void _start(void) {
	int sonar_3 = 5000, sonar_0 = 1200;
	
	inicializa_motor ();
	restaura_velocidade ();
	
	
	i = 1;
	while (i) {
		sonar_3 = read_sonar(3);
		if (sonar_3 <= DISTANCE) {
			roda_direita();
			for (j = 0; j < 2000000; j++);
			i = 0;
		}
	}
	
	i = 1;
	restaura_velocidade();
	while (i) {
		restaura_velocidade();
		sonar_0 = read_sonar(0);
		sonar_3 = read_sonar(3);
	
	
			if (sonar_0 >= GIG_DISTANCE) {
				roda_esquerda();
				delay();
				restaura_velocidade();
				delay();
			}
			if (sonar_3 <= MIN_DISTANCE) {
			roda_direita();
			for (j = 0; j < 2000000; j++);
			i = 0;
		}			

		
		
	}
	
	while (1) {
		delay();
	}
	
}

void inicializa_motor () {
	motor0.id = 0;
	motor0.speed = 15;
	motor1.id = 1;
	motor1.speed = 15;
}

void roda_esquerda () {
	motor0.speed = 5;
	motor1.speed = 0;
	set_motors_speed(&motor0, &motor1);
}

void roda_direita () {
	motor0.speed = 0;
	motor1.speed = 5;
	set_motors_speed(&motor0, &motor1);
}

void restaura_velocidade () {
	motor0.speed = 15;
	motor1.speed = 15;
	set_motors_speed(&motor0, &motor1);
}

void delay () {
	int i;
	for (i = 0; i < 6000000; i++); // AJUSTAR O TEMPO PRA ELE GIRAR EXATOS 90 GRAUS
}

void little_delay () {
	int i;
	for (i = 0; i < 300000; i++);
}
