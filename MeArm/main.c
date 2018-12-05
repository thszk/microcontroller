/*
	 __  __         _                      ____            _             _ 
	|  \/  | ___   / \   _ __ _ __ ___    / ___|___  _ __ | |_ _ __ ___ | |
	| |\/| |/ _ \ / _ \ | '__| '_ ` _ \  | |   / _ \| '_ \| __| '__/ _ \| |
	| |  | |  __// ___ \| |  | | | | | | | |__| (_) | | | | |_| | | (_) | |
	|_|  |_|\___/_/   \_\_|  |_| |_| |_|  \____\___/|_| |_|\__|_|  \___/|_|
*/

//--------------------bibliotecas--------------------
#include<reg52x2.h>
#include <intrins.h>

//--------------------defines--------------------
#define adc_databus P2 //porta de leitura dos dados convertidos pelo ADC
#define PWM_Period 0xB7FE //define periodo de pwm em 20ms

//--------------------definicao de portas--------------------
//pinos de controle ADC0808
sbit adc_A    = P1^0; //selecao dos canais de conversao
sbit adc_B    = P1^1;
sbit adc_ALE  = P1^2; //escolha do canal
sbit adc_Start= P1^3; //inicio da conversao
sbit adc_EOC  = P1^4; //indica final da conversao 0 -->1
sbit adc_OE   = P1^5; //habilitar saidas do conversor

//portas conectadas aos servos
sbit Servo_1 = P3^7;
sbit Servo_2 = P3^6;
sbit Servo_3 = P3^5;
sbit Servo_4 = P3^4;

//--------------------definicao de variaveis--------------------
unsigned char IN0, IN1, IN2, IN3, cvt; //valor convertido dos canais adc
unsigned char op, cmd; //armazena o dado da serial
unsigned int ON_Period, OFF_Period, DutyCycle; //periodo de pwm
int motor = 0; //flag para identificar o servo operado
float PWM_IN0, PWM_IN1, PWM_IN2, PWM_IN3; //dutycycle cada motor 
float vAnt1=7.3; //buffer de pwm para o motor 1

//--------------------definicao de funcoes--------------------
void delay_us(unsigned int us_count);
unsigned char ADC_StartConversion(char channel);
void Timer2_ISR();
void Delay(unsigned int ms);
void Timer0_ISR();
void Set_DutyCycle_To(float duty_cycle);
char UART_RxChar(void);
void Config();
void Controle_Potenciometro();
void Controle_Serial(char cmd);



//--------------------Principal--------------------
void main()
{
	Config(); //configs do programa
	
	Delay(5);

	do
	{ 
		Controle_Potenciometro(); //controla pelo potenciometro

		if(RI == 1) //ve se recebeu cmd da serial
		{
			op = SBUF; //pega o dado recebido
			RI = 0; //libera o canal

			if(op == 'q') //verifica se selecionou cntl pela serial
			{
				while (op != 'x') //fica sendo controlado pela serial ate pedir pra sair
				{
					if(RI == 1) //verifica se recebeu cmd da serial
					{
						op = SBUF; //pega o dado recebido
						RI = 0; //libera o canal

						//faz essa checagem so para evitar de entrar a toa no loop e
						//gastar processamento
						if(op != 'x') Controle_Serial(op);
					}
				}
			}
		}
	}while(1);
}

