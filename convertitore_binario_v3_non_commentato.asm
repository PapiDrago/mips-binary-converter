#Il programma converte un numero binario (es. "101010"), decimale o esadecimale, rappresentato come stringa ASCII,
#nel suo equivalente decimale (es. "42"), esadecimale o binario usando la notazione polinomiale e la rappresentazione in caratteri ASCII.
#Il convertitore ha 4 modalita' di funzionamento, ciascuna di esse e' individuata
#da un numero da 0 a 3 rappresentato da una stringa ASCII memorizzata nell'area di memoria input:
#"0" -> Decimale a Binario 
#"1" -> Binario a Decimale
#"2" -> Esadecimale a Decimale
#"3" -> Decimale a Esadecimale
#Il programma controlla input invalidi e l'occorenza di carry.
#Il max rappresentabile su 32 bit in valore assoluto è 2^32 - 1 = 4294967295 <-> 11111111111111111111111111111111 <-> ffffffff
#aggiungere in coda alle conversioni il conteggio del numero di 1 presenti nel risultato ottenuto.
.globl __start

.data 0x10000000
	input:
		.asciiz "0"				#Scelta modalita' 0->DtoB, 1->BtoD, 2->HextoD, 3->DtoHex
		.asciiz "65535"
.data 0x10000023
	newline:			
		.asciiz "\n"
	str_err_dimensione:
		.asciiz	"Errore. La stringa in input ha una dimensione superiore alla massima consentita."
	str_err_carattere:
		.asciiz "Errore. La stringa in input a un carattere che non corrisponde a una codifica ASCII consentita."
	str_err_carry:
		.asciiz "Errore. Non è possibile rappresentare  la conversione poiché non ho abbastanza bit."
	tabella_indirizzi_conv:
		.word DtoB, BtoD, HextoD, DtoHex
	tabella_indirizzi_peso: 
		.word peso0, peso1, default
	tabella_indirizzi_HexDecoder:
		.word dieci, undici, dodici, tredici, quattordici, quindici
	tabella_indirizzi_HexASCIIconv:
		.word f, e, d, c, bi, a
.data 0x10010000
	output: .space 32

