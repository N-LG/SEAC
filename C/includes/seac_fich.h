long last_error=0;

//******************************************************************************
//fonctions d'acces aux fichier

//ouvre le fichier
long open_file(char *nom){
    long erreur = 0;
    long numero = 0;
    asm volatile ("mov   $0x00, %%al\n"
                   "int   $0x64\n"
    	           : "=eax"(erreur),"=ebx"(numero)
                   : "edx"(nom)
                   : );
    if (erreur==0){
        return numero;
    }else{
        last_error = erreur;
        return -1;
    }
}


//ferme le fichier
long close_file(long numero){
    long erreur = 0;
    asm volatile ("mov   $0x01, %%al\n"
                  "int   $0x64\n"
                  : "=eax"(erreur)
                  : "ebx"(numero)
                  : );
    return erreur;
}


//créer fichier
long create_file(char *nom){
    long erreur = 0;
    long numero = 0;
    asm volatile ("mov   $0x02, %%al\n"
                  "int   $0x64\n"
    	          : "=eax"(erreur),"=ebx"(numero)
                  : "edx"(nom)
                  : );
    if (erreur==0){
        return numero;
    }else{
        last_error = erreur;
        return -1;
    }
}

//supprime le fichier
long delete_file(long numero){
    long erreur = 0;
    asm volatile ("mov $0x03, %%al\n"
                  "int $0x64\n"
    	          : "=eax"(erreur)
                  : "ebx"(numero)
                  : );
    return erreur;
}

//lit dans fichier
long read_file(long numero,long offset,long count,char *destination){
    long erreur = 0;
    asm volatile("mov $0x04, %%al\n"
                 "int $0x64\n"
    	         : "=eax"(erreur)
                 : "ebx"(numero),"ecx"(count),"edx"(offset),"eD"(destination)
                 : );
    return erreur;
}

//ecrire dans fichier
long write_file(long numero,long offset,long count,char *source){
    long erreur = 0;
    asm volatile("mov $0x05, %%al\n"
                 "int $0x64\n"
    	         : "=eax"(erreur)
                 : "ebx"(numero),"ecx"(count),"edx"(offset),"eS"(source)
                 : );
    return erreur;
}

//lire taille du fichier
long taille_file(long numero){
    long erreur = 0;
    long taille[2];
    asm volatile("mov $0x05, %%ax\n"
                 "int $0x64\n"
    	         :"=eax"(erreur)
                 :"ebx"(numero),"edx"(&taille)
                 : );
    if (erreur==0){
        return taille[0];
    }else{
        last_error = erreur;
        return -1;
    }
}

//lit la dernière erreur
long error_file(){
    return last_error;
}
