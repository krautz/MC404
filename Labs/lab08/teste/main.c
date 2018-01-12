#include "api_robot.h" /* Robot control API */

void delay();

/* main function */
void _start(void) 
{
  unsigned int distances[16];
  unsigned short sonar_3, sonar_4;

  set_speed_motors(25, 25);

  /* While not close to anything. */
	do {
		set_speed_motor(25,0);
		delay();
		read_sonars(distances);
                if ( ( distances[4] < 1200 ) || ( distances[3] < 1200 )) {
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
