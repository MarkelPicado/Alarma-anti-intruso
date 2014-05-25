
-------------------
--  PLANTILLA_VHDL.vhd
---------------------


--  Library Clause
LIBRARY IEEE;
LIBRARY work;


--  Use Clause
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_unsigned.all;


ENTITY luces IS
PORT (
		clk, reset		: IN	STD_LOGIC;
		ready			: IN	STD_LOGIC;
		alarma_activada			: IN	STD_LOGIC;
		rojo2		: OUT	STD_LOGIC;
		rojo3		: OUT	STD_LOGIC;
		rojo4		: OUT	STD_LOGIC;
		rojo5		: OUT	STD_LOGIC;
		rojo6		: OUT	STD_LOGIC;
		rojo7		: OUT	STD_LOGIC;
		rojo8		: OUT	STD_LOGIC;
		rojo9		: OUT	STD_LOGIC;
		rojo10		: OUT	STD_LOGIC;
		rojo11		: OUT	STD_LOGIC;
		rojo12		: OUT	STD_LOGIC;
		rojo13		: OUT	STD_LOGIC;
		rojo14		: OUT	STD_LOGIC;
		rojo15		: OUT	STD_LOGIC;
		rojo16		: OUT	STD_LOGIC;
		rojo17		: OUT	STD_LOGIC
		
	);
END luces;

ARCHITECTURE arq_luces OF luces IS


	TYPE estado is (e0, e1, e2, e3, e4, e5, e6,e7,e8,e9,e10,e11,e12,e13,e14,e15,e16);
	SIGNAL ep, es	: estado;
	--SIGNAL contCanal 	: natural range 0 to 320;
	--SIGNAL contBCLK 	: natural range 0 to 65000;
	SIGNAL cont			: STD_LOGIC;
	SIGNAL contLUCES		:	natural range 0 to 50000000;
	SIGNAL agudo :natural range 0 to 50;
	SIGNAl siguienteEstado:	STD_LOGIC;
	SIGNAL clcont :STD_LOGIC;
	
	
	------------------------------------------------------------------------
	--UNIDAD DE CONTROL
	------------------------------------------------------------------------

BEGIN	-- transiciï¿½n de estados

	PROCESS (ep,clk,siguienteEstado)	-- Lista de sensibilidad
	BEGIN
		CASE ep IS
			WHEN e0 =>
				IF siguienteEstado='1' THEN	es <= e1;
				ELSIF alarma_activada='0' THEN es<=e16;
				ELSE es<= e0;
				END IF;
			WHEN e1 =>
				IF siguienteEstado='1' THEN	es <= e2;
				ELSIF alarma_activada='0' THEN es<=e16;
				ELSE es<= e1;
				END IF;
			WHEN e2 =>
				IF siguienteEstado='1' THEN	es <= e3;
				ELSIF alarma_activada='0' THEN es<=e16;
				ELSE es<= e2;
				END IF;	
			WHEN e3 =>
				IF siguienteEstado='1' THEN	es <= e4;
				ELSIF alarma_activada='0' THEN es<=e16;
				ELSE es<= e3;
				END IF;	
			WHEN e4 =>
				IF siguienteEstado='1' THEN	es <= e5;
				ELSIF alarma_activada='0' THEN es<=e16;
				ELSE es<= e4;
				END IF;
			WHEN e5 =>
				IF siguienteEstado='1' THEN	es <= e6;
				ELSIF alarma_activada='0' THEN es<=e16;
				ELSE es<= e5;
				END IF;
			WHEN e6 =>
				IF siguienteEstado='1' THEN	es <= e7;
				ELSIF alarma_activada='0' THEN es<=e16;
				ELSE es<= e6;
				END IF;
			WHEN e7 =>
				IF siguienteEstado='1' THEN	es <= e9;
				ELSIF alarma_activada='0' THEN es<=e16;
				ELSE es<= e7;
				END IF;
			WHEN e8 =>
				IF siguienteEstado='1' THEN	es <= e9;
				ELSIF alarma_activada='0' THEN es<=e16;
				ELSE es<= e8;
				END IF;
			WHEN e9 =>
				IF siguienteEstado='1' THEN	es <= e10;
				ELSIF alarma_activada='0' THEN es<=e16;
				ELSE es<= e9;
				END IF;
			WHEN e10 =>
				IF siguienteEstado='1' THEN	es <= e11;
				ELSIF alarma_activada='0' THEN es<=e16;
				ELSE es<= e10;
				END IF;
			WHEN e11 =>
				IF siguienteEstado='1' THEN	es <= e12;
				ELSIF alarma_activada='0' THEN es<=e16;
				ELSE es<= e11;
				END IF;
			WHEN e12 =>
				IF siguienteEstado='1' THEN	es <= e13;
				ELSIF alarma_activada='0' THEN es<=e16;
				ELSE es<= e12;
				END IF;
			WHEN e13 =>
				IF siguienteEstado='1' THEN	es <= e14;
				ELSIF alarma_activada='0' THEN es<=e16;
				ELSE es<= e13;
				END IF;
			WHEN e14 =>
				IF siguienteEstado='1' THEN	es <= e15;
				ELSIF alarma_activada='0' THEN es<=e16;
				ELSE es<= e14;
				END IF;
			WHEN e15 =>
				IF siguienteEstado='1' THEN	es <= e0;
				ELSIF alarma_activada='0' THEN es<=e16;
				ELSE es<= e15;
				END IF;
			WHEN e16 =>
				IF alarma_activada='1' THEN	es <= e0;
				ELSE es<= e16;
				END IF;
				
		END CASE;
	
	END PROCESS ;

