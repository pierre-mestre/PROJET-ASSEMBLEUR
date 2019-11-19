; M. Akil, T. Grandpierre, R. Kachouri : département IT - ESIEE Paris -
; 01/2013 - Evalbot (Cortex M3 de Texas Instrument)
; programme - Pilotage 2 Moteurs Evalbot par PWM tout en ASM (Evalbot tourne sur lui même)



		AREA    |.text|, CODE, READONLY
		ENTRY
		EXPORT	__main
		
		;; The IMPORT command specifies that a symbol is defined in a shared object at runtime.
		IMPORT	MOTEUR_INIT					; initialise les moteurs (configure les pwms + GPIO)
		
		IMPORT	MOTEUR_DROIT_ON				; activer le moteur droit
		IMPORT  MOTEUR_DROIT_OFF			; déactiver le moteur droit
		IMPORT  MOTEUR_DROIT_AVANT			; moteur droit tourne vers l'avant
		IMPORT  MOTEUR_DROIT_ARRIERE		; moteur droit tourne vers l'arrière
		IMPORT  MOTEUR_DROIT_INVERSE		; inverse le sens de rotation du moteur droit
		
		IMPORT	MOTEUR_GAUCHE_ON			; activer le moteur gauche
		IMPORT  MOTEUR_GAUCHE_OFF			; déactiver le moteur gauche
		IMPORT  MOTEUR_GAUCHE_AVANT			; moteur gauche tourne vers l'avant
		IMPORT  MOTEUR_GAUCHE_ARRIERE		; moteur gauche tourne vers l'arrière
		IMPORT  MOTEUR_GAUCHE_INVERSE		; inverse le sens de rotation du moteur gauche
SYSCTL_PERIPH_GPIOF EQU		0x400FE108

