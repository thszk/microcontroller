;*************************************************************************************************
;																								 *
;					PROJETO: PWM - Controlado por dip-switch e serial    						 *
;																								 *
;*************************************************************************************************
;
; -> Projeto para criar diferentes pulsos de PWM a partir de uma selecao via dip-switch, tendo a
;    possibilidade de aumentar ou diminuir esse valor a partir de comandos enviados via serial.
;
;	|----------------------------------|
;	|      Combinacoes dip-switch      |		
;	|----------------------------------|
;	|Entrada		Periodo			PWM|
;	|001			40ms			10%|
;	|010			40ms			25%|
;	|011			40ms			75%|
;	|101			80ms			10%|
;	|110			80ms			30%|
;	|111			80ms			80%|
;	|----------------------------------|
;
; -> bits de entrada definidos no port P2 sendo P2.4(msb) P2.5 P2.6
; -> para definicao do perido do pwm eh preciso fazer o calculo 65535 - periodo(alta/baixo)
;
; -> atraves da comunicacao serial eh possivel enviar os caracteres 'a', 'd' ou 'm' ao MCU para aplicar os comandos:
;    'a' - aumenta o sinal do pwm em + 5% do selecionado via dip-switch
;    'd' - diminui o sinal do pwm em - 5% do selecionado via dip-switch
;    'm' - retorna ao menu de leitura do dip-switch
;
;
; -> uso dos registradores:
;    R0 controla o tempo de PWM
;    R1 armazena a parte alta do periodo on do PWM
;    R2 armazena a parte baixa do periodo on do PWM
;    R3 armazena a parte alta do periodo of do PWM
;    R4 armazena a parte baixa do periodo of do PWM


;definindo pinagem do MCU
SAIDA		EQU				P3.2				;Saida do PWM
saida_inv	equ				P3.3				;Saida do PWM invertido
dip 		equ 			P2 					;entrada do dip-switch

			ORG				0000H
			jmp				INICIO
			ORG				0040H

;configuracao timer 0 e da serial
INICIO:
			CLR 			SM0					;|
			SETB 			SM1					;| coloca serial em 8bits UART mode
			MOV				TMOD,#21H			;| coloca timer 0 configurado no modo 1 (16 bits)
												;| coloca timer 1 em 8-bit e recarga automatica
			MOV				TCON,#00H			; TIMER DESLIGADO
			MOV 			TH1,#0FDH			;|
			MOV 			TL1,#0FDH			;| boud rate de 9600
			SETB 			TR1					; start timer 1
			SETB 			REN					; enable read mode
;fim configuracao


;loop principal
le:
			MOV				A,dip				; Le dipswitch
			ORL				A,#10001111B		; mascara para os bits que interessam, p2.6 p2.5 p2.4
;a0				
			CJNE			A,#11001111B,a1 	; 001

			MOV				R0,#200				; tempo de PWM 
			MOV 			r1,#0F0H			;| periodo 40ms
			MOV 			r2,#05FH			;| 10% on
			MOV 			r3,#073H			;|
			MOV 			r4,#05FH			;| 90% of

			jmp				dez_pc_40ms
a1:
			CJNE			A,#10101111B,a2 	; 010
			
			MOV				R0,#200				; tempo de PWM
			mov 			r1,#0D8H			;| periodo 40ms
			mov 			r2,#0EFH			;| 25% on
			mov 			r3,#08AH			;|
			mov 			r4,#0CFH			;| 75% of

			jmp				vinte_cinco_pc_40ms
a2:
			CJNE			A,#11101111B,a3 	; 011

			MOV				R0,#200				; tempo de PWM
			mov 			r1,#08AH			;| periodo 40ms
			mov 			r2,#0CFH			;| 25% on
			mov 			r3,#0D8H			;|
			mov 			r4,#0EFH			;| 75% of

			jmp				setenta_cinco_pc_40ms
a3:
			CJNE			A,#11011111B,a4		; 101

			MOV				R0,#200				; tempo de PWM
			mov 			r1,#0E0H 			;| periodo 80ms
			mov 			r2,#0BFH 			;| 10% on
			mov 			r3,#073H 			;|
			mov 			r4,#05FH 			;| 90% of

			jmp				dez_pc_80ms
