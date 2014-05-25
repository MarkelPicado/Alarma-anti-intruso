---------------------
--  au_setup.vhd
---------------------
--	Configura el codec de la placa DE2 para trabajar en modo master,
--	frecuencia de muestreo de 8132.02 Hz, entrada MIC o LINEIN,
-- salida LINEOUT, formato "justificado a izquierda"
-------------------------------------------------------
--	Andoni Arruti
--  26/01/2011
--------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY au_setup IS 
	port
	(
		reset		   :  IN STD_LOGIC;
		clk_50 		:  IN STD_LOGIC;
		mic_lin		:  IN STD_LOGIC; -- si '1' MIC, si '0' LINEIN
		i2c_sdat	   :  INOUT STD_LOGIC;
		i2c_sclk	   :  OUT STD_LOGIC;
		aud_xck		:  OUT STD_LOGIC
	);
END au_setup;

ARCHITECTURE a OF au_setup IS
-- estados presente y siguiente de UC
	TYPE estado is (e0, e1, e2, e3, e4, e5);
	SIGNAL ep, es	: estado;
-- contador de bits
	SIGNAL cbits 	: integer range 0 to 24;
	SIGNAL incbits	: STD_LOGIC;
	SIGNAL clbits	: STD_LOGIC;
	SIGNAL bit24	: STD_LOGIC;
	SIGNAL stop		: STD_LOGIC;
-- contador de direcciones
	constant LADDR : integer:=6;
	SIGNAL caddr 	: integer range 0 to LADDR;
	SIGNAL incaddr	: STD_LOGIC;
	SIGNAL claddr	: STD_LOGIC;
	SIGNAL lastaddr	: STD_LOGIC;
-- contador de tiempo
	SIGNAL ctmp 	: integer range 0 to 255;
	SIGNAL inctmp	: STD_LOGIC;
	SIGNAL settmp	: STD_LOGIC;
	SIGNAL up		: STD_LOGIC;
	SIGNAL down		: STD_LOGIC;
-- bit de datos -------------------------
	SIGNAL dbit		: STD_LOGIC;
	SIGNAL ldbit	: STD_LOGIC;
	SIGNAL setbit0	: STD_LOGIC;
	SIGNAL setbit1	: STD_LOGIC;
	SIGNAL setbitz	: STD_LOGIC;
-- datos de configuraci�n -------------------------
	SIGNAL dato	: STD_LOGIC_VECTOR(0 to 23);
-- contador divisor de reloj /4 -------------------------
	SIGNAL cclkdiv	: integer range 0 to 3;
BEGIN
-- datos de configuraci�n -------------------------
-- configuraci�n para entrada por LINEIN
	dato(0 to 7) <= "00110100";	-- direcci�n del CODEC para escritura
	PROCESS (caddr)
	BEGIN
		CASE caddr IS
			WHEN 0 => 
--				IF mic_lin = '1' THEN
--					  dato(8 to 23) <= x"0C61";	-- power down: LINEIN, OSCPD, CLKOUTPD
--				ELSE
--					  dato(8 to 23) <= x"0C62";	-- power down: MIC, OSCPD, CLKOUTPD
--				END IF;
					  dato(8 to 23) <= x"0C00";	-- power down: deshabilitado
			WHEN 1 => dato(8 to 23) <= x"0E41";	-- master, 16 bits, formato justificado izquierda
			WHEN 2 => dato(8 to 23) <= x"100C";	-- 8 KHz, si clk de 12'288 MHz (12'5 MHz -> 8'138 KHz)
			WHEN 3 => 
				IF mic_lin = '1' THEN
					  dato(8 to 23) <= x"0814";	-- entrada MIC, salida DAC
				ELSE
					  dato(8 to 23) <= x"0810";	-- entrada LINEIN, salida DAC
				END IF;
			WHEN 4 => dato(8 to 23) <= x"057F";	-- volumen Lout y Rout
			WHEN 5 => dato(8 to 23) <= x"0117";	-- volumen Lin y Rin
			WHEN LADDR => dato(8 to 23) <= x"1201";	-- activaci�n
		END CASE;
	END PROCESS;
-- ==================================================
-- Unidad de control
-- calculo de estado siguiente -------------------------
	P_ES: PROCESS (ep, down, up, stop, bit24, lastaddr, i2c_sdat)
	BEGIN
		CASE ep IS
			WHEN e0 =>
				IF down='1'				  	THEN	es <= e1;
				ELSE								es <= e0;
				END IF;
			WHEN e1 =>
				IF down='1' AND stop='1' 	THEN	es <= e2;
				ELSE								es <= e1;
				END IF;
			WHEN e2 =>
				IF up='0' 					THEN	es <= e2;
				ELSIF i2c_sdat='1'			THEN	es <= e0;
				ELSE								es <= e3;
				END IF;
			WHEN e3 =>
				IF down='0'					THEN	es <= e3;
				ELSIF bit24='0'				THEN	es <= e1;
				ELSE								es <= e4;
				END IF;
			WHEN e4 =>
				IF down='0'					THEN	es <= e4;
				ELSIF lastaddr='0'			THEN	es <= e0;
				ELSE								es <= e5;
				END IF;
			WHEN e5 =>
													es <= e5;
		END CASE;
	END PROCESS P_ES;
