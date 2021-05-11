LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY MAESTRO_FPGA IS

	PORT(
		INI : IN STD_LOGIC;	--Boton para empezar transaccion
		RX : IN STD_LOGIC; -- MISO	
		CLK : IN STD_LOGIC;  --Entrada de reloj de 10MHz
		TX : OUT STD_LOGIC; --MOSI
		SCLK : OUT STD_LOGIC;
		SS : BUFFER STD_LOGIC;	--Chip select/ Slave select
		DISPLAY : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);-- SALIDA AL 7 SEGMENTOS
		DATO_IN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);--Dato de entraa 8 bits
		LOAD : IN STD_LOGIC --Boton para cargar dato a enviar
		--RST : IN STD_LOGIC;
	);


END ENTITY;

ARCHITECTURE ALGO OF MAESTRO_FPGA IS

--Durante inactividad:
	--SCLK se encuentra en estado bajo
	--CS se encuentra en estado alto
	
--Los datos se capturan en FLANCOS DE SUBIDA
--Primero se captura el bit MAS SIGNIFICATIVO

TYPE ESTADOS IS (E0,E1,E2,E3,E4,E5,E6,E7,E8,E9,E10,E11,E12,E13,E14,E15);

SIGNAL AUXCONT : INTEGER RANGE 0 TO 10;	--contador para el divisor de frecuencia

SIGNAL ASM1 : ESTADOS; --ASM CON FLANCOS ASCENDENTES
SIGNAL ASM2 : ESTADOS; --ASM CON FLANCOS DESCENDENTES

SIGNAL DATO :STD_LOGIC_VECTOR(7 downto 0);

SIGNAL ALTCLK : STD_LOGIC;

SIGNAL EN : STD_lOGIC;

SIGNAL HAB: STD_LOGIC;

SIGNAL DATO_TX : STD_LOGIC_VECTOR(7 DOWNTO 0);



BEGIN

	--DIvisor de 10 MHz a 1 MHz
	DIVISOR_FRECUENCIA: 
	PROCESS(CLK)
	BEGIN
		IF RISING_EDGE(CLK) THEN
			IF (AUXCONT = 4) THEN
				AUXCONT <= 0;
				ALTCLK <= NOT ALTCLK;
			ELSE
				AUXCONT <= AUXCONT + 1;
			END IF;
		END IF;
	END PROCESS;
	
	--ASM PRINCIPAL
	ASM: 
	PROCESS(ALTCLK)
	BEGIN
		IF RISING_EDGE(ALTCLK) THEN
		
			--CONTROLA SS Y LA OBTENCION DEL DATO
			CASE ASM1 IS
				
				WHEN E0 =>  SS <= '1'; HAB <= '0'; 
					IF INI = '0' THEN ASM1 <= E1; END IF;
			
				WHEN E1 => SS <= '0'; ASM1 <= E2; HAB <= '1';
				
				WHEN E2 => ASM1 <= E3;
				
				WHEN E3 => DATO(7) <= RX; ASM1 <= E4; 
				
				WHEN E4 => DATO(6) <= RX; ASM1 <= E5;
				
				WHEN E5 => DATO(5) <= RX; ASM1 <= E6;
				
				WHEN E6 => DATO(4) <= RX; ASM1 <= E7;
				
				WHEN E7 => DATO(3) <= RX; ASM1 <= E8;
				
				WHEN E8 => DATO(2) <= RX; ASM1 <= E9;
				
				WHEN E9 => DATO(1) <= RX; ASM1 <= E10;
				
				WHEN E10 => DATO(0) <= RX; ASM1 <= E11; HAB <= '0';
				
				WHEN E11 => SS <= '1'; 
					IF INI = '0' THEN ASM1 <= E11; ELSE ASM1 <= E0; END IF;
			
				WHEN OTHERS => ASM1 <= E0; SS <= '1'; HAB <= '0';
					
					
				
			END CASE;
		
		ELSIF FALLING_EDGE(ALTCLK) THEN
			
			--CONTROLA LA HABILITACION DEL RELOJ SERIAL Y LA TX
			
			CASE ASM2 IS 
				
				WHEN E0 => EN <= '0'; TX <= 'Z';
					IF HAB = '1' THEN ASM2 <= E1; END IF; 
				
				WHEN E1 => TX <= DATO_TX(7); EN <= '1'; ASM2 <= E2; --MSB
				
				WHEN E2 => TX <= DATO_TX(6); ASM2 <= E3;
				
				WHEN E3 => TX <= DATO_TX(5); ASM2 <= E4;
				
				WHEN E4 => TX <= DATO_TX(4); ASM2 <= E5;
				
				WHEN E5 => TX <= DATO_TX(3); ASM2 <= E6; -- BIT 3
				
				WHEN E6 => TX <= DATO_TX(2); ASM2 <= E7; -- BIT 2
				
				WHEN E7 => TX <= DATO_TX(1); ASM2 <= E8;
				
				WHEN E8 => TX <= DATO_TX(0); ASM2 <= E9;--LSB
				
				WHEN E9 => TX <= 'Z'; ASM2 <= E0;
			
				WHEN OTHERS => ASM2 <= E0; EN <= '0'; TX <= 'Z';
		
			END CASE;
			
		
			
		END IF;
		
	END PROCESS;
	
	--Controlador  de reloj (MUX)
	WITH EN SELECT SCLK <= '0' WHEN '0', ALTCLK WHEN '1';
	
	
	--DECODIFICADOR DE 7 SEGMENTOS
	DECODIFICADOR:
	PROCESS(ALTCLK)
	BEGIN
	
	IF RISING_EDGE(ALTCLK) THEN
	
		IF ss = '1' THEN
		CASE DATO IS
			
			WHEN "00110000" => DISPLAY <= NOT "1111110" ;--0
			
			WHEN "00110001" => DISPLAY <= NOT "0110000" ;--1
			
			WHEN "00110010" => DISPLAY <= NOT "1101101" ;--2
			
			WHEN "00110011" => DISPLAY <= NOT "1111001" ;--3
			
			WHEN "00110100" => DISPLAY <= NOT "0110011" ;--4
			
			WHEN "00110101" => DISPLAY <= NOT "1011011" ;--5
			
			WHEN "00110110" => DISPLAY <= NOT "1011111" ;--6
			
			WHEN "00110111" => DISPLAY <= NOT "1110001" ;--7
			
			WHEN "00111000" => DISPLAY <= NOT "1111111" ;--8
			
			WHEN "00111001" => DISPLAY <= NOT "1110011" ;--9
			
			WHEN OTHERS => DISPLAY <= NOT "0000000"; --DEFAULT NO MUESTRA NADA

		END CASE;
		END IF;
	END IF;
	END PROCESS;
	
	
	-- 'Comando a enviar' cargado desde los switches de la tarjeta
	
	CARGAR_DATO:
	PROCESS(ALTCLK)
	BEGIN
	
		IF RISING_EDGE(ALTCLK) THEN
			
			IF LOAD = '0' THEN
				DATO_TX <= DATO_IN;
			END IF;
		END IF;
	END PROCESS;
	

	
	
	


END ALGO;