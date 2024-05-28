#Il programma converte un numero binario, rappresentato come stringa (es. "101010"), nel suo equivalente decimale (es. 42) usando la notazione
#polinomiale. Il programma controlla input invalidi. NB il max rappresentabile su 32 bit in valore assoluto è 2^32-1 = 4294967295 ->
#11111111111111111111111111111111
#SPIM non ha una chiamata che permette di stampare interi senza segno. Per questo motivo devo fare la conversione in ASCII

.globl __start

.data 0x10000000
	input:
		.asciiz "11111111111111111111111111111111"	#in memoria la stringa ASCII sara' memorizzata con la rappresentazione binaria (esadecimale nel simulatore).
													#Nel caso di "11" avrò 0x00003131
													#NB memorizzare i byte che rappresentano una stringa ascii con .asciiz fa si che venga aggiunto alla
													#fine il carattere null (0x0). Quindi se la stringa è rappresentata da 32 byte che individuano i caratteri
													#significativi, in realtà bisongna tenere in considerazione l'ultimo che è il null e che in questo caso
													#sarebbe il 33esimo. Questo mi porta all'errore se la seconda direttiva .data e' seguita
													#dall'indirizzo 0x10000020. In questo l'assemblatore carica a partire da 0x10000000 tutti i byte
													#che puo' fino a 0x10000020. Se questi fossero 32 andrebbe bene, tuttavia non lo sono e il null
													#non viene inserito perche' all'indirizzo 0x10000020 c'è newline che è terminata da un carattere
													#null. Per questa ragione quando si determina la dimensione veniva contato anche \n poiche'
													#precedente. Quindi ho semplicemente sostituito 0x10000020 con 0x10000021
															
.data 0x10000021
	newline:			#se avessi messo ascii al posto di asciiz, il significato della stringa sarebbe stato falsato da ciò che viene dopo in memoria
		.asciiz "\n"	#es. "11" e "\n": il contenuto della parola all'indirizzo 0x10000000 sarebbe stato 0x000a3131, con asciiz: 0x0a003131
	str_err_dimensione:
		.asciiz	"Errore. La stringa in input ha una dimensione superiore a 32 caratteri, la massima consentita."
	str_err_carattere:
		.asciiz "Errore. La stringa in input a un carattere che non corrisponde a una codifica ASCII consentita."
	tabella_indirizzi:	#NB al posto di asciiz avrei potuto usare anche .byte, ricordando che il numero che segue è la codifica del carattere ASCII 
		.word peso0, peso1, default
.data 0x10010000
	output: .space 32	#riservo 32 byte per il risultato

