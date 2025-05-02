//exemple d'utilisation de la fonction de temporisation

#include "includes/base_seac.h"

int main(void){
    printJ("attend 1 seconde\r");
    delay(1000);
    printJ("attend 10 seconde\r");
    delay(10000);
    printJ("finis!\r");

}
