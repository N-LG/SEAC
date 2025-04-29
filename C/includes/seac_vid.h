
#define ECRAN_TEXTE  1
#define ECRAN_VIDEO  2
#define ECRAN_SOURIS 4

struct retourclavier {
    unsigned char touche;
    unsigned char spec;
    unsigned long carac;
    unsigned long x;
    unsigned long y;
};

//******************************************************************************
//fonctions video

long cree_ecran(unsigned char mode_ecran){
    long erreur = 0;
     asm volatile ("mov   $0, %%al\n"
    		  "int   $0x63\n"
    	          :"=eax"(erreur)
                  :"ah"(mode_ecran)
                  :);
    return erreur;

}

void supprime_ecran(){
     asm volatile ("mov   $1, %%al\n"
    		  "int   $0x63\n"
    	          :/*pas de sortie*/
                  :/*pas d'entrée*/
                  :);

}

void afficher_ecran(int id){
    asm volatile ("mov $3,%%al\n"
                  "int $0x63\n"
                  :/*pas de sortie*/ 
                  :"dx"(id)
                  : );
}

struct retourclavier clavier(){
     struct retourclavier structure;
     asm volatile ("mov   $5, %%al\n"
    		  "int   $0x63\n"
                  :"=ah"(structure.touche),"=al"(structure.spec),"=ecx"(structure.carac),"=ebx"(structure.x)
                  :/*aucunes entrées*/
                  :);
    if (structure.touche<0xF0){
        structure.y = 0;
    }else{
        structure.y = structure.carac;
        structure.carac = 0;
    }
    return structure ;
}


char saisie_clavier(char* chaine,char couleur,long taille){
    char retour = 0;
    asm volatile ("mov $6,%%al\n"
                  "int $0x63\n"
                  :"=al"(retour) 
                  :"edx"(chaine),"ah"(couleur),"ecx"(taille)
                  : );
    return retour;
}

void maj_ecran(){
     asm volatile ("mov   $7, %%al\n"
    		  "int   $0x63\n"
    	          :/*pas de sortie*/
                  :/*pas d'entrée*/
                  :);

}

void maj_ecran_partiel(long x1,long y1,long x2,long y2){
     asm volatile ("mov   $8, %%al\n"
    		  "int   $0x63\n"
    	          :/*pas de sortie*/
                  :"ebx"(x1),"ecx"(y1),"eS"(x2),"eD"(y2)
                  :);

}

void printP(char* chaine,long x,long y){
     asm volatile ("mov   $10, %%al\n"
    		  "int   $0x63\n"
    	          :/*pas de sortie*/
                  :"ebx"(x),"ecx"(y),"edx"(chaine)
                  :"eax");
}

void printC(char* chaine){
     asm volatile ("mov   $11, %%al\n"
    		  "int   $0x63\n"
    	          :/*pas de sortie*/
                  :"edx"(chaine)
                  :"eax");
}

void posC(long x,long y){
     asm volatile ("mov   $12, %%al\n"
    		  "int   $0x63\n"
    	          :/*pas de sortie*/
                  :"ebx"(x),"ecx"(y)
                  :"eax");
}

void pixel(unsigned long x,unsigned long y,unsigned long couleur,unsigned char type){
     asm volatile ("mov   $21, %%al\n"
    		  "int   $0x63\n"
    	          :/*pas de sortie*/
                  :"ebx"(x),"ecx"(y),"edx"(couleur),"ah"(type)
                  : );
}

void carre(unsigned long x1,unsigned long y1,unsigned long x2,unsigned long y2,unsigned long couleur,unsigned char type){
     asm volatile ("mov   $22, %%al\n"
    		  "int   $0x63\n"
    	          :/*pas de sortie*/
                  :"ebx"(x1),"ecx"(y1),"edx"(couleur),"ah"(type),"eS"(x2),"eD"(y2)
                  : );
}


void segment(unsigned long x1,unsigned long y1,unsigned long x2,unsigned long y2,unsigned long couleur,unsigned char type){
     asm volatile ("mov   $23, %%al\n"
    		  "int   $0x63\n"
    	          :/*pas de sortie*/
                  :"ebx"(x1),"ecx"(y1),"edx"(couleur),"ah"(type),"eS"(x2),"eD"(y2)
                  : );
}   

void cercle(unsigned long x,unsigned long y,unsigned long couleur,unsigned char type,unsigned long rayon){
     asm volatile ("mov   $24, %%al\n"
    		  "int   $0x63\n"
    	          :/*pas de sortie*/
                  :"ebx"(x),"ecx"(y),"edx"(couleur),"ah"(type),"eS"(rayon)
                  : );
}


void chaine(unsigned long x,unsigned long y,unsigned char couleur,unsigned char* chaine){
     asm volatile ("mov   $25, %%al\n"
    		  "int   $0x63\n"
    	          :/*pas de sortie*/
                  :"ebx"(x),"ecx"(y),"edx"(chaine),"ah"(couleur)
                  : );
}  

void paragraphe(unsigned long x,unsigned long y,unsigned char couleur,unsigned char* chaine,unsigned long largeur){
     asm volatile ("mov   $26, %%al\n"
    		  "int   $0x63\n"
    	          :/*pas de sortie*/
                  :"ebx"(x),"ecx"(y),"edx"(chaine),"ah"(couleur),"eS"(largeur)
                  : );
}  