//--------------------descricao das funcoes--------------------
//--------------------ADC--------------------
//delay para 1us
void delay_us(unsigned int us_count)
{  
	while(us_count!=0)
	{
		us_count--;
	}
}
//faz a conversao no canal infomado no parametro
unsigned char ADC_StartConversion(char channel)
{
	unsigned char adc_result;
	
	//Seleciona o canal
	adc_A=((channel>>0) & 0x01); //desloca para direita 0 bits
	adc_B=((channel>>1) & 0x01); //desloca para direita 1 bits

	adc_ALE=1; //Latch the address by making the ALE high.
	delay_us(50);
	adc_Start=1; //Start the conversion after latching the channel address
	delay_us(25);

	adc_ALE=0; //Pull ALE line to zero after starting the conversion.
	delay_us(50);
	adc_Start=0; //Pull Start line to zero after starting the conversion.

	while(adc_EOC==0); // Wait till the ADC conversion is completed, EOC will be pulled to HIGH by the hardware(ADC0809) once conversion is completed.

	adc_OE=1; //Make the Output Enable high to bring the ADC data to port pins
	delay_us(25);
	adc_result=adc_databus; //Read the ADC data from ADC bus
	adc_OE=0; //After reading the data, disable th ADC output line.

	return(adc_result);
}
//gera clock pro ADC
void Timer2_ISR() interrupt 5
{
	P1_6=~P1_6;
}

//--------------------pwm--------------------
//delay apos pwm
void Delay(unsigned int ms)
{
  unsigned long int us = ms*1000;
  while(us--)
  {
    _nop_();
  }
}
//Timer0 interrupt service routine (ISR)
void Timer0_ISR() interrupt 1
{
	switch(motor)
	{
		case 1:
			Servo_1 = !Servo_1;
			if(Servo_1)
			{
				TH0 = (ON_Period >> 8);
				TL0 = ON_Period;
			}	
			else
			{
				TH0 = (OFF_Period >> 8);
				TL0 = OFF_Period;
			}
		break;

		case 2:
			Servo_2 = !Servo_2;
			if(Servo_2)
			{
				TH0 = (ON_Period >> 8);
				TL0 = ON_Period;
			}
			else
			{
				TH0 = (OFF_Period >> 8);
				TL0 = OFF_Period;
			}
		break;

		case 3:
			Servo_3 = !Servo_3;
			if(Servo_3)
			{
				TH0 = (ON_Period >> 8);
				TL0 = ON_Period;
			}
			else
			{
				TH0 = (OFF_Period >> 8);
				TL0 = OFF_Period;
			}
		break;

		case 4:
			Servo_4 = !Servo_4;
			if(Servo_4)
			{
				TH0 = (ON_Period >> 8);
				TL0 = ON_Period;
			}
			else
			{
				TH0 = (OFF_Period >> 8);
				TL0 = OFF_Period;
			}
		break;
	}
}
//Calculate ON & OFF period from duty cycle
void Set_DutyCycle_To(float duty_cycle)
{
	float period = 65535 - PWM_Period;
	ON_Period = ((period/100.0) * duty_cycle);
	OFF_Period = (period - ON_Period);	
	ON_Period = 65535 - ON_Period;	
	OFF_Period = 65535 - OFF_Period;
}

//--------------------serial--------------------NO MOMENTO NAO USO ESSA FUNCAO
/*char UART_RxChar(void)
{
    while(RI==0);     // Wait till the data is received
    RI=0;             // Clear Receive Interrupt Flag for next cycle
    return(SBUF);     // return the received char
}*/

//--------------------config gerais--------------------
void Config()
{
	//config adc
	adc_Start=0; //Initialize all the control lines to zero.
	adc_ALE=0;
	adc_OE=0;
	adc_EOC=1; //Configure the EOC pin as INPUT
	adc_databus=0xff; //configure adc_databus as input

	//config timer
	TMOD = 0x21; //Timer0(PWM) mode1 e Timer1(serial) in Mode2

	//config pwm
	TH0 = (PWM_Period >> 8); //20ms timer value
	TL0 = PWM_Period;
	TR0 = 1; //Start timer0

	//config serial
	SCON = 0x50; //Asynchronous mode, 8-bit data and 1-stop bit
	TH1 = 0xFD; //9600 baudrate
	TR1 = 1; //Turn ON the timer for Baud rate generation

	//configurando interrupcoes
	ES = 1; //interrupcao da serial
	EA  = 1; //Atendendo interrupcao
	EX0 = 1; //Habilitando externa 0
	EX1 = 1; //Habilitano externa 1
	ET0 = 1; //Enable timer0 interrupt
	IT1 = 1; // sensivel por borda
	IT0 = 1; // sensivel por borda

	//utilizando o timer 2
	T2MOD=0X00;
	T2CON=0X00;
	RCAP2L=0X00;
	RCAP2H=0X4D;
	TL2=0X00;
	TH2=0X9B;
	ET2=1;
	TR2 = 1;
}

