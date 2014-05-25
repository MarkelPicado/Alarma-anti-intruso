---------------------
--  au_out.vhd
---------------------
--	envia una muestra de 16 bits al codec por la linea serie
--	Se supone que el codec está configurado para trabajar en modo master,
--  y con formato "justificado a izquierda"
--	Se envia la misma muestra por los dos canales
-------------------------------------------------------
--	Andoni Arruti
--  30/10/2011
--------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY au_out IS
	PORT (
		clk, reset		: IN	STD_LOGIC;
		daclrc			: IN	STD_LOGIC;
		bclk			: IN	STD_LOGIC;
		sampleout		: IN	STD_LOGIC_VECTOR(15 DOWNTO 0);
		dacdat			: OUT	STD_LOGIC;
		outready		: OUT	STD_LOGIC
	);
END au_out;

ARCHITECTURE a OF au_out IS
-- estados presente y siguiente de UC
	TYPE estado is (e0, e1, e2, e3, e4, e5, e6);
	SIGNAL ep, es	: estado;
-- registro de desplazamiento
	SIGNAL srdato 	: STD_LOGIC_VECTOR(16 DOWNTO 0);
	SIGNAL lddato	: STD_LOGIC;
	SIGNAL desplaza	: STD_LOGIC;
-- contador de bits
	SIGNAL cbits 	: integer range 0 to 15;
	SIGNAL incbits	: STD_LOGIC;
	SIGNAL ultimo	: STD_LOGIC;
-- entradas sincronizadas 
	SIGNAL daclrcs	: STD_LOGIC;
	SIGNAL bclks	: STD_LOGIC;
	
BEGIN
-- ==================================================
-- Unidad de control
-- calculo de estado siguiente -------------------------
	P_ES: PROCESS (ep, daclrcs, bclks, ultimo)
	BEGIN
		CASE ep IS
			WHEN e0 =>
				IF daclrcs='1' AND bclks='0' 	THEN	es <= e1;
				ELSE								es <= e0;
				END IF;
			WHEN e1 =>
													es <= e2;
			WHEN e2 =>
				IF bclks='1' 	THEN				es <= e3;
				ELSE								es <= e2;
				END IF;
			WHEN e3 =>
				IF bclks='0' 	THEN				es <= e4;
				ELSE								es <= e3;
				END IF;
			WHEN e4 =>
				IF ultimo='0' 	THEN				es <= e2;
				ELSIF daclrcs='0' THEN				es <= e0;
				ELSE								es <= e5;
				END IF;
			WHEN e5 =>
				IF daclrcs='0' AND bclks='0' 	THEN	es <= e6;
				ELSE								es <= e5;
				END IF;
			WHEN e6 =>
													es <= e2;
		END CASE;
	END PROCESS P_ES;
-- almacenamiento de estado presente --------------
	P_EP: PROCESS (clk, reset)
	BEGIN
		IF (reset='1') THEN
			ep <= e0;
		ELSIF (clk'EVENT AND clk='1') THEN
			ep <= es;
		END IF;
	END PROCESS P_EP;
-- se�ales de control --------------------------------
	lddato		<= '1' WHEN ep=e1 					ELSE '0';
	desplaza	<= '1' WHEN ep=e4 OR ep=e6 			ELSE '0';
	incbits		<= '1' WHEN ep=e4 					ELSE '0';
	outready	<= '1' WHEN ep=e1 					ELSE '0';
-- ==================================================
-- Unidad de proceso
-- registro de desplazamiento -------------------------
	P_SRDATO:PROCESS (clk, reset)
	BEGIN
		IF (reset='1') THEN
			srdato <= "00000000000000000";
		ELSIF (clk'EVENT AND clk='1') THEN
			IF (lddato='1') THEN
				srdato <= sampleout & '0';
			ELSIF (desplaza='1') THEN
				srdato <= srdato(15 DOWNTO 0) & srdato(16);
			END IF;
		END IF;
	END PROCESS P_SRDATO;
	dacdat <= srdato(16);
-- contador de bits -------------------------
	P_CBITS:PROCESS (clk, reset)
	BEGIN
		IF (reset='1') THEN
			cbits <= 0;
		ELSIF (clk'EVENT AND clk='1') THEN
			IF (incbits='1') THEN
				cbits <= cbits + 1;
			END IF;
		END IF;
	END PROCESS P_CBITS;
	ultimo	<= '1' WHEN cbits=15		ELSE '0';
-- sincronización de entradas ----------------
	P_SINCIN: PROCESS (clk, reset)
	BEGIN
		IF (reset='1') THEN
			daclrcs <= '0';
			bclks <= '0';
		ELSIF (clk'EVENT AND clk='1') THEN
			daclrcs <= daclrc;
			bclks <= bclk;
		END IF;
	END PROCESS P_SINCIN;
END a;