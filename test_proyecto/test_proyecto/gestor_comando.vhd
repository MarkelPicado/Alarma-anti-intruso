--  Library Clause
LIBRARY IEEE;
LIBRARY work;


--  Use Clause
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_unsigned.all;


ENTITY GESTOR_COMANDO IS
PORT(	
  
	reset,clk       : IN STD_LOGIC;
	--modulo RX
	--------ENTRADAS
	cmd_completo       : IN STD_LOGIC;
	comando_rx     : IN STD_LOGIC_VECTOR(2 DOWNTO 0);				
	timestamp_rx   : IN NATURAL range 0 to 999999999;
	t_activ        : IN NATURAL range 0 to 99;
	t_desac        : IN NATURAL range 0 to 99;
	password       : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
	--------SALIDAS
	cmd_completo_ack   : OUT STD_LOGIC;
	
	--modulo TX
	--------ENTRADAS
	start_tx_ack   : IN STD_LOGIC;
	--------SALIDAS   
	start_tx       : OUT STD_LOGIC;
	comando_tx     : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
	timestamp_tx   : OUT NATURAL RANGE 0 TO 999999999;
	activado       : OUT STD_LOGIC;		
	OK             : OUT STD_LOGIC;
	res_act        : OUT NATURAL range 0 to 99;
	t_res          : OUT NATURAL range 0 to 99;
	intrusion      : OUT STD_LOGIC;
	alarma         : OUT STD_LOGIC;
	firmware       : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
	
	--modulo GestorAlarma
	--------ENTRADAS
	activado_A     : IN STD_LOGIC;
	alarma_A       : IN STD_LOGIC;
	res_actA       : IN NATURAL range 0 to 99;
	intrusoA       : IN STD_LOGIC;
	t_res_A        : IN NATURAL range 0 to 99;
	--------SALIDAS
	t_activA       : OUT NATURAL range 0 to 99;
	t_desacA       : OUT NATURAL range 0 to 99;
	AS             : OUT STD_LOGIC;
	
	---------------------
	ledVerde       : OUT STD_LOGIC;
	ledRojo        : OUT STD_LOGIC
	);
END GESTOR_COMANDO;

ARCHITECTURE a OF GESTOR_COMANDO IS

  type estado is (e0, e1, e2, e3, e4, e5, e6, e7, e8, e9, e10, e11, e12, e13, e14,e15,e16,e17,e18,e19);
	signal ep, es 		                     :estado;
	--Definici�n de se�ales internas
	SIGNAL estado_sig 		:natural range 0 to 6;
	--CONTADOR Timestamp
	SIGNAL timestamp_def,LD_TIMEST,INC_ST	 			: STD_LOGIC;	
  --CONTADOR intentos
	SIGNAL INTENTO,CL_INTENTOS,INC_INTENTOS	 			: STD_LOGIC;
	--CONTADOR state
	SIGNAL STAT,CL_STATE,INC_STATE	 			: STD_LOGIC;				
	--Registro Tiempo de Activacion
	SIGNAL t_act_def,LD_T_ACT            	 			: STD_LOGIC;
	--Registro Tiempo de Desactivacion
	SIGNAL t_desc_def,LD_T_DESC          	 			: STD_LOGIC;
	--Registro Password y comparadores Password
	SIGNAL pass_def,LD_PASS 			       : STD_LOGIC;
	signal PASSOK : STD_LOGIC;
	SIGNAL Qpassword,Qpassword_aux                          : STD_LOGIC_VECTOR(31 DOWNTO 0);
	--Registro Comando,ComandoAuxiliar(cxm),Activado,Tiempo restante de activacion, intruso, tiempo restante para se�al de alarma, se�al de alarma
	SIGNAL LD_COM,LD_CXM,LDAS,as_a,LD_ACTIVADO_A,LD_RES_ACTA,LD_INTRUSOA,LD_T_RES_A,LD_ALARMA,LD		: STD_LOGIC;
	SIGNAL com_tx,cmx                             : STD_LOGIC_VECTOR(2 DOWNTO 0);
	SIGNAL timestamp_tx_aux,timestamp_tx_aux2                   : NATURAL range 0 to 999999999;
	SIGNAL state                              : NATURAL range 0 to 9;
	SIGNAL intentos                           : NATURAL range 0 to 9;
	SIGNAL  tiempo: natural range 0 to 50000000;
	SIGNAL t_activA_aux       				  : NATURAL range 0 to 99;
	SIGNAL t_desacA_aux						  : NATURAL range 0 to 99;
	------------------------------------------------------------------------
	--UNIDAD DE CONTROL
	------------------------------------------------------------------------

