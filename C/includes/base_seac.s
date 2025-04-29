.intel_syntax noprefix


.section .data


.section .text


.global _start

_start:
call main
int 0x60