.text
	__start:	
			la $s0, input				#In $s0 c'e' l'indirizzo associato all'etichetta input.
			la $s1, output				#In $s1 c'e' l'indirizzo associato all'etichetta output.
			lbu $t0, 0($s0)
			andi $t0, $t0, 0xf
			sll $t0, $t0, 2
			la $t1, tabella_indirizzi_conv
			addu $t0, $t0, $t1
			lw $t1, 0($t0)
			jr $t1
	
	DtoB:	addiu $s0, $s0, 2			#$s0 deve puntare al primo carattere della stringa in ingresso.
			add $s2, $0, $0				#In $s2 ci sara' la dimensione della stringa in ingresso. Qui inizializzo.
			add $s3, $0, $0				#In $s3 ci sara' il peso della cifra. Qui inizializzo.
			add $s4, $0, $0				#In $s4 ci sara' la rappresentazione in valore assoluto del numero binario identificato dalla stringa
										#ASCII in ingresso.
			add $a0, $s0, $0			#In $a0 ho l'indirizzo della prima cella di memoria dell'area dati input.
			add $a1, $s2, $0			
			jal dim						
			add $s0, $v0, $0
			add $s2, $v1, $0
			sltiu $t0, $s2, 11
			beq $t0, $0, err_dimensione
			
			loopDtoB:	lbu $s5, 0($s0)
												
												
						addu $a0, $s5, $0		
												
						jal checkASCIIDec
						add $s5, $v0, $0
						add $a0, $s5, $0		#In $a0 ho la configurazione binaria che rapprensenta in valore assoluto un numero da 0 a 9.
						add $a1, $s3, $0  		#In $a1 ho il peso della cifra che sto valutando.
						li $a2, 10				#In $a2 ho la base del numero da convertire.
						jal moltiplicatore		#Chiamata alla procedura moltiplicatore.
						addu $a0, $s4, $0		#In $a0 ho il valore del numero determinato nelle iterazioni precedenti.
						addu $a1, $v0, $0		#In $a1 ho il valore da sommare a $s4 ottenuto nell'iterazione corrente.
						jal check_carry
						addu $s4, $s4, $v0		
						addiu $s3, $s3, 1		
						addiu $s0, $s0, -1
						sltu $t0, $s3, $s2		
						bne $t0, $0 loopDtoB	
						add $a0, $s4, $0		#In $a0 c'e' il valore binario del numero.	
						add $a1, $s2, $0		#In $a1 la dimensione della stringa.	
						add $a2, $s1, $0		#In $a2 l'indirizzo di output.
						li $a3, 2				#Carico in $a3 la base in cui converto il numero binario.
						li $t2, 31				#In $t2, il numero per limitare l'iterazione che determina il divisore.
						jal conversione
						j termine
			
	BtoD:	
			addiu $s0, $s0, 2
			add $s2, $0, $0				#In $s2 ci sara' la dimensione della stringa in ingresso.
			add $s3, $0, $0				#In $s3 ci sara' il peso della cifra.
			add $s4, $0, $0				#In $s4 ci sara' la rappresentazione in valore assoluto del numero binario identificato dalla stringa
										#ASCII in ingresso.
			add $a0, $s0, $0			#In $a0 ho l'indirizzo della prima cella di memoria dell'area dati input.
			add $a1, $s2, $0			#Inizializzo $a1 che conterrà il valore usato per ottenere la dimensione.
			jal dim						
			add $s0, $v0, $0			
			add $s2, $v1, $0
			sltiu $t0, $s2, 33			
			beq $t0, $0, err_dimensione
			
			loopBtoD:	lbu $s5, 0($s0)			
						addu $a0, $s5, $0		#In $a0 copio la configurazione ASCII da controllare.
												
						jal checkASCIIBin		
						add $s5, $v0, $0		
						add $a0, $s5, $0		#In $a0 ho la configurazione binaria di 0 oppure 1.
						add $a1, $s3, $0  		#In $a1 ho il peso della cifra che sto valutando.
						li $a2, 2				#In $a2 ho la base del numero da convertire.
						jal moltiplicatore		
						addu $s4, $s4, $v0		
						addiu $s3, $s3, 1		
						addiu $s0, $s0, -1		
						sltu $t0, $s3, $s2		
						bne $t0, $0 loopBtoD	
						add $a0, $s4, $0		
						add $a1, $s2, $0		
						add $a2, $s1, $0		#In $a0 c'e' il valore binario del numero. In $a1 la dimensione della stringa. In $a2 l'indirizzo di output.
						li $a3, 10				#Carico in $a3 la base in cui converto il numero binario.
						li $t2, 9				#Mi serve per limitare il ciclo in conversione.
						jal conversione
						j termine
	
	HextoD:	la $s7, tabella_indirizzi_HexDecoder	#In $s7 carico l'indirizzo della tabella.
			addiu $s0, $s0, 2
			add $s2, $0, $0				#In $s2 ci sara' la dimensione della stringa in ingresso.
			add $s3, $0, $0				#In $s3 ci sara' il peso della cifra.
			add $s4, $0, $0				#In $s4 ci sara' la rappresentazione in valore assoluto del numero binario identificato dalla stringa
										#ASCII in ingresso.
			add $a0, $s0, $0			#In $a0 ho l'indirizzo della prima cella di memoria dell'area dati input.
			add $a1, $s2, $0
			jal dim				
			add $s0, $v0, $0
			add $s2, $v1, $0
			sltiu $t0, $s2, 9
			beq $t0, $0, err_dimensione
			
			loopHextoD:	lbu $s5, 0($s0)
						addu $a0, $s5, $0		#In $a0 copio la configurazione ASCII da controllare.
						addu $a1, $s7, $0		#In $a1 copio l'indirizzo della memoria della tabella.
						jal checkASCIIHex1
						add $a0, $v0, $0		#In $a0 ho la configurazione binaria che rapprensenta in valore assoluto un numero da 0 a 15.
						add $a1, $s3, $0  		#In $a1 ho il peso della cifra che sto valutando.
						li $a2, 16				#In $a2 ho la base del numero da convertire.
						jal moltiplicatore		
						addu $s4, $s4, $v0		
						addiu $s3, $s3, 1		
						addiu $s0, $s0, -1		
						sltu $t0, $s3, $s2		
						bne $t0, $0 loopHextoD	
						add $a0, $s4, $0		
						add $a1, $s2, $0		
						add $a2, $s1, $0		#In $a0 c'e' il valore binario del numero. In $a1 la dimensione della stringa. In $a2 l'indirizzo di output.
						li $a3, 10				#Carico in $a3 la base in cui converto il numero binario.
						li $t2, 9				#In $t2, il numero per limitare l'iterazione che determina il divisore.
						jal conversione	
						j termine
	
	DtoHex:	addiu $s0, $s0, 2
			add $s2, $0, $0				#In $s2 ci sara' la dimensione della stringa in ingresso.
			add $s3, $0, $0				#In $s3 ci sara' il peso della cifra.
			add $s4, $0, $0				#In $s4 ci sara' la rappresentazione in valore assoluto del numero binario identificato dalla stringa
										#ASCII in ingresso.
			add $a0, $s0, $0			#In $a0 ho l'indirizzo della prima cella di memoria dell'area dati input.
			add $a1, $s2, $0		
			jal dim			
			add $s0, $v0, $0
			add $s2, $v1, $0
			sltiu $t0, $s2, 11
			beq $t0, $0, err_dimensione
			
			loopDtoHex:	lbu $s5, 0($s0)			
												
												
						addu $a0, $s5, $0		
	
						jal checkASCIIDec		
						add $s5, $v0, $0
						add $a0, $s5, $0		#In $a0 ho la configurazione binaria che rapprensenta in valore assoluto un numero da 0 a 9.
						add $a1, $s3, $0  		#In $a1 ho il peso della cifra che sto valutando.
						li $a2, 10				#In $a2 ho la base del numero da convertire.
						jal moltiplicatore		
						addu $a0, $s4, $0		#In $a0 ho il valore del numero determinato nelle iterazioni precedenti
						addu $a1, $v0, $0		#In $a1 ho il valore da sommare a $s4 ottenuto nell'iterazione corrente 
						jal check_carry
						addu $s4, $s4, $v0	
						addiu $s3, $s3, 1
						addiu $s0, $s0, -1
						sltu $t0, $s3, $s2		
						bne $t0, $0 loopDtoHex	
						add $a0, $s4, $0		#In $a0 c'e' il valore binario del numero. In $a1 la dimensione della stringa. In $a2 l'indirizzo di output.
						add $a1, $s2, $0
						add $a2, $s1, $0		
						li $a3, 16				
						li $t2, 7				#In $t2, il numero per limitare l'iterazione che determina il divisore.
						jal conversione
						j termine
	
	dim:			lbu $t0, 0($a0)			
					addiu	$a1, $a1, 1	
					addiu	$a0, $a0, 1
					bne	$t0, $0, dim			
					addiu $a0, $a0, -2			
												
					addiu $a1, $a1, -1 			
												
					add $v0, $a0, $0			
					add $v1, $a1, $0			
					jr $ra
					
					
	moltiplicatore:	addi $sp, $sp, -12
					sw $s5, 8($sp)			
					sw $s6, 4($sp)
					sw $s0, 0($sp)
					add $v0, $0, $0
					la $s0, tabella_indirizzi_peso
					sltiu $t0, $a1, 2
					beq $t0, $0, peso_default
					sll $t0, $a1, 2	
					addu $t0, $s0, $t0		
					lw $s5, 0($t0)			
					jr $s5
				prodotto:
					multu $a0, $v0
					mflo $v0
					mfhi $t0
					bne $t0, $0, err_carry
					lw $s0, 0($sp)			
					lw $s6, 4($sp)
					lw $s5, 8($sp)
					addi $sp, $sp, 12
					jr $ra
	
	conversione:	addi $sp, $sp, -12	 	
					sw $ra, 8($sp)			#In $a1 la dimensione della stringa.
					sw $s0, 4($sp)			#In $a0 c'e' il valore binario del numero.
					sw $s1, 0($sp)			#In $a2 l'indirizzo di output.
					add $s0, $0, $a3		#Copio in in $s0 il valore della base che sarà la potenza di partenza. E' il divisore.
					add $s1, $0, $0			
					add $t1, $0, $0			#$t1 conta le iterazioni.	
					addiu $t3, $0, 1		#1 mi serve per il controllo finale.