.text
	__start:	
				
				la $s0, input				#in $s0 c'e' l'indirizzo associato all'etichetta input
				la $s1, output				#in $s1 c'e' l'indirizzo associato all'etichetta output
				#sw $0, 0($s1)
				add $s6, $0, $0
				add $s3, $0, $0				#in $s3 c'e' il peso della cifra
				add $s4, $0, $0
				
			dim:	lbu $s7, 0($s0)
					addiu	$s6, $s6, 1
					addiu	$s0, $s0, 1
					bne	$s7, $0, dim
					addiu $s0, $s0, -2
					addiu $s6, $s6, -1 
					sltiu $t0, $s6, 33			#se la dimensione dim è >= 33 allora arriveremo ad avere, dopo la conversione un numero non rappresentabile.
					beq $t0, $0, err_dimensione	#il numero massimo rappresentabile ha 32 bit impostati a 1. Ciascun carattere ASCII è un byte, 32 caratteri a 1 sono 32 byte
			loop:	lbu $s2, 0($s0)
					sltiu $t0, $s2, 0x3a 	#0x39 e' la codifica esadecimale ASCII di 9
				 	beq $t0, $0, err_carattere
					sltiu $t0, $s2, 0x30 	#0x30 e' la codifica esadecimale ASCII di 0
					bne $t0, $0, err_carattere
					andi $s2, $s2, 0xf		#per rendere la cifra utilizzabile nelle operazioni aritmetiche, forzo a 0 i primi 24 bit e
											#invariati i rimanenti 8. es codifica binaria ASCII di 1 è 00110001 che diventa 00000001.
					add $a0, $s2, $0
					add $a1, $s3, $0  		#in a1 ho il peso
					jal moltiplicatore
					addu $s4, $s4, $v0
					addiu $s3, $s3, 1
					addiu $s0, $s0, -1
					sltu $t0, $s3, $s6
					bne $t0, $0 loop
					add $a0, $s4, $0
					add $a1, $s6, $0
					add $a2, $s1, $0
					li $a3, 10
					jal conversione
					sb $0, 0($v1)
					li $v0, 4
					la $a0, output
					#la $a0, output non va bene perche' cosi' stampa la rappresentazione decimale dell'indirizzo output
					syscall
					li $v0, 4
					la $a0, newline
					syscall
					li $v0, 10
					syscall
					#j exit
					
					
	moltiplicatore:	addi $sp, $sp, -12
					sw $s5, 8($sp)
					sw $s6, 4($sp)
					sw $s4, 0($sp)
					add $v0, $0, $0
					la $s4, tabella_indirizzi
					sltiu $t0, $a1, 2
					beq $t0, $0, default
					sll $t0, $a1, 2
					add $t0, $s4, $t0
					lw $s5, 0($t0)
					jr $s5
				prodotto:
					multu $a0, $s6
					mflo $v0
					lw $s4, 0($sp)
					lw $s6, 4($sp)
					lw $s5, 8($sp)
					addi $sp, $sp, 12
					jr $ra
	
	conversione:	addi $sp, $sp, -12
					sw $ra, 8($sp)
					sw $s0, 4($sp)
					sw $s1, 0($sp)
					add $s0, $0, $a3	#il massimo divisore è 10^9, lavorando in base 10
					add $s1, $0, $0		#inizializzo $s1
					add $t1, $0, $0
			loop2:	sltu $t0, $a0, $s0
					bne $t0, $0, avanti
					sltiu $t0, $a1, 31  #2^30 è circa 10^9, non riesco a rappresentare 10^10
					addi $t1, $t1, 1
					sltiu $t0, $t1, 9	#moltiplico per 10 partendo da 10, arrivo a 10^9 alla 9a iterazione
					beq $t0, $0, avanti2
					multu $s0, $a3
					mflo $s0
					j loop2
			avanti:	divu $s0, $a3
					mflo $s0
			avanti2:divu $a0, $s0
					mflo $s1
					addi $sp, $sp, -4
					sw $a0, 0($sp)
					add $a0, $s1, $0
					jal ASCIIconv
					lw $a0, 0($sp)
					addi $sp, $sp, 4
					sb $v0, 0($a2)		#subu $a0 - $s1 * $s0
					multu $s0, $s1								#se moltiplico 9 per 10^9
					mflo $t1
					subu $a0, $a0, $t1
					addiu $a2, $a2, 1
					bne $a0, $0 loop2
					add $v1, $a2, $a0
					lw $s1, 0($sp)
					lw $s0, 4($sp)
					lw $ra, 8($sp)
					addi $sp, $sp, 12
					jr $ra
					
	
	ASCIIconv:	ori $v0, $a0, 0x30
				jr $ra
	err_dimensione:	li $v0, 4
					la $a0, str_err_dimensione
					syscall
					li $v0, 10
					syscall
	err_carattere:	li $v0, 4
					la $a0, str_err_carattere
					syscall
					li $v0, 10
					syscall
	err:			li $v0, 4
					la $a0, str_err_dimensione
					syscall
					li $v0, 10
					syscall
	exit:		j exit

.text 0x401000
	peso0:	addi $s6, $0, 1
			j prodotto
	peso1:	addi $s6, $0, 2
			j prodotto
	default:	addi $s6, $0, 2
				addi $t0, $0, 1 
				exp:	addu $s6, $s6, $s6 #con add sarebbe scattato l'overflow
						addi $t0, $t0, 1
						bne $t0, $a1, exp
						j prodotto
				
			#	addi $s0, $0, 10	#il massimo divisore è 10^9
			#	addi $t2, $0, 10
			#bu: addi $t0, $t0, 1	#0x3b9aca00 è 10^9
			#	multu $s0, $t2
			#	mflo $s0
			#	j bu
			
			
			#li $s0, 0xffffffff
				#li $s1, 0x3b9aca00
				#divu $s0, $s1
				#mflo $s2
			
				
				
				#li $t0, 15
				#li $t1, 10
				#divu $t0, $t1
				#mflo $t2