------------------------------------------------------------------------
--Registro de estados
-----------------------

	PROCESS (clk,reset)
	BEGIN
		IF (clk'EVENT AND clk='1') THEN 
			IF reset = '1' THEN 
				ep <= e0;
			ELSE 
				ep <= es;
			END IF;
		END IF;
	END PROCESS ;
-------------------------------------------------------------------------


-- CONTADORES, registros, etc


PROCESS (clk, reset,siguienteEstado)
	BEGIN
		IF (clk'EVENT AND clk='1') THEN 
			IF reset = '1' THEN 
				contLUCES <= 0;				
					
			ELSIF (contLUCES>3125000) THEN
			  contLUCES<=0;
			ELSE contLUCES<=contLUCES+1;
			END IF;
		END IF;
	END PROCESS;
	siguienteEstado <= '1' WHEN (contLUCES>3125000) ELSE '0';
	
-----------------------
-- SALIDAS DEL CIRCUITO
-----------------------
	rojo2		<= '1' WHEN (ep=e0 OR ep=e15) 					ELSE '0';
	rojo17		<= '1' WHEN (ep=e0 OR ep=e15) 					ELSE '0';
	rojo3		<= '1' WHEN (ep=e0 OR ep=e1 OR ep=e15 OR ep=e14) 					ELSE '0';
	rojo16		<= '1' WHEN (ep=e0 OR ep=e1 OR ep=e15 OR ep=e14) 					ELSE '0';
	rojo4		<= '1' WHEN (ep=e1 OR ep=e2 OR ep=e14  OR ep=e13) 					ELSE '0';
	rojo15		<= '1' WHEN (ep=e1 OR ep=e2 OR ep=e14  OR ep=e13) 					ELSE '0';
	rojo5		<= '1' WHEN (ep=e2 OR ep=e3 OR ep=e13  OR ep=e12) 					ELSE '0';
	rojo14		<= '1' WHEN (ep=e2 OR ep=e3 OR ep=e13  OR ep=e12) 					ELSE '0';
	rojo6		<= '1' WHEN (ep=e3 OR ep=e4 OR ep=e12 OR ep=e11) 					ELSE '0';
	rojo13		<= '1' WHEN (ep=e3 OR ep=e4 OR ep=e12 OR ep=e11) 					ELSE '0';
	rojo7		<= '1' WHEN (ep=e4 OR ep=e5 OR ep=e11 OR ep=e10) 					ELSE '0';
	rojo12		<= '1' WHEN (ep=e4 OR ep=e5 OR ep=e11 OR ep=e10) 					ELSE '0';
	rojo8		<= '1' WHEN (ep=e5 OR ep=e6 OR ep=e10 OR ep=e9) 					ELSE '0';
	rojo11		<= '1' WHEN (ep=e5 OR ep=e6 OR ep=e10 OR ep=e9) 					ELSE '0';
	rojo9		<= '1' WHEN (ep=e6 OR ep=e7 OR ep=e9 OR ep=e8) 					ELSE '0';
	rojo10		<= '1' WHEN (ep=e6 OR ep=e7 OR ep=e9 OR ep=e8) 					ELSE '0';
	

					


	

END arq_luces;