a4:
			CJNE			A,#10111111B,a5		; 110
			
			MOV				R0,#100				; tempo de PWM
			mov 			r1,#0A2H 			;| periodo 80ms
			mov 			r2,#03FH 			;| 30% on
			mov 			r3,#025H 			;|
			mov 			r4,#03FH 			;| 70% of

			jmp				trinta_pc_80ms
a5:
			CJNE			A,#11111111B,le 	; 111

			MOV				R0,#200				; tempo de PWM
			mov 			r1,#005H 			;| periodo 80ms
			mov 			r2,#0FFH 			;| 80% on
			mov 			r3,#0C1H 			;|
			mov 			r4,#07FH 			;| 20% of

			jmp				oitenta_pc_80ms
;fim loop principal


;sub-rotinas para gerar pulsos do pwm

;************************************************************************************************
;*	   10% (HIGH)
;*	                                                 90% (LOW)     
;* periodo 40ms / 40000us
;************************************************************************************************
dez_pc_40ms:
			MOV				TH0,r1				; CARREGA TIMER 0 COM 4ms 10%
			MOV				TL0,r2				; EM ALTO
			SETB			TR0					; LIGA TIMER 0
			SETB			SAIDA				; POE SAIDA EM UM
			CLR				saida_inv

			JNB				TF0,$				; ESPERA OVERFLOW
			CLR				TR0					; DESLIGA TIMER
			CLR				TF0					; ZERA FLAG DE OVERFLOW

			MOV				TH0,r3				; CARREGA TIMER 0 COM 36ms 90%    
			MOV				TL0,r4				; EM baixo  
			SETB			TR0					; LIGA TIMER0
			CLR				SAIDA				; POE SAIDA EM NIVEL ZERO
			setb			saida_inv

			JNB				TF0,$				; ESPERA OVERFLOW DO TIMER
			CLR				TR0					; DESLIGA TIMER
			CLR				TF0					; ZERA FLAG DE OVERFLOR DO TIMER

			DJNZ			R0,dez_pc_40ms		; FAZ ENSTA ONDA POR 5 SEGUNDOS

			call			serial_dez_pc_40ms
			
			jmp				le

;************************************************************************************************
;*	   25% (HIGH)
;*	                                                 75% (LOW)     
;* periodo 40ms / 40000us
;************************************************************************************************
vinte_cinco_pc_40ms:
			MOV				TH0,r1				; CARREGA TIMER 0 COM 10000 us / 10ms / 25%
			MOV				TL0,r2				; EM ALTO
			SETB			TR0					; LIGA TIMER 0
			SETB			SAIDA				; POE SAIDA EM UM
			clr				saida_inv

			JNB				TF0,$				; ESPERA OVERFLOW
			CLR				TR0					; DESLOGA TIMER
			CLR				TF0					; ZERA FLAG DE OVERFLOW

			MOV				TH0,r3 				; CARREGA TIMER 0 COM 30000us / 30ms / 75%
			MOV				TL0,r4 				; EM BAIXO
			SETB			TR0					; LIGA TIMER 0
			CLR				SAIDA				; POE SAIDA EM NIVEL ZERO
			setb			saida_inv

			JNB				TF0,$				; ESPERA OVERFLOW
			CLR				TR0					; DESLIGA TIMER
			CLR				TF0					; ZERA FLAG DE OVERFLOW DO TIMER
			DJNZ			R0,vinte_cinco_pc_40ms

			call			serial_vinte_cinco_pc_40ms
			
			jmp				le