potenza_iniziale:	sltu $t0, $a0, $s0
					bne $t0, $0, avanti		

					addi $t1, $t1, 1
					sltu $t0, $t1, $t2
					beq $t0, $0, avanti2	
					multu $s0, $a3
					mflo $s0
					j potenza_iniziale
			avanti:	divu $s0, $a3
					mflo $s0
			avanti2:divu $a0, $s0
					mflo $s1
					
					addi $sp, $sp, -16
					sw $a3, 12($sp)
					sw $a2, 8($sp)
					sw $a1, 4($sp)
					sw $a0, 0($sp)
					add $a0, $s1, $0		#In $a0 copio la cifra ottenuta dalla divisione.
					jal ASCIIconv	
					lw $a0, 0($sp)
					lw $a1, 4($sp)
					lw $a2, 8($sp)
					lw $a3, 12($sp)
					addi $sp, $sp, 16
					sb $v0, 0($a2)
					multu $s0, $s1
					mflo $t1
					subu $a0, $a0, $t1
					
							beq $0, $s1, avanti10
							addiu $s7, $s7, 1
					avanti10: addiu $a2, $a2, 1
					bne $s0, $t3 avanti
					add $v1, $a2, $a0
					lw $s1, 0($sp)
					lw $s0, 4($sp)
					lw $ra, 8($sp)
					addi $sp, $sp, 12
					jr $ra
					
	ASCIIconv:				sltiu $t0, $a0, 10
							bne $t0, $0, cifra_decimale
							la $a1, tabella_indirizzi_HexASCIIconv
							li $t1, 15
							subu $a2, $t1, $a0
							sll $a2, $a2, 2
							addu $a2, $a2, $a1
							lw $a3, 0($a2)
							jr $a3
		cifra_decimale:		ori $v0, $a0, 0x30
							jr $ra
				
	check_carry:	nor $t0, $a0, $0			#In $a0 ho il valore del numero determinato nelle iterazioni precedenti.
					sltu $v1, $t0, $a1			#In $a1 ho il valore da sommare a $s4 ottenuto nell'iterazione corrente.
					bne $v1, $0, err_carry
					add $v0, $a1, $0
					jr $ra
					
	checkASCIIHex1:	sltiu $t0, $a0, 0x67
					beq $t0, $0, err_carattere
					sltiu $t0, $a0, 0x61
					bne $t0, $0, checkASCIIHex2
					j HexDecoder
			
	checkASCIIHex2:	sltiu $t0, $a0, 0x47
					beq $t0, $0, err_carattere
					sltiu $t0, $a0, 0x41
					bne $t0, $0, checkASCIIDec
					j HexDecoder
					
	checkASCIIDec:	sltiu $t0, $a0, 0x3a
					beq $t0, $0, err_carattere	
					sltiu $t0, $a0, 0x30
					bne $t0, $0, err_carattere
					andi $v0, $a0, 0xf
					jr $ra
					
	checkASCIIBin:	sltiu $t0, $a0, 0x32
					beq $t0, $0, err_carattere	
					sltiu $t0, $a0, 0x30
					bne $t0, $0, err_carattere
					andi $v0, $a0, 0xf
					jr $ra
					
	HexDecoder:		andi $v0, $a0, 0xf
					sll $t0, $v0, 2
					addu $t0, $t0, $a1
					addi $t0, $t0, -4
					lw $t1, 0($t0)
					jr $t1
					
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
	err_carry:		li $v0, 4
					la $a0, str_err_carry
					syscall
					li $v0, 10
					syscall
	err:			li $v0, 4
					la $a0, str_err_dimensione
					syscall
					li $v0, 10
					syscall
	termine:		sb $0, 0($v1)
					li $v0, 4
					la $a0, output
					syscall
					li $v0, 4
					la $a0, newline
					syscall
					li $v0, 10				
					syscall

.text 0x401000
	peso0:			addi $v0, $0, 1
					j prodotto
	peso1:			addu $v0, $a2, $0			#In $a2, c'e' la base del numero da convertire.
					j prodotto
	peso_default:	addu $v0, $a2, $0
					addi $t0, $0, 1 
					exp:	multu $v0, $a2
							mflo $v0
							addi $t0, $t0, 1
							bne $t0, $a1, exp
							j prodotto
	
	dieci:			li $v0, 0xa
					jr $ra
	undici:			li $v0, 0xb
					jr $ra
	dodici:			li $v0, 0xc
					jr $ra
	tredici:		li $v0, 0xd
					jr $ra
	quattordici:	li $v0, 0xe
					jr $ra
	quindici:		li $v0, 0xf
					jr $ra
	
		f:			ori $v0, $0, 0x46
					jr $ra
		e:			ori $v0, $0, 0x45
					jr $ra
		d:			ori $v0, $0, 0x44
					jr $ra
		c:			ori $v0, $0, 0x43
					jr $ra
		bi:			ori $v0, $0, 0x42
					jr $ra
		a:			ori $v0, $0, 0x41
					jr $ra