-- almacenamiento de estado presente --------------
	P_EP: PROCESS (clk_50, reset)
	BEGIN
		IF (reset='1') THEN
			ep <= e0;
		ELSIF (clk_50'EVENT AND clk_50='1') THEN
			ep <= es;
		END IF;
	END PROCESS P_EP;
-- se�ales de control --------------------------------
	inctmp		<= '0' WHEN ep=e5 				ELSE '1';
	settmp		<= '1' WHEN (ep=e0 AND down='1')
						 OR (ep=e2 AND up='1' AND i2c_sdat='1')
						 OR (ep=e4 AND down='1' AND lastaddr='0')	ELSE '0';
	setbit0		<= '1' WHEN (ep=e0 AND down='1')
						 OR (ep=e3 AND down='1' AND bit24='1')	ELSE '0';
	setbit1		<= '1' WHEN (ep=e4 AND down='1')	ELSE '0';
	setbitz		<= '1' WHEN (ep=e2 OR ep=e3)	ELSE '0';
	ldbit		<= '1' WHEN (ep=e1 AND down='1' AND stop='0')
						 OR (ep=e3 AND down='1' AND bit24='0')	ELSE '0';
	incbits		<= '1' WHEN (ep=e1 AND down='1' AND stop='0')
						 OR (ep=e3 AND down='1' AND bit24='0')	ELSE '0';
	clbits		<= '1' WHEN (ep=e2 AND up='1' AND i2c_sdat='1')
						 OR (ep=e4 AND down='1' AND lastaddr='0')	ELSE '0';
	claddr		<= '1' WHEN (ep=e2 AND up='1' AND i2c_sdat='1')
						 OR (ep=e4 AND down='1' AND lastaddr='0')	ELSE '0';
	incaddr		<= '1' WHEN (ep=e4 AND down='1' AND lastaddr='0')	ELSE '0';
-- ==================================================
-- Unidad de proceso
-- contador de bits -------------------------
	PROCESS (clk_50, reset)
	BEGIN
		IF (reset='1') THEN
			cbits <= 0;
		ELSIF (clk_50'EVENT AND clk_50='1') THEN
			IF (incbits='1') THEN
				cbits <= cbits + 1;
			ELSIF (clbits='1') THEN
				cbits <= 0;
			END IF;
		END IF;
	END PROCESS;
	stop <= '1' WHEN cbits=8 OR cbits=16 OR cbits=24	ELSE '0';
	bit24 <= '1' WHEN cbits=24		ELSE '0';
-- contador de direcciones -------------------------
	PROCESS (clk_50, reset)
	BEGIN
		IF (reset='1') THEN
			caddr <= 0;
		ELSIF (clk_50'EVENT AND clk_50='1') THEN
			IF (incaddr='1') THEN
				caddr <= caddr + 1;
			ELSIF (claddr='1') THEN
				caddr <= 0;
			END IF;
		END IF;
	END PROCESS;
	lastaddr <= '1' WHEN caddr=LADDR		ELSE '0';
-- contador de tiempo -------------------------
	PROCESS (clk_50, reset)
	BEGIN
		IF (reset='1') THEN
			ctmp <= 128;
		ELSIF (clk_50'EVENT AND clk_50='1') THEN
			IF (settmp='1') THEN
				ctmp <= 128;
			ELSIF (inctmp='1') THEN
				ctmp <= ctmp + 1;
			END IF;
		END IF;
	END PROCESS;
	up <= '1' WHEN ctmp=127			ELSE '0';
	down <= '1' WHEN ctmp=255		ELSE '0';
	i2c_sclk <= '1' WHEN ctmp>127	ELSE '0';
-- bit de datos -------------------------
	PROCESS (clk_50, reset)
	BEGIN
		IF (reset='1') THEN
			i2c_sdat <= '1';
		ELSIF (clk_50'EVENT AND clk_50='1') THEN
			IF (ldbit='1') THEN
				i2c_sdat <= dbit;
			ELSIF (setbit0='1') THEN
				i2c_sdat <= '0';
			ELSIF (setbit1='1') THEN
				i2c_sdat <= '1';
			ELSIF (setbitz='1') THEN
				i2c_sdat <= 'Z';
			END IF;
		END IF;
	END PROCESS;
	dbit <= dato(cbits);
-- contador divisor de reloj /4 -------------------------
	PROCESS (clk_50, reset)
	BEGIN
		IF (reset='1') THEN
			cclkdiv <= 0;
		ELSIF (clk_50'EVENT AND clk_50='1') THEN
			cclkdiv <= cclkdiv + 1;
		END IF;
	END PROCESS;
	aud_xck <= '1' WHEN cclkdiv>1	ELSE '0';
END a;