//--------------------controle--------------------
void Controle_Potenciometro()
{	
	//faz a conversao de cada canal e colocando num temporario cvt
	//armazena o valor anterior nas variaveis IN0, IN1, IN2, IN3 e verifica se foi alterado
	//assim evita gastar processamento a toa gerando pwm quando nao deu comando para mover
	
	//canal 0 - motor 1
	cvt = ADC_StartConversion(0); //faz a conversao
	if(IN0 != cvt) //ve se o valor anterior eh diferente do atual
	{
		IN0 = cvt; //salva o valor atual
		motor = 1; //seleciona o motor pra operar
		PWM_IN0 = ((IN0*9.3)/255)+2.7; //calcula o duty cycle
		Set_DutyCycle_To(PWM_IN0); //gera pwm
		Delay(10);
	}

	//canal 1 - motor 2
	cvt = ADC_StartConversion(1);
	if(IN1 != cvt)
	{
		IN1 = cvt;
		motor = 2;
		PWM_IN1 = ((IN1*9.3)/255)+2.7;
		Set_DutyCycle_To(PWM_IN1);
		Delay(10);
	}
	
	//canal 2 - motor 3
	cvt = ADC_StartConversion(2);
	if(IN2 != cvt)
	{
		IN2 = cvt;
		motor = 3;
		PWM_IN2 = ((IN2*9.3)/255)+2.7;
		Set_DutyCycle_To(PWM_IN2);
		Delay(10);
	} 
	
	//canal 3 - motor 4
	cvt = ADC_StartConversion(3);
	if(IN3 != cvt)
	{	
		IN3 = cvt;
		motor = 4;
		PWM_IN3 = ((cvt*9.3)/255)+2.7;
		Set_DutyCycle_To(PWM_IN3);
		Delay(10);
	}
}

void Controle_Serial(char cmd)
{
	switch(cmd)
	{
		case 'o': //abre a garra
			motor = 4;
			Set_DutyCycle_To(2.7);//0º
			Delay(10);
		break;
		case 'c': //fecha a garra
			motor = 4;
			Set_DutyCycle_To(4.755);//aprox. 10º | na pratica funciona, porem na simulacao nao move o motor
			Delay(10);
		break;
		
		case 't': //para tras
			motor = 3;
			Set_DutyCycle_To(2.7);//0º
			Delay(10);
		break;
		case 'i': //intermediario
			motor = 3;
			Set_DutyCycle_To(4.9);
			Delay(10);
		break;
		case 'f': //frente
			motor = 3;
			Set_DutyCycle_To(8.7);//aprox <160º
			Delay(10);
		break;
		
		case 'l': //levanta
			motor = 2;
			Set_DutyCycle_To(9.2);// <180º
			Delay(10);
		break;
		case 'a': //abaixa
			motor = 2;
			Set_DutyCycle_To(2.7);//0º
			Delay(10);
		break;
		case 'm': //meio
			motor = 2;
			Set_DutyCycle_To(6.5);
			Delay(10);
		break;
		
		case 'd': //um pouco pra direita
			vAnt1 = vAnt1 + 0.6;
			motor = 1;
			Set_DutyCycle_To(vAnt1);
			Delay(10);
		break;
		case 'e': //um pouco pra esquerda
			vAnt1 = vAnt1 - 0.6;
			motor = 1;
			Set_DutyCycle_To(vAnt1);
			Delay(10);
		break;
		case 'n': //neutro - garra para frente
			motor = 1;
			Set_DutyCycle_To(7.3);
			Delay(10);
		break;

		default:
		break;
	}
}