;************************************************************************************************
;*	   75% (HIGH)
;*	                                                 25% (LOW)     
;* periodo 40ms / 40000us
;************************************************************************************************
setenta_cinco_pc_40ms:
			MOV				TH0,r1				; CARREGA TIMER 0 COM 30000us / 30ms / 75%
			MOV				TL0,r2				; EM alta

			SETB			TR0					; LIGA TIMER 0
			SETB 			SAIDA				; COLOCA SAIDA EM um
			CLR				saida_inv

			JNB				TF0,$				; ESPERA OVERFLOW
			CLR				TR0					; DESLIGA TIMER
			CLR				TF0					; ZERA FLAG DE OVERFLOW

			MOV				TH0,r3  	  		; CARREGA TIMER 0  10000us / 10ms / 25%
			MOV				TL0,r4 				; EM BAIXA
			SETB			TR0					; LIGA TIMER
			clr				SAIDA				; COLOCA SAIDA EM zero
			setb			saida_inv

			JNB				TF0,$				; ESPERA OVERFLOW

			CLR				TR0					; DESLIGA TIMER
			CLR				TF0					; ZERA FLAG DE OVERFLOW
			DJNZ			R0,setenta_cinco_pc_40ms

			call			serial_setenta_cinco_pc_40ms

			jmp				le


;************************************************************************************************
;*	   10% (HIGH)
;*	                                                 90% (LOW)     
;* periodo 80ms / 80000us
;************************************************************************************************
dez_pc_80ms:
;parte alta
			MOV				TH0,r1 				; CARREGA TIMER 0 COM 8000us / 8ms / 10%
			MOV				TL0,r2 				; EM alta

			SETB			TR0					; LIGA TIMER 0
			SETB 			SAIDA				; COLOCA SAIDA EM um
			CLR				saida_inv

			JNB				TF0,$				; ESPERA OVERFLOW
			CLR				TR0					; DESLIGA TIMER
			CLR				TF0					; ZERA FLAG DE OVERFLOW

;parte baixa divide o periodo de 90% em dois de 45% e faz 2x o de 45%
;primeira vez
			MOV				TH0,r3 	    		; CARREGA TIMER 0  36000us / 36ms / 45%
			MOV				TL0,r4  			; EM BAIXA
			SETB			TR0					; LIGA TIMER
			clr				SAIDA				; COLOCA SAIDA EM zero
			setb			saida_inv

			JNB				TF0,$				; ESPERA OVERFLOW
			CLR				TR0					; DESLIGA TIMER
			CLR				TF0					; ZERA FLAG DE OVERFLOW
;segunda vez
			MOV				TH0,r3 	    		; CARREGA TIMER 0  36000us / 36ms / 45%
			MOV				TL0,r4  			; EM BAIXA
			SETB			TR0					; LIGA TIMER
			clr				SAIDA				; COLOCA SAIDA EM zero
			setb			saida_inv

			JNB				TF0,$				; ESPERA OVERFLOW
			CLR				TR0					; DESLIGA TIMER
			CLR				TF0					; ZERA FLAG DE OVERFLOW

			DJNZ			R0,dez_pc_80ms

			call 			serial_dez_pc_80ms

			jmp				le

;************************************************************************************************
;*	   30% (HIGH)
;*	                                                 70% (LOW)     
;* periodo 80ms / 80000us
;************************************************************************************************
trinta_pc_80ms:
			MOV				TH0,r1				; CARREGA TIMER 0 COM 24000us / 24ms / 30%
			MOV				TL0,r2				; EM alta

			SETB			TR0					; LIGA TIMER 0
			SETB 			SAIDA				; COLOCA SAIDA EM um
			CLR				saida_inv

			JNB				TF0,$				; ESPERA OVERFLOW
			CLR				TR0					; DESLIGA TIMER
			CLR				TF0					; ZERA FLAG DE OVERFLOW

			MOV				TH0,r3    			; CARREGA TIMER 0  56000us / 56ms / 70%
			MOV				TL0,r4 				; EM BAIXA
			SETB			TR0					; LIGA TIMER
			clr				SAIDA				; COLOCA SAIDA EM zero
			setb			saida_inv

			JNB				TF0,$				; ESPERA OVERFLOW
			CLR				TR0					; DESLIGA TIMER
			CLR				TF0					; ZERA FLAG DE OVERFLOW

			DJNZ			R0,trinta_pc_80ms

			call 			serial_trinta_pc_80ms

			jmp				le

