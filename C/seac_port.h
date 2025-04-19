//****************************************************************
//constantes




//****************************************************************
//fonctions port

//envoi un octet sur le port
unsigned long send1_port(unsigned char port,unsigned char data){
    unsigned long erreur = 0;
    asm volatile("mov $0x00, %%al\n"
                 "int $0x66\n"
    	         : "=eax"(erreur)
                 : "ah"(port),"cl"(data)
                 : );
    return erreur;
}


unsigned long sendM_port(unsigned char port,unsigned char *data,unsigned long count){
    unsigned long erreur = 0;
    asm volatile("mov $0x01, %%al\n"
                 "int $0x66\n"
    	         : "=eax"(erreur)
                 : "ah"(port),"eS"(data),"ecx"(count)
                 : );
    return erreur;
}

unsigned long recv1_port(unsigned char port,unsigned char *data){
    unsigned long erreur = 0;
    asm volatile("mov $0x02, %%al\n"
                 "int $0x66\n"
                 "mov %%cl,(%0)\n"
    	         : "=eax"(erreur)
                 : "ah"(port),"r"(data)
                 : );
    return erreur;
}


unsigned long recvM_port(unsigned char port,char *data,unsigned long count){
    unsigned long erreur = 0;
    asm volatile("mov $0x03, %%al\n"
                 "int $0x66\n"
    	         : "=eax"(erreur)
                 : "ah"(port),"eD"(data),"ecx"(count)
                 : );
    return erreur;
}

unsigned long recvC_port(unsigned char port,unsigned long *control){
    unsigned long erreur = 0;
    asm volatile("mov $0x04, %%al\n"
                 "int $0x66\n"
                 "mov %%ecx,(%0)\n"
    	         : "=eax"(erreur)
                 : "ah"(port),"r"(control)
                 : );
    return erreur;
}

unsigned long sendC_port(unsigned char port,unsigned long control){
    long erreur = 0;
    asm volatile("mov $0x05, %%al\n"
                 "int $0x66\n"
    	         : "=eax"(erreur)
                 : "ah"(port),"ecx"(control)
                 : );
    return erreur;
}


unsigned long conf_port(unsigned char port,char attributs,unsigned long vitesse){
    unsigned long erreur = 0;
    asm volatile("mov $0x06, %%al\n"
                 "int $0x66\n"
    	         : "=eax"(erreur)
                 : "ah"(port),"dl"(attributs),"ecx"(vitesse)
                 : );
    return erreur;
}


unsigned long res_port(unsigned char port){
    unsigned long erreur = 0;
    asm volatile("mov $0x07, %%al\n"
                 "int $0x66\n"
    	         : "=eax"(erreur)
                 : "ah"(port)
                 : );
    return erreur;
}


unsigned long lib_port(unsigned char port){
    unsigned long erreur = 0;
    asm volatile("mov $0x08, %%al\n"
                 "int $0x66\n"
    	         : "=eax"(erreur)
                 : "ah"(port)
                 : );
    return erreur;
}

unsigned long ztr_port(unsigned char port,unsigned long taille){
    unsigned long erreur = 0;
    asm volatile("mov $0x09, %%al\n"
                 "int $0x66\n"
    	         : "=eax"(erreur)
                 : "ah"(port),"ecx"(taille)
                 : );
    return erreur;
}






