//exemple d'ecriture dans le journal avec en plus un petit peu de couleur

#include "base_seac.h"

char temporaire[2];

int main(void){
    printJ("Hello, World!\r");

    for (char i = 0x10;i < 0x20;i++){
        temporaire[0]=i;
        printJ(temporaire);
        printJ("pouic!\r");
    }
    temporaire[0]=0x17;
    printJ(temporaire);
}