;************************************************************************************************
;*	   80% (HIGH)
;*	                                                 20% (LOW)     
;* periodo 80ms / 80000us
;************************************************************************************************
oitenta_pc_80ms:
			MOV				TH0,r1			; CARREGA TIMER 0 COM 64000us / 64ms / 80%
			MOV				TL0,r2			; EM alta

			SETB			TR0					; LIGA TIMER 0
			SETB 			SAIDA				; COLOCA SAIDA EM um
			CLR				saida_inv

			JNB				TF0,$				; ESPERA OVERFLOW
			CLR				TR0					; DESLIGA TIMER
			CLR				TF0					; ZERA FLAG DE OVERFLOW

			MOV				TH0,r3    		; CARREGA TIMER 0  16000us / 16ms / 20%
			MOV				TL0,r4 			; EM BAIXA
			SETB			TR0					; LIGA TIMER
			clr				SAIDA				; COLOCA SAIDA EM zero
			setb			saida_inv

			JNB				TF0,$				; ESPERA OVERFLOW
			CLR				TR0					; DESLIGA TIMER
			CLR				TF0					; ZERA FLAG DE OVERFLOW

			DJNZ			R0,oitenta_pc_80ms

			call 			serial_oitenta_pc_80ms

			jmp				le
;fim das sub-rotinas de gerar pwm


;sub-rotina da serial
;--------------------------------
;		serial_dez_pc_40ms
;--------------------------------
serial_dez_pc_40ms:
			jnb				ri,$				;aguarda receber cmd pela serial
			mov				a,sbuf				;salva o valor da serial no acc
			clr				ri 					;limpa o flag da serial

			CJNE			a,#6DH,cmp_serial_dez_pc_40ms
			jmp				le 					;se teclar m volta pro menu
cmp_serial_dez_pc_40ms:			
			CJNE			a,#61H,dim_serial_dez_pc_40ms
			
			mov 			r0,#200				; carrega tempo de PWM

			mov 			r1,#0E8h			;|
			mov 			r2,#08Fh			;|parte alta 15%
			mov 			r3,#07Bh			;|
			mov 			r4,#02Fh			;|parte baixa 85%

			jmp				dez_pc_40ms
dim_serial_dez_pc_40ms:
			mov 			r0,#200				; carrega tempo de PWM

			mov 			r1,#0F8h			;|
			mov 			r2,#02Fh			;|parte alta 5%
			mov 			r3,#06Bh			;|
			mov 			r4,#08Fh			;|parte baixa 95%

			jmp				dez_pc_40ms


;--------------------------------
;	serial_vinte_cinco_pc_40ms
;--------------------------------
serial_vinte_cinco_pc_40ms:	
			jnb				ri,$				;aguarda receber cmd pela serial
			mov				a,sbuf				;salva o valor da serial no acc
			clr				ri 					;limpa o flag da serial

			CJNE			a,#6DH,cmp_serial_vinte_cinco_pc_40ms
			jmp				le 					;se teclar m volta pro menu
cmp_serial_vinte_cinco_pc_40ms:
			CJNE			a,#61H,dim_serial_vinte_cinco_pc_40ms
			
			mov 			r0,#200				; carrega tempo de PWM

			mov 			r1,#0D1h			;|
			mov 			r2,#01Fh			;|parte alta 30%
			mov 			r3,#092h			;|
			mov 			r4,#09Fh			;|parte baixa 70%

			jmp				vinte_cinco_pc_40ms
dim_serial_vinte_cinco_pc_40ms:
			mov 			r0,#200				; carrega tempo de PWM

			mov 			r1,#0E0h			;|
			mov 			r2,#0BFh			;|parte alta 20%
			mov 			r3,#082h			;|
			mov 			r4,#0FFh			;|parte baixa 80%

			jmp				vinte_cinco_pc_40ms

;--------------------------------
;	serial_setenta_cinco_pc_40ms
;--------------------------------
serial_setenta_cinco_pc_40ms:	
			jnb				ri,$				;aguarda receber cmd pela serial
			mov				a,sbuf				;salva o valor da serial no acc
			clr				ri 					;limpa o flag da serial

			CJNE			a,#6DH,cmp_serial_setenta_cinco_pc_40ms
			jmp				le 					;se teclar m volta pro menu
cmp_serial_setenta_cinco_pc_40ms:
			CJNE			a,#61H,dim_serial_setenta_cinco_pc_40ms
			
			mov 			r0,#200				; carrega tempo de PWM

			mov 			r1,#082h			;|
			mov 			r2,#0FFh			;|parte alta 80%
			mov 			r3,#0E0h			;|
			mov 			r4,#0BFh			;|parte baixa 20%

			jmp				setenta_cinco_pc_40ms
