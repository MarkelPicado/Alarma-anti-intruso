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

ENTITY aud_cont IS
	PORT (
		clk, reset		: IN	STD_LOGIC;
		ready			: IN	STD_LOGIC;
		alarma_activada			: IN	STD_LOGIC;
		data		: OUT	STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
END aud_cont;

ARCHITECTURE a OF aud_cont IS
-- estados presente y siguiente de UC
	
-- registro de desplazamiento
	
	--SIGNAL contCanal 	: natural range 0 to 320;
	--SIGNAL contBCLK 	: natural range 0 to 65000;
	SIGNAL cont			: STD_LOGIC;
	SIGNAL agudo :natural range 0 to 50;
	
BEGIN

-- contador de CANAl -------------------------
	PROCESS (clk, reset)
	BEGIN
		IF (reset='1') THEN
			cont	<= '0';
			agudo<=0;
		ELSIF (clk'EVENT AND clk='1') THEN
				IF (ready='1' AND alarma_activada='1') THEN
					agudo <= agudo+1;
					IF (agudo=3) THEN --cambiando el valor de este numero cambiamos la frecuencia de la señal(mas agudo mas bajo)
						cont <= not cont;
						agudo<=0;
					END IF;
				END IF;
		END IF;
	END PROCESS;
	
	data	<= "1110000000000000" WHEN cont ='1'  ELSE "0001111111111111";--cambiando los valores cambiamos la amplitud de la señal (en complemento A6)


END a;