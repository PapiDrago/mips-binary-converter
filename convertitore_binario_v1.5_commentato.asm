#Il programma converte un numero binario, rappresentato come stringa (es. "101010"), nel suo equivalente decimale (es. 42) usando la notazione
#polinomiale. Il programma controlla input invalidi. NB il max rappresentabile su 32 bit in valore assoluto è 2^32-1 = 4294967295 ->
#11111111111111111111111111111111
#0x3b9aca00 = 10^9
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
				
			la $s0, input				#In $s0 c'e' l'indirizzo associato all'etichetta input.
			la $s1, output				#In $s1 c'e' l'indirizzo associato all'etichetta output.
			#sw $0, 0($s1)
			add $s2, $0, $0				#In $s2 ci sara' la dimensione della stringa in ingresso. Qui inizializzo.
			add $s3, $0, $0				#In $s3 ci sara' il peso della cifra. Qui inizializzo.
			add $s4, $0, $0				#In $s4 ci sara' la rappresentazione in valore assoluto del numero binario identificato dalla stringa
										#ASCII in ingresso.
			add $a0, $s0, $0			#In $a0 ho l'indirizzo della prima cella di memoria dell'area dati input.
			add $a1, $s2, $0			#Inizializzo $a1 che conterrà il valore usato per ottenere la dimensione.
			jal dim						#Chiamata al sottoprogrammma.
			add $s0, $v0, $0			#Conservo e faccio uso dei risultati della procedura.
			add $s2, $v1, $0
			sltiu $t0, $s2, 33			#Se la dimensione dim è >= 33 allora arriveremmo ad avere, dopo la conversione un numero non rappresentabile.
			beq $t0, $0, err_dimensione	#il numero massimo rappresentabile ha 32 bit impostati a 1. Ciascun carattere ASCII è un byte,
										#32 caratteri a 1 sono 32 byte
			
			loop:	lbu $s5, 0($s0)				#Carico in $s5 il byte contenuto nella cella di indirizzo $s0. NB si parte dalla cella di
												#memoria di indirizzo piu' grande fino ad arrivare a 0x10000000, quella in cui è contenuta
												#la codifica ASCII della cifra decimale di peso piu' grande.
					sltiu $t0, $s5, 0x3a 		#0x39 e' la codifica esadecimale ASCII di 9. Controllo se la configurazione è
				 	beq $t0, $0, err_carattere	#all'interno dell'intervallo in cui si trovano quelle significative per noi.
					sltiu $t0, $s5, 0x30 		#0x30 e' la codifica esadecimale ASCII di 0.
					bne $t0, $0, err_carattere	#Termino il controllo
					
					andi $s5, $s5, 0xf		#Per rendere la cifra utilizzabile nelle operazioni aritmetiche, forzo a 0 i primi 24 bit e
											#invariati i rimanenti 8. es codifica binaria ASCII di 1 è 00110001 che diventa 00000001.
					
					add $a0, $s5, $0		#In $a0 ho la configurazione binaria di 0 oppure 1.
					add $a1, $s3, $0  		#In $a1 ho il peso della cifra che sto valutando.
					jal moltiplicatore		#Chiamata alla procedura moltiplicatore.
					addu $s4, $s4, $v0		#Viene sommato il valore del numero calcolato alla precedente iterazione con il valore posizionale corrente.
					addiu $s3, $s3, 1		#Incremento il peso.
					addiu $s0, $s0, -1		#Decremento l'indirizzo che puntera' al byte precedente in memoria.
					sltu $t0, $s3, $s2		#Confronto tra peso e dimensione per capire se si e' conclusa la determinazione del numero binario
					bne $t0, $0 loop		#in valore assoluto.
					add $a0, $s4, $0		#Una volta concluso il compito precedente è necessario convertire in base 10 il numero in binario.
					add $a1, $s2, $0		#Ogni cifra sarà codificata con il corripondente codice ASCII in modo da stampare il risultato come stringa.
					add $a2, $s1, $0		#In $a0 c'e' il valore binario del numero. In $a1 la dimensione della stringa. In $a2 l'indirizzo di output.
					li $a3, 10				#Carico in $a3 la base in cui converto il numero binario.
					jal conversione
					sb $0, 0($v1)			#Termino la stringa di output con il carattere null.
					li $v0, 4
					la $a0, output			#Chiamata a syscall per la stampa a video dell'output, per l'andata a capo e per
					syscall
					li $v0, 4
					la $a0, newline
					syscall					#terminare l'esecuzione del programma
					li $v0, 10				
					syscall
	
	dim:			lbu $t0, 0($a0)			
					addiu	$a1, $a1, 1			#A ogni iterazione incremento dimensione e indirizzo di 1.
					addiu	$a0, $a0, 1
					bne	$t0, $0, dim			#Mi chiedo se il valore in $t0 è il null character.
					addiu $a0, $a0, -2			#In $a0 prima della sottrazione e' contenuto l'indirizzo della cella di memoria successiva a quella
												#che contiene il carattere di terminazione della stringa.
					addiu $a1, $a1, -1 			#Sottraggo cio' che c'e' in $a1 poiché successivamente il numero di caratteri significativi
												#della stringa mi tornerà comodo nei confronti.
					add $v0, $a0, $0			#Passo al programma chiamante l'indirizzo della cella di memoria in cui è contenuto l'ultimo carattere
					add $v1, $a1, $0			#significativo e la dimensione significativa della stringa in input.
					jr $ra
					
					
	moltiplicatore:	addi $sp, $sp, -12		#moltiplicatore prevede di usare dei registri da preservare. Se ne fa il riversamento nella pila
					sw $s5, 8($sp)			#aggiornando adeguatamente il puntatore alla stack.
					sw $s6, 4($sp)
					sw $s0, 0($sp)
					add $v0, $0, $0			#Inizializzo $v0.
					la $s0, tabella_indirizzi
					sltiu $t0, $a1, 2
					beq $t0, $0, peso_default	#Si passa alla procedura peso_default se il peso della cifra attuale e' >= 2.
					sll $t0, $a1, 2			#Per regolare il caso in cui il peso e' 1 oppure 2 usiamo un costrutto case-switch
					addu $t0, $s0, $t0		#servendoci di una tabella degli indirizzi di salto. Moltiplico l'indice ($t0) per 4 e
					lw $s5, 0($t0)			#sommo il risultato alla base per ottenere l'indirizzo corretto.
					jr $s5					#Chiamata a sottoprogramma usando una modalità di indirizzamento tramite registro.
				prodotto:
					multu $a0, $v0			#Prodotto tra la cifra binaria e il peso determinato in base alla sua posizione.
					mflo $v0				#Copio il risultato in $v0.
					lw $s0, 0($sp)			#Recupero le informazioni salvate nella pila.
					lw $s6, 4($sp)
					lw $s5, 8($sp)
					addi $sp, $sp, 12
					jr $ra					#Torno al programma chiamante.
	
	conversione:	addi $sp, $sp, -12	 	
					sw $ra, 8($sp)
					sw $s0, 4($sp)
					sw $s1, 0($sp)
					add $s0, $0, $a3		#Copio in in $s0 il valore della base che sarà la potenza di partenza. 
					add $s1, $0, $0			#Inizializzo $s1 e $t1.
					add $t1, $0, $0			#*
			loop2:	sltu $t0, $a0, $s0		#Voglio trovare la potenza di 10 appena > di cio' che c'e' in $a0 in modo tale dividerlo per la potenza appena <.
					bne $t0, $0, avanti		#Dopo la divisione avro' la cifra decimale che è coefficiente del fattore di scala (la potenza per cui ho diviso).
					sltiu $t0, $a1, 31		#2^30 è circa 10^9, il massimo divisore: non riesco a rappresentare 10^10
					addi $t1, $t1, 1
					sltiu $t0, $t1, 9		#moltiplico per 10 partendo da 10, arrivo a 10^9 alla 9a iterazione.
					beq $t0, $0, avanti2
					multu $s0, $a3
					mflo $s0
					j loop2
			avanti:	divu $s0, $a3
					mflo $s0
			avanti2:divu $a0, $s0			#NB se $t0 = 9 e non ho ancora trovato la potenza appena > significa che ho gia' il divisore.
					mflo $s1				#In tutti i casi qui divido per la potenza appena <.
					addi $sp, $sp, -4		#Riverso $a0 nella stack perche' mi servira' anche dopo e questo, per convenzione, non è un registro che
					sw $a0, 0($sp)			#il programma chiamato deve preservare.
					add $a0, $s1, $0		#Passo il parametro necessario alla procedura ASCIIconv.
					jal ASCIIconv
					lw $a0, 0($sp)
					addi $sp, $sp, 4
					sb $v0, 0($a2)			#Carico nell'area di memoria designata il carattere ASCII della cifra decimale.
					multu $s0, $s1			#Moltiplico la cifra decimale per il suo fattore di scala determinato dalla sua posizione.
					mflo $t1				#subu $a0 - $s1 * $s0
					subu $a0, $a0, $t1
					addiu $a2, $a2, 1		#L'indirizzo dell'area output punta al nuovo byte "vuoto".
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
	peso0:			addi $v0, $0, 1				#b^0 = 1
					j prodotto
	peso1:			addi $v0, $0, 2				#b^1 = b
					j prodotto
	peso_default:	addi $v0, $0, 2				#Qui si parte con 
					addi $t0, $0, 1 
					exp:	addu $v0, $v0, $v0 #con add sarebbe scattato l'overflow
							addi $t0, $t0, 1
							bne $t0, $a1, exp
							j prodotto

#*la conversione da base 2 a base 10 prevede dividere il numero binario per la potenza di 10 minore a quella immediatamente maggiore del numero binario.
#Il quoziente della divisione è il coefficiente decimale di peso corrispondente a quella potenza. Quindi si sottrae al numero binario iniziale il
#prodotto tra il coefficiente e la potenza di 10 per cui abbiamo diviso. Rifacciamo il procedimento col risultato e terminiamo quando il risultato
#della differenza è 0.
				
				#avrei potuto anche shiftare gli 1 di uno shit amount dipendente dal loro peso e poi sommare, soluzione sicuramente più elegante