dim_serial_setenta_cinco_pc_40ms:
			mov 			r0,#200				; carrega tempo de PWM

			mov 			r1,#092h			;|
			mov 			r2,#09Fh			;|parte alta 70%
			mov 			r3,#0D1h			;|
			mov 			r4,#01Fh			;|parte baixa 30%

			jmp				setenta_cinco_pc_40ms


;--------------------------------
;		serial_dez_pc_80ms
;--------------------------------
serial_dez_pc_80ms:	
			jnb				ri,$				;aguarda receber cmd pela serial
			mov				a,sbuf				;salva o valor da serial no acc
			clr				ri 					;limpa o flag da serial

			CJNE			a,#6DH,cmp_serial_dez_pc_80ms
			jmp				le 					;se teclar m volta pro menu
cmp_serial_dez_pc_80ms:
			CJNE			a,#61H,dim_serial_dez_pc_80ms
			
			mov 			r0,#200				; carrega tempo de PWM

			mov 			r1,#0D1h			;|
			mov 			r2,#01Fh			;|parte alta 15%
			mov 			r3,#07Bh			;|
			mov 			r4,#02Fh			;|parte baixa 85%

			jmp				dez_pc_80ms
dim_serial_dez_pc_80ms:
			mov 			r0,#200				; carrega tempo de PWM

			mov 			r1,#0F0h			;|
			mov 			r2,#05Fh			;|parte alta 5%
			mov 			r3,#06Bh			;|
			mov 			r4,#08Fh			;|parte baixa 95%

			jmp				dez_pc_80ms


;--------------------------------
;	serial_trinta_pc_80ms
;--------------------------------
serial_trinta_pc_80ms:	
			jnb				ri,$				;aguarda receber cmd pela serial
			mov				a,sbuf				;salva o valor da serial no acc
			clr				ri 					;limpa o flag da serial

			CJNE			a,#6DH,cmp_serial_trinta_pc_80ms
			jmp				le 					;se teclar m volta pro menu
cmp_serial_trinta_pc_80ms:
			CJNE			a,#61H,dim_serial_trinta_pc_80ms
			
			mov 			r0,#200				; carrega tempo de PWM

			mov 			r1,#092h			;|
			mov 			r2,#09Fh			;|parte alta 35%
			mov 			r3,#034h			;|
			mov 			r4,#0DFh			;|parte baixa 65%

			jmp				trinta_pc_80ms
dim_serial_trinta_pc_80ms:
			mov 			r0,#200				; carrega tempo de PWM

			mov 			r1,#0B1h			;|
			mov 			r2,#0DFh			;|parte alta 25%
			mov 			r3,#015h			;|
			mov 			r4,#09Fh			;|parte baixa 75%

			jmp				trinta_pc_80ms


;--------------------------------
;	serial_oitenta_pc_80ms
;--------------------------------
serial_oitenta_pc_80ms:	
			jnb				ri,$				;aguarda receber cmd pela serial
			mov				a,sbuf				;salva o valor da serial no acc
			clr				ri 					;limpa o flag da serial

			CJNE			a,#6DH,cmp_serial_oitenta_pc_80ms
			jmp				le 					;se teclar m volta pro menu
cmp_serial_oitenta_pc_80ms:
			CJNE			a,#61H,dim_serial_oitenta_pc_80ms
			
			mov 			r0,#200				; carrega tempo de PWM

			;mov 			r1,#092h			;|
			;mov 			r2,#09Fh			;|parte alta 85%
			;mov 			r3,#034h			;|
			;mov 			r4,#0DFh			;|parte baixa 15%

			jmp				oitenta_pc_80ms
dim_serial_oitenta_pc_80ms:
			mov 			r0,#200				; carrega tempo de PWM

			mov 			r1,#015h			;|
			mov 			r2,#09Fh			;|parte alta 75%
			mov 			r3,#0B1h			;|
			mov 			r4,#0DFh			;|parte baixa 25%

			jmp				oitenta_pc_80ms


;fim sub-rotina da serial
