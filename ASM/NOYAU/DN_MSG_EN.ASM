dn_msg_en:
;message systeme uttilisé par SeAC 💩
;doit être entregistré au format utf8


messages_systeme:
db 1Ah,0C2h,080h,0C2h,081h,0C2h,082h,0C2h,083h,"SEAC V0.21 June 2022 development version",13 
db 0C2h,084h,0C2h,085h,0C2h,086h,0C2h,087h,"Systeme d'Exploitation Aproximativement Complet",17h,13,0


db 13,16h,"unknown command: ",0 ;1
db 13,16h,"directory not found: ",0   ;2
db 13,16h,"Error while executing the command ",34,0     ;3
db 13,16h, "Task not found: ",0 ;4
db 0  ;5
db 13,16h,"unrecognized file format",13,0  ;6
db 13,16h,"Video mode not supported",13,0 ;7
db 0 ;8
db 13,16h,"Locked video mode change",13,0 ;9


;message des exceptions
db "Divide Error",0                    ;ex0 message 10
db "Debug Exception",0                        ;ex1     
db "Nonmaskable external interrupt",0      ;ex2
db "Breakpoint",0        ;ex3 
db "Overflow",0              ;ex4
db "BOUND Range Exceeded",0       ;ex5
db "Invalid Opcode (Undefined Opcode)",0    ;ex6
db "No Math Coprocessor",0       ;ex7
db "Double fault",0                 ;ex8
db "CoProcessor Segment Overrun",0  ;ex9
db "Invalid TSS",0                 ;ex10
db "Segment Not Present",0    ;ex11
db "Stack fault",0                 ;ex12
db "General protection fault",0  ;ex13
db "Page Fault",0   ;ex14
db "Exception # 15",0   ;ex15
db "x87 FPU Floating-Point Error",0          ;ex16
db "Alignment Check",0 ;ex17
db "Machine Check",0       ;ex18
db "SIMD Floating-Point Exception",0         ;ex19
db "Virtualization Exception",0    ;ex20
db "exception # 21",0   ;21
db "exception # 22",0   ;22
db "exception # 23",0   ;23
db "exception # 24",0   ;24
db "exception # 25",0   ;25
db "exception # 26",0   ;26
db "exception # 27",0   ;27
db "exception # 28",0   ;28
db "exception # 29",0   ;29
db "exception # 30",0   ;30
db "exception # 31",0   ;ex31 message 41 

db 13,"Process # ",0 ;42
db " caused the exception: ",0 ;43
db " after step ",0  ;44
db 13,"the main task had to be restarted",17h,13,0  ;45
db 13,"the faulty task had to be stopped",17h,13,0  ;46
db "impossible to reserve memory",0  ;47 seul texte qui doit être codé en ISO 8859-1 et pas en UTF8
db 1Ch,"detection of an error in memory, erasure of corrupted memory",17h,13,0  ;48
db 0  ;49





db 13,"List of disks:",13,"#dm  Ram Disk",13,0  ;50
db 13,"Liste des partitions et disques amovibles detecté:",13,0 ;51
db " Unknown partition type(",0 ;52
db " damaged partition of ",0 ;53
db " partition type FAT12 of",0 ;54
db " partition type FAT16 of ",0 ;55
db " partition type FAT32 of ",0 ;56   
db " partition type exFAT of ",0 ;57
db " partition type Ext2 of ",0 ;58
db " partition type Ext3 of ",0 ;59
db " partition type TOD of ",0 ;60
db " partition type NTFS of ",0 ;61
db " partition type SFS of ",0 ;62
db 0 ;63
db 0 ;64
db 0 ;65
db 0 ;66
db 0 ;67
db 0 ;68
db "#di  Floppy Drive",13,0 ;69

db 13,"List of files in the folder: ",0   ;70

db 13,"List of Tasks running:",13,0   ;71


db 13,"memory organization:",13,0   ;72 
db "free memory: ",0   ;73
db 13,"memory used by system: ",0    ;74
db 13,"memory used by task: ",0    ;75
db 13,"memory used by communication between tasks: ",0 ;76
db 13,"total memory: ",0 ;77

db " bytes",13,0 ;78
db 0 ;79

db 13,"List of video modes supported:",13,0   ;80
db " text",13,0;81
db "bits banked memory",13,0 ;82
db "bits linear memory",13,0 ;83
db 0 ;84
db 0 ;85
db 0 ;86
db " file has been loaded for the language definition",13,0               ;87
db " file has been loaded for the keyboard definition",13,0               ;88
db " file has been loaded for the graphic character definition",13,0 ;89

db 0 ;90
db 0 ;91
db "forced stop of task ",0  ;92
db "modification of the execution time of the task ",0  ;93
db "the system folder has been defined",13,0  ;94
db " has been copied to ",0  ;95
db " has been removed",13,0  ;96
db " file has been renamed to ",0  ;97
db "the ",0  ;98
db 0  ;99
db "USB device ",34,0; 100
db 34," has been connected to address ", 0; 101
db "error when connecting a new USB device",13,0; 102
db "disconnection of USB device", 0; 103


;************************************************************************
messages_erreur:
db "execution sans probleme",0
db "parameter error",13,0                                     ;erreur 1
db "read error",13,0                                          ;erreur 2
db "drive / disk / file not found",13,0                       ;erreur 3
db "file system error",13,0                                   ;erreur 4
db "writing error",13,0                                       ;erreur 5
db "no disk response",13,0                                    ;erreur 6
db "disk busy",13,0                                           ;erreur 7
db "file already open",13,0                                   ;erreur 8
db "forbidden reading",13,0                                   ;erreur 9
db "forbidden opening",13,0                                   ;erreur 10
db "not enougth memory",13,0                                  ;erreur 11
db "the open file is a folder",13,0                           ;erreur 12
db "error of unknown origin",13,0                             ;erreur 13
db "unrecognized number of colors",13,0                       ;erreur 14
db "screen missing",13,0                                      ;erreur 15
db "unauthorized action",13,0                                 ;erreur 16
db "empty buffer zone",13,0                                   ;erreur 17
db "full buffer zone",13,0                                    ;erreur 18
db "controller does not respond",13,0                         ;erreur 19
db "controller absent",13,0                                   ;erreur 20
db "cannot delete folder because it is not empty",13,0        ;erreur 21
db "forbidden character in file name",13,0                    ;erreur 22
db "file creation not possible",13,0                          ;erreur 23
db "file name already used",13,0                              ;erreur 24
db "no answer",13,0                                           ;erreur 25
db "structure error",13,0                                     ;erreur 26
db "data available",13,0                                      ;erreur 27
db "data not available",13,0                                  ;erreur 28
db "memory area unavailable",13,0                             ;erreur 29
db "memory area outside physical memory",13,0                 ;erreur 30
db "UHCI controller error",13,0                               ;erreur 31
db "OHCI controller error",13,0                               ;erreur 32
db "EHCI controller error",13,0                               ;erreur 33
db "XHCI controller error",13,0                               ;erreur 34
db "Stack overflow or underflow",13,0                         ;erreur 35
db "Invalid arithmetic operation",13,0                        ;erreur 36
db "Invalid operation",13,0                                   ;erreur 37
db "Denormalized operand",13,0                                ;erreur 38
db "Divide-by-zero",13,0                                      ;erreur 39
db "Numeric overflow",13,0                                    ;erreur 40
db "Numeric underflow",13,0                                   ;erreur 41
db "Inexact result (precision)",13,0                          ;erreur 42



fin_messages:
