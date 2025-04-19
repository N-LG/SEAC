//****************************************************************
//constantes




//****************************************************************
//fonctions

//ouvre un canal
unsigned long open_canal(unsigned char port,unsigned long taille){
    unsigned long erreur = 0;
    asm volatile("mov $0x09, %%al\n"
                 "int $0x66\n"
    	         : "=eax"(erreur)
                 : "ah"(port),"ecx"(taille)
                 : );
    return erreur;
}








