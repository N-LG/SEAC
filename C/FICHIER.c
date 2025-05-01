//créer un fichier avec le nom en argument
//puis écrit un ptit truc dedans

#include "includes/base_seac.h"


char nom_fichier[256];

int main(void){
    arg_num(0,nom_fichier);
    int numero = create_file(nom_fichier);
    write_file(numero,0,25,"ecriture dans fichier ok!");
    printJ("ecriture dans fichier ok!");
}
