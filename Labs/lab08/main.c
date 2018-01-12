#include "api_robot.h" /* Robot control API */

void delay();

/* main function */
void _start(void) 
{
  unsigned int distances[16];
  unsigned short sonar_3, sonar_4;

  set_speed_motors(15, 15);

  /* While not close to anything. */
	do {
		set_speed_motor(15,0);
		delay();
		sonar_3 = read_sonar (3);
        sonar_4 = read_sonar (4);
                if (sonar_3 < 1200 || sonar_4 < 1200)  {
                    set_speed_motor (0, 0);
                    sonar_4 = 0;
                    while (sonar_3 < 1200 || sonar_4 < 1200) {
                        delay();
                        sonar_3 = read_sonar (3);
                        sonar_4 = read_sonar (4);
                    }
                }
	} while (1);
}

/* Spend some time doing nothing. */
void delay()
{
  int i;
  /* Not the best way to delay */
  for(i = 0; i < 10000; i++ );  
}

/* A funcao read_sonars demora muito paara ler todos sonares!(o que acaba resultando em o robo artavessar paredes para velocidades
	um pouco altas (acima de 10) pois nao conseguiu finalizar a leitura dos radares antes de atinir uma parede). 
	Entao eu optei apenas por ler os sonares 3 e 4, porem minha funcao read_sonars esta funcionando e foi testada!
*/