; The GPIODATA register is the data register
; GPIO Port F (APB) base: 0x4002.5000 (p416 datasheet de ;lm3s9B92.pdf

GPIO_PORTF_BASE		EQU		0x40025000
GPIO_PORTE_BASE		EQU		0x40024000


; configure the corresponding pin to be an output
; all GPIO pins are inputs by default
; GPIO Direction (p417 datasheet de lm3s9B92.pdf

GPIO_O_DIR   		EQU 	0x400

; The GPIODR2R register is the 2-mA drive control register
; By default, all GPIO pins have 2-mA drive.
; GPIO 2-mA Drive Select (p428 datasheet de lm3s9B92.pdf)

GPIO_O_DR2R   		EQU 	0x500  

; Digital enable register
; To use the pin as a digital input or output, the ;corresponding GPIODEN bit must be set.
; GPIO Digital Enable (p437 datasheet de lm3s9B92.pdf)

GPIO_O_DEN   		EQU 	0x51C  

; Registre pour activer les switchs  en logiciel (par défaut ;ils sont reliés à la masse donc inactifs)

GPIO_PUR			EQU		0x510

; Port select - LED1 et LED2 sur la ligne 4 et 5 du port F

PORT45              EQU		0x30

; Port select - LED 2 sur la ligne 5 du port F

PORT5               EQU     0x20

; Port select - LED 1 sur la ligne 4 du port F

PORT4				EQU		0x10

; PORT E : selection des BUMPER GAUCHE et DROIT,LIGNE 01 du Port E

PORT01				EQU		0x03

; PORT E : selection du BUMPER DROIT, LIGNE 0 du Port E

PORT0				EQU		0x01

; PORT E : selection du BUMPER DROIT, LIGNE 1 du Port E

PORT1               EQU     0x02

; Instruction : aucune LED allumée

NOL2D				EQU		0x00

; Instruction : LED 1 allumée, ligne 4, du port F

LED1				EQU		0x10

; blinking frequency, non utile dans ce programme

DUREE   			EQU     0x002FFFFF	

	  	
		EXPORT	__main

__main	
  	mov r0, #0x00000038  				
		ldr r6, = SYSCTL_PERIPH_GPIOF  		

	      str r0, [r6]

;"There must be a delay of 3 system clocks before any GPIO reg. access  (p413 datasheet de lm3s9B92.pdf)
;tres tres important....;; pas necessaire en simu ou en debbug ;step by step...

		nop	   									
		nop	   
		nop	   									
	
; CONFIGURATION LED

        	ldr r6, = GPIO_PORTF_BASE+GPIO_O_DIR    

; une broche (Pin) du portF en sortie (broche 4 et 5 : 00110000)

		ldr r0, = PORT45	
        	str r0, [r6]
		;ldr r0, = PORT5
		    ;str r0, [r8]  ; r8 contient sortie du PORT5

; Enable Digital Function 	

        	ldr r6, = GPIO_PORTF_BASE+GPIO_O_DEN	
        	ldr r0, = PORT45 		
        	str r0, [r6]
			
; Choix de l'intensité de sortie (2mA)	

		ldr r6, = GPIO_PORTF_BASE+GPIO_O_DR2R	
        	ldr r0, = PORT45		
		str r0, [r6]
		
; pour eteindre LED

 		;mov r2, #0x000           

; Enable Digital Function - Port E

		ldr r7, = GPIO_PORTE_BASE+GPIO_O_DEN	
        	ldr r0, = PORT01		
        	str r0, [r7]	

; Activer le registre des bumpers, Port E

		ldr r7, = GPIO_PORTE_BASE+GPIO_PUR	
        	ldr r0, = PORT01
        	str r0, [r7]

		;; BL Branchement vers un lien (sous programme)

		; Configure les PWM + GPIO
		BL	MOTEUR_INIT	   		   
		
		; Activer les deux moteurs droit et gauche
		BL	MOTEUR_DROIT_OFF
		BL	MOTEUR_GAUCHE_OFF

		; Boucle de pilotage des 2 Moteurs (Evalbot tourne sur lui même)
loop	

			; Evalbot avance droit devant
				; Avancement pendant une période (deux WAIT)
		mov r3, #PORT45       				
		ldr r6, = GPIO_PORTF_BASE + (PORT45<<2)
		
;lecture de l'état du BUMPER DROIT

			ldr r7,= GPIO_PORTE_BASE + (PORT0<<2)
			ldr r5, [r7]
 
;lecture de l'état du BUMPER GAUCHE

            ldr r9, =  GPIO_PORTE_BASE + (PORT1<<2)
			ldr r10, [r9]

;Traitement qui allume/éteint la LED1 et la LED2 en fonction de l'état  ;du SW1, la LED1 est initialement allumée, et s'éteint si SW1 ;est activé = appuyé

;si BUMPER DROIT est actif (=0), on éteint la LED1

			cmp	r5,#0x01          
			bne	noled1
			
;si BUMPER GAUCHE est actif (=0), on éteint la LED2

			cmp r10, #0x02
			bne noled2

			str r3, [r6]          ; allume les leds 1 et 2
			
		
		ldr r1, =0xAFFFFF 	; BL (Branchement vers le lien WAIT); possibilité de retour à la suite avec (BX LR)
		ldr r1, =0xAFFFFF 


		b	loop
noled1		
			BL	MOTEUR_DROIT_ON
			BL	MOTEUR_DROIT_AVANT	
			ldr r6, = GPIO_PORTF_BASE + (PORT4<<2) 
			str r2, [r6]          ; éteint la led 1
			b	loop	
			
;éteindre LED2

noled2      
			BL	MOTEUR_GAUCHE_ON
			BL	MOTEUR_GAUCHE_AVANT	
			ldr r6, = GPIO_PORTF_BASE + (PORT5<<2)
			str r2, [r6]          ; éteint la led 2
            b   loop
			nop		
     		   	END 
		;; Boucle d'attante

wait1	subs r1, #1
        bne wait1
		
		;; retour à la suite du lien de branchement
		BX	LR

		NOP
        END