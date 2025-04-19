struct dateheure {
    unsigned long annee;
    unsigned char mois;
    unsigned char jour;
    unsigned char heure;
    unsigned char minute;
    unsigned long milliseconde;
};



//******************************************************************************
//fonctions générales

//envoie une commande au systeme
void cmd(char *commande){
    asm volatile ("mov $0x00, %%al\n"
                  "int   $0x61\n"
    	          : 
                  :"edx"(commande)
                  :"eax");
}


//attend x millisecondes
void delay(unsigned long millis){
    asm volatile ("mov $10, %%eax\n"
                  "xor %%edx, %%edx\n"
                  "mul %%ecx\n"
                  "mov $25, %%ecx\n"
                  "div %%ecx\n"
                  "mov %%eax, %%ecx\n"
                  "mov $0x01,%%al\n"
                  "int $0x61\n"
    	          :/* no output */
                  :"ecx"(millis)
                  :"eax","edx" );

}


//récupère l'ID de la tache
unsigned int id_tache(){
    unsigned int id = 0;
    asm volatile ("mov $0x02, %%al\n"
                  "int   $0x61\n"
    	          :"=bx"(id)
                  : 
                  :"eax");
   return id;
}


//recupère la commande
unsigned long arg_tot(char *string){
    unsigned long erreur = 0;
    asm volatile ("mov $0x00, %%al\n"
                  "int   $0x61\n"
    	          : 
                  :"edx"(string)
                  :"eax");
   return erreur;
}

// récupère argument par son numéros
long arg_num(char numero,char *string){
    unsigned long erreur = 0;
    asm volatile ("mov $0x04, %%al\n"
                  "mov $0x00, %%cl\n"
    		  "int   $0x61\n"
    	          :"=eax"(erreur)
                  :"ah"(numero),"edx"(string)
                  :"cl");
   return erreur;
}

// récupère argument par sa lettre
long arg_lettre(char lettre,char *string){
    long erreur = 0;
    asm volatile ("mov $0x05, %%al\n"
                  "mov $0x00, %%cl\n"
    		  "int $0x61\n"
    	          :"=eax"(erreur)
                  :"ah"(lettre),"edx"(string)
                  :"cl");
   return erreur;
}

//affiche du texte dans le journal
void printJ(char *string){
    asm volatile ("mov   $0x06, %%al\n"
                  "int   $0x61\n"
                  :/* no output */
                  :"edx"(string)
                  :"eax");
}

//modifie le descripteur de tache
void printD(char *string){
    asm volatile ("mov   $0x07, %%al\n"
                  "int   $0x61\n"
                  : /* no output */
                  :"edx"(string)
                  :"eax");
}

//change la taille de la mémoire
long changeT(long taille){
    long erreur = 0;
    asm volatile ("mov $0x08, %%al\n"
                  "mov $0x47,%%dx\n"
                  "int   $0x61\n"
                  :"=eax"(erreur)
                  :"ecx"(taille)
                  :"dx");
    return erreur;
}

//récupère la date et l'heure
struct dateheure lireDH(){
    struct dateheure structure;
    asm volatile ("mov   $0x09, %%al\n"
                  "int   $0x61\n"
                  :"=bh"(structure.heure),"=bl"(structure.minute),"=eS"(structure.milliseconde),"=dl"(structure.jour),"=dh"(structure.mois),"=ecx"(structure.annee)
                  :/*aucunes entrées*/
                  :);
    return structure ;
}

//change le type de service
void changeS(unsigned char service){
    asm volatile ("mov   $0x0A, %%al\n"
                  "int   $0x61\n"
                  :
                  :"ah"(service)
                  :);
}

//cherche service
unsigned long rechercheS(unsigned char service,unsigned int *table,unsigned char taille){
    unsigned long erreur = 0;
    asm volatile ("mov   $0x0B, %%al\n"
                  "int   $0x61\n"
                  :
                  :"ah"(service),"edx"(table),"cl"(taille)
                  :);
    return erreur;
}

//lit le compteur de temps
long compteur(){
    long lsb;
    long msb;
    asm volatile ("mov   $0x0C, %%al\n"
                  "int   $0x61\n"
                  :"=eax"(lsb),"=ebx"(msb)
                  :/*aucunes entrées*/
                  :);
    return lsb;
}

//lire un message systeme
void message_systeme(int num,char* chaine){
    asm volatile ("mov   $0x000D, %%ax\n"
                  "mov   $0, %%ch\n"
                  "int   $0x61\n"
                  :"=edx"(chaine),"=cl"(num)
                  :/*aucunes entrées*/
                  :);   
}

//lire un message d'erreur
void message_erreur(int num,char* chaine){
    asm volatile ("mov   $0x010D, %%ax\n"
                  "mov   $0, %%ch\n"
                  "int   $0x61\n"
                  :"=edx"(chaine),"=cl"(num)
                  :/*aucunes entrées*/
                  :);   
}

//lire journal systeme
void lire_journal(char* chaine,long taille){
    asm volatile ("mov   $0x0E, %%al\n"
                  "int   $0x61\n"
                  :/*pas de sortie*/
                  :"edx"(chaine),"ecx"(taille)
                  :);   
}

//copier des données dans le presse papier
void ecrire_pp(char* chaine,long taille){
    asm volatile ("mov   $0x0F, %%al\n"
                  "int   $0x61\n"
                  :/*pas de sortie*/
                  :"edx"(chaine),"ecx"(taille)
                  :);   
}


//lire les donnés dans le presse papier
void lire_pp(char* chaine,long taille){
    asm volatile ("mov   $0x10, %%al\n"
                  "int   $0x61\n"
                  :/*pas de sortie*/
                  :"edx"(chaine),"ecx"(taille)
                  :);   
}

//effacer le contenu du presse papier
void effacer_pp(){
     asm volatile ("mov   $0x11, %%al\n"
    		  "int   $0x61\n"
    	          :/*pas de sortie*/
                  :/*pas d'entrée*/
                  :);

}

//lire l'adresse du dossier de travail
void lire_dossier_travail(char* chaine){
    asm volatile ("mov   $0x12, %%al\n"
                  "int   $0x61\n"
                  :/*pas de sortie*/
                  :"edx"(chaine)
                  :);   
}

//lire l'adresse du dossier de travail
void sous_taches(int* chaine,char nb){
    asm volatile ("mov   $0x13, %%al\n"
                  "int   $0x61\n"
                  :/*pas de sortie*/
                  :"edx"(chaine),"cl"(nb)
                  :);   
}
