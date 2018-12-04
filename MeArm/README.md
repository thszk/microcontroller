	 __  __         _                      ____            _             _ 
	|  \/  | ___   / \   _ __ _ __ ___    / ___|___  _ __ | |_ _ __ ___ | |
	| |\/| |/ _ \ / _ \ | '__| '_ ` _ \  | |   / _ \| '_ \| __| '__/ _ \| |
	| |  | |  __// ___ \| |  | | | | | | | |__| (_) | | | | |_| | | (_) | |
	|_|  |_|\___/_/   \_\_|  |_| |_| |_|  \____\___/|_| |_|\__|_|  \___/|_|
	         __           			     	               __
	 _(\    |@@|					           _  |@@|
	(__/\__ \--/ __					          / \ \--/ __
	   \___|----|  |   __					  ) O|----|  |   __
	       \ }{ /\ )_ / _\					 / / \ }{ /\ )_ / _\
	       /\__/\ \__O (__					 )/  /\__/\ \__O (__
	      (--/\--)    \__/					|/  (--/\--)    \__/
	      _)(  )(_					        /   _)(  )(_
	     `---''---`					           `---''---`

	Firmware para controle do braço robótico -me arm- através do microcontrolador 8052.

	O controle é feito de duas formas: fisicamente através de potenciômetros, ou via comunicação serial.
	
	A variação do servo motor é de 0º ~ 180º, sendo:
	- Potenciômetro:
	baixa impedância - move para 180º
	alta impedância - move para 0º
	
 	- Serial: 
 	'd' -  direita
	'n' -  neutro
 	'e' -  esquerda
		  
 	'f' -  frente
	'i' -  intermediario			  
 	't' -  tras
			  
 	'a' -  abaixa
	'm' -  meio
 	'l' -  levanta
			  
	'o' - abre a garra
	'c' - fecha a garra

	Por default ao iniciar o programa, o robô é controlado físicamente via potenciômetro, para alterar:
	'x' - controlado por potênciometro
	'q' - controlado por serial
	
	Largura de pulso no servo:
	2.7% -> 0º
	7.3%   -> 90º
	12%  -> 180º
	
	Posicionamento dos motores:
	motor 1: base - direita/esquerda
	motor 2: corpo - sobe/desce
	motor 3: corpo - frente/tras
	motor 4: garra - abre/fecha