BEGIN	-- transici�n de estados

	PROCESS (ep, cmd_completo,PASSOK,start_tx_ack,com_tx,clk)	-- Lista de sensibilidad
	BEGIN
		CASE ep IS
			WHEN e0 =>	
			       es <= e1;		
			WHEN e1 => 
			     if (cmd_completo='1') then 
					es <= e2;
			     else                                  
					es <= e1;
			     end if;
			when e2 =>   
			     es <= e15;
			when e3 =>
				es <= e16; 
			when e4 =>
				es <= e19; 
			WHEN e5 =>
			     if (INTENTO='0') then 
			       if (PASSOK='1') then
						 if (com_tx="111") then              
							es <= e6;
						 elsif (com_tx="010") then           
							es <= e7;
						 elsif com_tx ="100" then                              
							es <= e8;
						end if;
				   else                                  
						es <= e3;
			       end if;  
			     else 
					es <= e14;
			     end if;
			WHEN e6 =>
				es <= e12;			     
			WHEN e7 => 
				es <= e12;
			WHEN e8 =>
			     es <= e12;
			WHEN e9 =>
			      es <= e3;
			WHEN e10 =>
			      es <= e11;
			WHEN e11 =>   
			     if (start_tx_ack='1') then
						es <= e12;
			     else
						es <= e11;
			     end if;
			WHEN e12 =>
                   es <= e1;
			WHEN e13 =>   
			     if (start_tx_ack='1') then
						es <= e14;
			     else
						es <= e13;
			     end if;
			WHEN e14 =>   
			     es <= e1; 
			WHEN e15 => 
			     if (com_tx="000") then              
					es <= e11;
			     elsif (com_tx="101") then           
					es <= e11;
			     elsif (com_tx="001") then           
					es <= e11;
			     elsif (com_tx="011") then           
			       if (PASSOK='1') then              
						es <= e11;
			       else                              
						es <= e13;
			       end if;
			     elsif (com_tx="110") then           
					es <= e10;
			     elsif (com_tx="010") then           
					es <= e17; 
			     elsif (com_tx="100") then           
					es <= e17;   
			     elsif com_tx = "111" then                               
					es <= e17;   
			     end if;
			 WHEN e16 => 
				 if (cmd_completo='1') then 
					es <= e4;
				 else                                    
					es <= e16;
				 end if;
			WHEN e17 =>                                    
				es <= e18;
			WHEN e18 =>   
			     if (start_tx_ack='1') then
						es <= e3;
			     else
						es <= e18;
			     end if;
			WHEN e19 =>
			     if (cmx="011") then                    
					es <= e5;
			     elsif (cmx="110") then
			       if (STAT='1') then                   
					  es <= e14;
			       else                                  
					  es <= e9;
			       end if;
			     else                                    
					es <= e14;
			     end if;	 
		END CASE;
	
	END PROCESS;

