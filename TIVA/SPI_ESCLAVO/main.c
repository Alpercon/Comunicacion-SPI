#include "tm4c1294ncpdt.h"
#include <stdint.h>

//SPI Esclavo (modulo 0)

uint8_t datoRx = 0;
uint32_t cont;

void configurarLeds(); //funcion que configura LEDs de la TIVA
void configurarInt(); //funcion que configura la interrupcion para el SPI
void manejadorInt(); //Manejador de la interrupcion al recibir dato


void main(void){

    configurarLeds();

    //Se activa el modulo 0 de SSI
    SYSCTL_RCGCSSI_R |= 0x01;

    //Se va a usar el puerto A para la comunicacion SPI modulo 0, se le da reloj
    SYSCTL_RCGCGPIO_R |= 0x01;

    //Se espera a que el puerto este listo
    while((SYSCTL_PRGPIO_R & 0x01) == 0 ){}

    //Habilitar la función alterna en pines 2,3,4 y 5 del puerto
    GPIO_PORTA_AHB_AFSEL_R |= 0x3C;

    //Se asigna el puerto al controlador SPI
    GPIO_PORTA_AHB_PCTL_R |= 0x00FFFF00;

    //Se habilitan los pines asociados del puerto A
    GPIO_PORTA_AHB_DEN_R |= 0x3C;

    //Configuración como ESCLAVO
    SSI0_CR1_R |= 0x04;

    //La siguiente configuración genera un 'bit rate' para 1 MHz
    SSI0_CPSR_R |= 0x08;//16

    /*
     * Formato 'Freescale SPI'
     * Se define polaridad y fase del reloj
     * 8 bits de trama
     */
    SSI0_CR0_R |= 0x0107;


    //Se habilitan los modulos
    SSI0_CR1_R |= 0x02;

    //llenar fifo del esclavo
    for(cont = 48; cont <= 55; cont++){

        SSI0_DR_R = cont;
    }

    //configurarInt();



    while(1){

        while(!(SSI0_SR_R & 0x04)){} //Esperamos hasta recibir dato
        datoRx = SSI0_DR_R;

        switch(datoRx){

            case 0x00://Apaga todos los LEDs
                GPIO_PORTN_DATA_R = 0x00;
                GPIO_PORTF_AHB_DATA_R = 0x00;
            break;

            case 0x01: //Enciende D4
                GPIO_PORTN_DATA_R = 0x00;
                GPIO_PORTF_AHB_DATA_R = 0x01;
            break;

            case 0x02://Enciende D3
                GPIO_PORTN_DATA_R = 0x00;
                GPIO_PORTF_AHB_DATA_R = 0x10;
            break;

            case 0x04://Enciende D2
                GPIO_PORTN_DATA_R = 0x01;
                GPIO_PORTF_AHB_DATA_R = 0x00;
            break;

            case 0x08://Enciende D1
                GPIO_PORTN_DATA_R = 0x02;
                GPIO_PORTF_AHB_DATA_R = 0x00;
            break;

            case 0x0F: //Secuencia de LEDs
                GPIO_PORTN_DATA_R = 0x00;
                GPIO_PORTF_AHB_DATA_R = 0x00;
                for(cont = 0; cont <50000; cont++){}

                //Encender D4
                GPIO_PORTN_DATA_R = 0x00;
                GPIO_PORTF_AHB_DATA_R = 0x01;
                for(cont = 0; cont <50000; cont++){}

                //Encender D3
                GPIO_PORTN_DATA_R = 0x00;
                GPIO_PORTF_AHB_DATA_R = 0x10;
                for(cont = 0; cont <50000; cont++){}

                //Encender D2
                GPIO_PORTN_DATA_R = 0x01;
                GPIO_PORTF_AHB_DATA_R = 0x00;
                for(cont = 0; cont <50000; cont++){}

                //Encender D1
                GPIO_PORTN_DATA_R = 0x02;
                GPIO_PORTF_AHB_DATA_R = 0x00;
                for(cont = 0; cont <50000; cont++){}

            break;

            case 0xFF: //Secuencia de LEDs
                GPIO_PORTN_DATA_R = 0x00;
                GPIO_PORTF_AHB_DATA_R = 0x00;
                for(cont = 0; cont <50000; cont++){}

                //Encender D1
                GPIO_PORTN_DATA_R = 0x02;
                GPIO_PORTF_AHB_DATA_R = 0x00;
                for(cont = 0; cont <50000; cont++){}

                //Encender D2
                GPIO_PORTN_DATA_R = 0x01;
                GPIO_PORTF_AHB_DATA_R = 0x00;
                for(cont = 0; cont <50000; cont++){}

                //Encender D3
                GPIO_PORTN_DATA_R = 0x00;
                GPIO_PORTF_AHB_DATA_R = 0x10;
                for(cont = 0; cont <50000; cont++){}

                //Encender D4
                GPIO_PORTN_DATA_R = 0x00;
                GPIO_PORTF_AHB_DATA_R = 0x01;
                for(cont = 0; cont <50000; cont++){}
            break;

            default:// Por defecto enciende todos los LEDs
                GPIO_PORTN_DATA_R = 0x03;
                GPIO_PORTF_AHB_DATA_R = 0x11;
            break;

        }


    }





}


void configurarLeds(){
    //Funcion que configura los LEDS de la TIVA
    //se le da reloj al puerto N y F
    SYSCTL_RCGCGPIO_R = SYSCTL_RCGCGPIO_R12 | SYSCTL_RCGCGPIO_R5;
    cont = 0;

    //Programacion puerto N
    GPIO_PORTN_DEN_R = 0x03; //Se habilita el bit 1 y 2 (LED 1 y 2)
    GPIO_PORTN_DIR_R = 0x03; //PIN como salida

    //Programacion puerto F
    GPIO_PORTF_AHB_DEN_R = 0x11; //Se habilita el bit 4 y 0 (LED 3 y 4)
    GPIO_PORTF_AHB_DIR_R = 0x11; //PIN como salida

    //Encender todos los LEDs
    GPIO_PORTN_DATA_R = 0x03;
    GPIO_PORTF_AHB_DATA_R = 0x11;
}

void configurarInt(){

    //7 0x0000.005C SSI0
    //Se activa interrupcion para dato recibido (RXIM)
    SSI0_IM_R |= 0x04;
    //Se habilita la interrupcion
    NVIC_EN0_R |= 0x80;

}

void manejadorInt(){
    //al recibir dato se guarda
    datoRx = SSI0_DR_R;
}