------------------------------------------------------------------------
--Registro de estados
-----------------------
	process (clk, reset)
	begin
		if (reset='1') then
		  ep <= e0;
		elsif (clk'EVENT and clk='1') then	
		  ep <= es;
		end if;
	end process;
-------------------------------------------------------------------------
-------------------------------------------------------------------------
-- Salidas de la unidad de control
-------------------------------------------------------------------------

t_act_def <= '1' when (ep=e0) else '0';
INC_STATE <= '1' when (ep=e9) else '0';
INC_INTENTOS <= '1' when (ep=e5) else '0';
CL_STATE <= '1' when (ep=e2) else '0';
CL_INTENTOS <= '1' when (ep=e2) else '0';
LD_T_ACT <= '1' when (ep=e0 or ep=e7) else '0';
t_desc_def <= '1' when (ep=e0) else '0';
LD_T_DESC <= '1' when (ep=e0 or ep=e7) else '0';
pass_def <= '1' when (ep=e0) else '0';
LD_PASS <= '1' when (ep=e0 or ep=e7) else '0';
timestamp_def <= '1' when (ep=e0) else '0';
LD_TIMEST <= '1' when (ep=e0 or ep=e7) else '0';
LD_COM <= '1' when (ep=e2) else '0';
OK  <= '1' when (ep=e11 or ep=e18) else '0';
ledVerde <= '1' when (ep=e11) else '0';
ledRojo <= '1' when ( ep=e13 ) else '0';
start_tx <= '1' when (ep=e11 or ep=e13 or ep=e18) else '0';
cmd_completo_ack <= '1' when (ep=e3 or ep=e12 or ep=e14) else '0';
as_a <= '1' when (ep=e8) else '0';
LDAS <= '1' when (ep=e0 or ep=e8 or ep=e6) else '0';
LD_ACTIVADO_A <= '1' when (ep=e10) else '0';
LD_RES_ACTA		<= '1' when (ep=e10) else '0';			
LD_INTRUSOA   <= '1' when (ep=e10) else '0';
LD_T_RES_A    <= '1' when (ep=e10) else '0';
LD_ALARMA     <= '1' when (ep=e10) else '0';
LD_CXM    <= '1' when (ep=e4) else '0';
LD   <= '1' when (ep=e17) else '0'; 		
							
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------

----------------------------------------------------------------------------		
--UNIDAD DE PROCESO
----------------------------------------------------------------------------	
	

-- CONTADORES, registros, etc

-- CONTADORES, registros, etc


	PROCESS (clk,reset)	
	BEGIN
		IF (clk'EVENT AND clk='1') THEN 
			IF reset = '1' THEN 
				tiempo <= 50000000;					-- Ponemos el contador a Cero
			END IF;
			if (tiempo > 0) THEN
			    tiempo <= tiempo -1;	-- decrementamos si el valor es mayor a 0
			else 
				tiempo <= 50000000;
			end if;
		END IF;
	END PROCESS;
	INC_ST <= '1' when tiempo = 1 else '0';
-------------------
-- CONTADOR TIEMPO + MULTIPLEXOR
-------------------
	
	PROCESS (clk,reset,INC_ST)	
	BEGIN
		IF (clk'EVENT AND clk='1') THEN 
			IF reset = '1' THEN 
				timestamp_tx_aux <= 0;					-- Ponemos el contador a Cero
			ELSIF (LD_TIMEST = '1') THEN    		
				if (timestamp_def='1') then -- Ponemos el valor por defecto
				  timestamp_tx_aux <= 0;
				else
				  timestamp_tx_aux <= timestamp_tx_aux2;
				end if;
			ELSIF (INC_ST = '1') THEN
				timestamp_tx_aux <= timestamp_tx_aux + 1;		-- Contamos
			END IF;
		END IF;
	END PROCESS ;
	timestamp_tx <= timestamp_tx_aux;
-------------------
-- CONTADOR INTENTOS
-------------------
	
	PROCESS (clk,reset)	
	BEGIN
		IF (clk'EVENT AND clk='1') THEN 
			IF reset = '1' THEN 
				intentos <= 1;					-- Ponemos el contador a Cero
			ELSIF (CL_INTENTOS = '1') THEN    		
				intentos <= 1;
			ELSIF (INC_INTENTOS = '1') THEN
				intentos <= intentos +1;		-- Contamos
			END IF;
		END IF;
	END PROCESS ;
	
	INTENTO <= '1' when (intentos > 2) else '0';
-------------------
-- CONTADOR STATE
-------------------
	
	PROCESS (clk,reset)	
	BEGIN
		IF (clk'EVENT AND clk='1') THEN 
			IF reset = '1' THEN 
				state <= 1;					-- Ponemos el contador a Cero
			ELSIF (CL_STATE = '1') THEN    		
				state <= 1;
			ELSIF (INC_STATE = '1') THEN
				state <= state +1;		-- Contamos
			END IF;
		END IF;
	END PROCESS ;
STAT <= '1' when (state > 2) else '0';
-------------------
-- REGISTRO TIEMPO ACTIVACION + MULTIPLEXOR
-------------------
  PROCESS (clk,reset)	
	BEGIN
		IF (clk'EVENT AND clk='1') THEN 
			IF reset = '1' THEN 
				t_activA <= 30;					-- Ponemos el valor por defecto
			ELSIF (LD_T_ACT = '1') THEN    		
				if (t_act_def='1') then -- Ponemos el valor por defecto
				  t_activA <= 30;
				else
				  t_activA <= t_activA_aux;
				end if;
		  END IF;
		END IF;
	END PROCESS ;
-------------------
-- REGISTRO TIEMPO DESACTIVACION + MULTIPLEXOR
-------------------
  PROCESS (clk,reset)	
	BEGIN
		IF (clk'EVENT AND clk='1') THEN 
			IF reset = '1' THEN 
				t_desacA <= 30;					-- Ponemos el valor por defecto
			ELSIF (LD_T_DESC = '1') THEN    		
				if (t_desc_def='1') then -- Ponemos el valor por defecto
				  t_desacA <= 30;
				else
				  t_desacA <= t_desacA_aux;
				end if;
		  END IF;
		END IF;
	END PROCESS ;
	-------------------
-- REGISTRO COMANDO
-------------------
  PROCESS (clk,reset)	
	BEGIN
		IF (clk'EVENT AND clk='1') THEN 
			IF reset = '1' THEN 
				com_tx <= "000";					-- Ponemos el valor por defecto
			ELSIF (LD_COM = '1') THEN    		
				com_tx <= comando_rx;
		  END IF;
		END IF;
	END PROCESS ;
  comando_tx <= com_tx;
	-------------------
-- REGISTRO COMANDO AUXILIAR
-------------------
  PROCESS (clk,reset)	
	BEGIN
		IF (clk'EVENT AND clk='1') THEN 
			IF reset = '1' THEN 
				cmx <= "000";					-- Ponemos el valor por defecto
			ELSIF (LD_CXM = '1') THEN    		
				cmx <= comando_rx;
		  END IF;
		END IF;
	END PROCESS ;
  
	-------------------
-- REGISTRO ACTIVAR ALARMA
-------------------
  PROCESS (clk,reset)	
	BEGIN
		IF (clk'EVENT AND clk='1') THEN 
			IF reset = '1' THEN 
				AS <= '0';					-- Ponemos el valor por defecto
			ELSIF (LDAS = '1') THEN    		
				AS <= as_a;
		  END IF;
		END IF;
	END PROCESS ;
	-------------------
-- REGISTRO CONF AUX
-------------------
  PROCESS (clk,reset)	
	BEGIN
		IF (clk'EVENT AND clk='1') THEN 
			IF reset = '1' THEN 
				t_desacA_aux <=30;					
				t_activA_aux <=30;						-- Ponemos el valor por defecto
				Qpassword_aux <= X"30303030";
				timestamp_tx_aux2 <= 0;
			ELSIF (LD = '1') THEN    		
				t_desacA_aux <=t_desac;					
				t_activA_aux <=t_activ;
				Qpassword_aux <= password;
				timestamp_tx_aux2 <= timestamp_rx;
		  END IF;
		END IF;
	END PROCESS ;
	-------------------
-- REGISTRO ALARMA ACTIVADA
-------------------
  PROCESS (clk,reset)	
	BEGIN
		IF (clk'EVENT AND clk='1') THEN 
			IF reset = '1' THEN 
				activado <= '0';					-- Ponemos el valor por defecto
			ELSIF (LD_ACTIVADO_A = '1') THEN    		
				activado <= activado_A;
		  END IF;
		END IF;
	END PROCESS ;
 -------------------
-- REGISTRO TIEMPO RESTANTE ACTIVAR ALARMA (despues de activarla)
-------------------
  PROCESS (clk,reset)	
	BEGIN
		IF (clk'EVENT AND clk='1') THEN 
			IF reset = '1' THEN 
				res_act <= res_actA;					-- Ponemos el valor por defecto
			ELSIF (LD_RES_ACTA = '1') THEN    		
				res_act <= res_actA;
		  END IF;
		END IF;
	END PROCESS ;
 -------------------
-- REGISTRO INTRUSION
-------------------
  PROCESS (clk,reset)	
	BEGIN
		IF (clk'EVENT AND clk='1') THEN 
			IF reset = '1' THEN 
				intrusion <= '0';					-- Ponemos el valor por defecto
			ELSIF (LD_INTRUSOA = '1') THEN    		
				intrusion <= intrusoA;
		  END IF;
		END IF;
	END PROCESS ;
-------------------
-- REGISTRO TIEMPO RESTANTE ACTIVAR ALARMA (despues de que se detecte intrusion)
-------------------
  PROCESS (clk,reset)	
	BEGIN
		IF (clk'EVENT AND clk='1') THEN 
			IF reset = '1' THEN 
				t_res <= t_res_A;					-- Ponemos el valor por defecto
			ELSIF (LD_T_RES_A = '1') THEN    		
				t_res <= t_res_A;
		  END IF;
		END IF;
	END PROCESS ;
-------------------
-- REGISTRO ALARMA
-------------------
  PROCESS (clk,reset)	
	BEGIN
		IF (clk'EVENT AND clk='1') THEN 
			IF reset = '1' THEN 
				alarma <= '0';					-- Ponemos el valor por defecto
			ELSIF (LD_ALARMA = '1') THEN    		
				alarma <= alarma_A;
		  END IF;
		END IF;
	END PROCESS ;
-------------------
-- REGISTRO PASS + MULTIPLEXOR
-------------------
  PROCESS (clk,reset)	
	BEGIN
		IF (clk'EVENT AND clk='1') THEN 
			IF reset = '1' THEN 
				Qpassword <= X"30303030";					-- Ponemos el valor por defecto
			ELSIF (LD_PASS = '1') THEN    		
				if (pass_def='1') then -- Ponemos el valor por defecto
				  Qpassword <= X"30303030";
				else
				  Qpassword <= Qpassword_aux;
				end if;
		  END IF;
		
		END IF;
	END PROCESS ;
	
-------------------
-- COMPARADORES
-------------------
  PASSOK <= '1' when password = Qpassword else '0';
  firmware <= X"41444D33";
END a;
