--  Library Clause
LIBRARY IEEE;
LIBRARY work;


--  Use Clause
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_unsigned.all;


ENTITY rx_comando IS
PORT(
	reset, clk          : in std_logic;
	rec,cmd_completo_ack		  : IN STD_LOGIC;							-- Entradas y salidas del m�dulo
	byte			            	: IN STD_LOGIC_VECTOR (7 DOWNTO 0);	
	timestamp			       	: OUT natural range 0 to 999999999;	
	comando			         	: OUT STD_LOGIC_VECTOR (2 DOWNTO 0);
	t_activ,t_des			   	: OUT natural range 0 to 99;
	password			         : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
	cmd_completo, rec_ok				: OUT STD_LOGIC			

	);
END rx_comando;

ARCHITECTURE arq_rx_comando OF rx_comando IS


	--Definici�n de se�ales internas
	type estado is (e0, e1, e2, e3, e4,e5,e6,e7);
	signal ep, es :estado;
	signal comando_comp : STD_LOGIC_VECTOR (2 DOWNTO 0);
	signal password_aux		         : STD_LOGIC_VECTOR (31 DOWNTO 0);
	
	SIGNAL cmd   :STD_LOGIC_VECTOR (231 DOWNTO 0);
	
	signal trozo1			: natural range 0 to 9;
	signal trozo2			: natural range 0 to 9;
	signal trozo3			: natural range 0 to 9;
	signal trozo4			: natural range 0 to 9;
	signal trozo5			: natural range 0 to 9;
	signal trozo6			: natural range 0 to 9;
	signal trozo7			: natural range 0 to 9;
	signal trozo8			: natural range 0 to 9;
	signal trozo9			: natural range 0 to 9;
	signal trozo1_t_activ : natural range 0 to 9;
	signal trozo2_t_activ : natural range 0 to 9;
	signal trozo1_t_des   : natural range 0 to 9;
	signal trozo2_t_des   : natural range 0 to 9;
	
	-- Se�ales de salida de UP a UC
	signal igual :std_logic;
	signal indice :natural;
	
	-- Se�ales de salida de UC a UP
	signal cargar_comando   :std_logic;
	signal LD_byte    		:std_logic;
	signal INC_indice   	:std_logic;
	signal CL_indice 		:std_logic;
	
	
BEGIN

	------------------------------------------------------------------------
	--UNIDAD DE CONTROL
	------------------------------------------------------------------------
	
	------------------------------
	-- transici�n de estados
	------------------------------
	PROCESS (clk)	-- Lista de sensibilidad
	BEGIN
		CASE ep IS
			WHEN e0 => 
				  es<= e1;
			WHEN e1 => 
			  if rec='1' then 
				  es<=e2;
			  else 
				  es<=e1;
			  end if; 
			when e2 =>
				es <= e7;
			WHEN e7 =>
				if igual='1' then		   
					es <= e3;
				else
					es<=e6;
				end if;	
			WHEN e3 =>
				es <= e4;
			WHEN e4 =>
				es <= e5;				
			WHEN e5 =>
				if cmd_completo_ack='1' then		  
				  es <= e0;
				else 
				  es <= e5;
				end if;	
			WHEN e6 =>
				es <= e1;
		END CASE;
		
  END PROCESS;

-----------------------
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
-- SE�ALES DE CONTROL
-------------------------------------------------------------------------

CL_indice <= '1'  WHEN ep = e0 ELSE '0';
LD_byte	<= '1'     WHEN ep = e2	ELSE '0';					
rec_ok	<= '1'      WHEN (ep = e6 or ep = e3)	ELSE '0';
INC_indice <= '1'   WHEN ep = e2	ELSE '0';
cargar_comando <='1' WHEN ep = e5	ELSE '0';
cmd_completo <= '1'     WHEN ep = e5	ELSE '0';			
 

----------------------------------------------------------------------------		
--UNIDAD DE PROCESO
----------------------------------------------------------------------------	
	
---------------------
-- Comparador
---------------------

igual <= '1' when byte = X"0D"  else '0';

-------------------
-- Contador
-------------------
	
PROCESS (clk,reset,INC_indice)	
	BEGIN
	  IF reset = '1' THEN
	    	indice <= 0;					-- Ponemos el contador a Cero
		elsif clk'EVENT AND clk='1' THEN 	 			
			IF CL_indice ='1' then
				indice <= 0;
			ELSIF inc_indice = '1' THEN
			  indice <= indice + 8;
			END IF;
		END IF;
	END PROCESS;


-------------------------
-- Construccion_comando 
-------------------------
	PROCESS (clk,reset)	
	BEGIN
	  IF reset = '1' THEN
			 cmd <= X"0000000000000000000000000000000000000000000000000000000000";
		elsif clk'EVENT AND clk='1' THEN 
		  if LD_byte ='1' then
			 cmd( 231 - indice downto 224 - indice) <= byte;
		  end if;
		END IF;
	END PROCESS;
						
	

-----------------------
-- conversor_comando
-----------------------
process (clk,reset)
begin
  if  clk'EVENT and clk='1' then
	if reset ='1' then
		 comando_comp <= "000";
    elsif  cargar_comando = '1' then   
      case cmd(231 downto 192)  is
         when X"4D4B0D0000" =>
           -- MK a
           comando_comp <= "000";
         when X"4D4B2B560D" =>
           -- MK+V a
           comando_comp <= "001";   
         when X"4D4B2B434F" =>
           -- MK+CONF:<timestamp>,<tiempo de activaci�n>,< tiempo de desactivaci�n >,<nuevo password> 
           comando_comp <= "010";  
         when X"4D4B2B5041" =>
           -- MK+PASS:<password>
           comando_comp <= "011"; 
         when X"4D4B2B4143" =>
           -- MK+ACT 
           comando_comp <= "100";   
         when X"4D4B2B4426" =>
           -- MK+D&H a
           comando_comp <= "101";
         when X"4D4B2B5354" =>
           -- MK+STATE  a
           comando_comp <= "110";  
         when X"4D4B2B4445" =>
           -- MK+DEACT 
           comando_comp <= "111"; 
         when others =>
          comando_comp <= "000"; 
      end case;
    end if;
  end if;
end process;



---------------------
-- conversor_tiempos
---------------------
PROCESS (clk,reset)	
	BEGIN
		IF clk'EVENT AND clk='1' THEN	
		 if  cargar_comando = '1' then 
		 
			  ---------------------------
			  --  Traduccion de timestamp
			  ---------------------------
			  -- timestamp esta en ---> cmd ( 167 downto 96)
			  case cmd( 167 downto 160 ) is
			    when X"30" =>
			      trozo1 <= 0;
			    when X"31" =>
			      trozo1 <= 1;
			    when X"32" =>
			      trozo1 <= 2;
			    when X"33" =>
			      trozo1 <= 3;
			    when X"34" =>
			      trozo1 <= 4;
			    when X"35" =>
			      trozo1 <= 5;
			    when X"36" =>
			      trozo1 <= 6;
			    when X"37" =>
			      trozo1 <= 7;
			    when X"38" =>
			      trozo1 <= 8;
			    when X"39" =>
			      trozo1 <= 9;
			    when others =>
			      trozo1 <= 0;
			  end case;
			  
			  case cmd( 159 downto 152 ) is
			    when X"30" =>
			      trozo2 <= 0;
			    when X"31" =>
			      trozo2 <= 1;
			    when X"32" =>
			      trozo2 <= 2;
			    when X"33" =>
			      trozo2 <= 3;
			    when X"34" =>
			      trozo2 <= 4;
			    when X"35" =>
			      trozo2 <= 5;
			    when X"36" =>
			      trozo2 <= 6;
			    when X"37" =>
			      trozo2 <= 7;
			    when X"38" =>
			      trozo2 <= 8;
			    when X"39" =>
			      trozo2 <= 9;
			    when others =>
			      trozo2 <= 0;
			  end case;
			  
			  case cmd( 151 downto 144 ) is
			    when X"30" =>
			      trozo3 <= 0;
			    when X"31" =>
			      trozo3 <= 1;
			    when X"32" =>
			      trozo3 <= 2;
			    when X"33" =>
			      trozo3 <= 3;
			    when X"34" =>
			      trozo3 <= 4;
			    when X"35" =>
			      trozo3 <= 5;
			    when X"36" =>
			      trozo3 <= 6;
			    when X"37" =>
			      trozo3 <= 7;
			    when X"38" =>
			      trozo3 <= 8;
			    when X"39" =>
			      trozo3 <= 9;
			    when others =>
			      trozo3 <= 0;
			  end case;
			  
			  case cmd( 143 downto 136 ) is
			    when X"30" =>
			      trozo4 <= 0;
			    when X"31" =>
			      trozo4 <= 1;
			    when X"32" =>
			      trozo4 <= 2;
			    when X"33" =>
			      trozo4 <= 3;
			    when X"34" =>
			      trozo4 <= 4;
			    when X"35" =>
			      trozo4 <= 5;
			    when X"36" =>
			      trozo4 <= 6;
			    when X"37" =>
			      trozo4 <= 7;
			    when X"38" =>
			      trozo4 <= 8;
			    when X"39" =>
			      trozo4 <= 9;
			    when others =>
			      trozo4 <= 0;
			  end case;
			  
			  case cmd( 135 downto 128 ) is
			    when X"30" =>
			      trozo5 <= 0;
			    when X"31" =>
			      trozo5 <= 1;
			    when X"32" =>
			      trozo5 <= 2;
			    when X"33" =>
			      trozo5 <= 3;
			    when X"34" =>
			      trozo5 <= 4;
			    when X"35" =>
			      trozo5 <= 5;
			    when X"36" =>
			      trozo5 <= 6;
			    when X"37" =>
			      trozo5 <= 7;
			    when X"38" =>
			      trozo5 <= 8;
			    when X"39" =>
			      trozo5 <= 9;
			    when others =>
			      trozo5 <= 0;
			  end case;
			  
			  case cmd( 127 downto 120 ) is
			    when X"30" =>
			      trozo6 <= 0;
			    when X"31" =>
			      trozo6 <= 1;
			    when X"32" =>
			      trozo6 <= 2;
			    when X"33" =>
			      trozo6 <= 3;
			    when X"34" =>
			      trozo6 <= 4;
			    when X"35" =>
			      trozo6 <= 5;
			    when X"36" =>
			      trozo6 <= 6;
			    when X"37" =>
			      trozo6 <= 7;
			    when X"38" =>
			      trozo6 <= 8;
			    when X"39" =>
			      trozo6 <= 9;
			    when others =>
			      trozo6 <= 0;
			  end case;
			  
			  case cmd( 119 downto 112 ) is
			    when X"30" =>
			      trozo7 <= 0;
			    when X"31" =>
			      trozo7 <= 1;
			    when X"32" =>
			      trozo7 <= 2;
			    when X"33" =>
			      trozo7 <= 3;
			    when X"34" =>
			      trozo7 <= 4;
			    when X"35" =>
			      trozo7 <= 5;
			    when X"36" =>
			      trozo7 <= 6;
			    when X"37" =>
			      trozo7 <= 7;
			    when X"38" =>
			      trozo7 <= 8;
			    when X"39" =>
			      trozo7 <= 9;
			    when others =>
			      trozo7 <= 0;
			  end case;
			  
			  case cmd( 111 downto 104 ) is
			    when X"30" =>
			      trozo8 <= 0;
			    when X"31" =>
			      trozo8 <= 1;
			    when X"32" =>
			      trozo8 <= 2;
			    when X"33" =>
			      trozo8 <= 3;
			    when X"34" =>
			      trozo8 <= 4;
			    when X"35" =>
			      trozo8 <= 5;
			    when X"36" =>
			      trozo8 <= 6;
			    when X"37" =>
			      trozo8 <= 7;
			    when X"38" =>
			      trozo8 <= 8;
			    when X"39" =>
			      trozo8 <= 9;
			    when others =>
			      trozo8 <= 0;
			  end case;
			  
			  case cmd( 103 downto 96 ) is
			    when X"30" =>
			      trozo9 <= 0;
			    when X"31" =>
			      trozo9 <= 1;
			    when X"32" =>
			      trozo9 <= 2;
			    when X"33" =>
			      trozo9 <= 3;
			    when X"34" =>
			      trozo9 <= 4;
			    when X"35" =>
			      trozo9 <= 5;
			    when X"36" =>
			      trozo9 <= 6;
			    when X"37" =>
			      trozo9 <= 7;
			    when X"38" =>
			      trozo9 <= 8;
			    when X"39" =>
			      trozo9 <= 9;
			    when others =>
			      trozo9 <= 0;
			  end case;
			  
			  --------------------------
			  --  Traduccion de t_activ
			  --------------------------
			  -- t_activ esta en ---> cmd ( 87 downto 80)
			  case cmd( 87 downto 80 ) is
			    when X"30" =>
			      trozo1_t_activ <= 0;
			    when X"31" =>
			      trozo1_t_activ <= 1;
			    when X"32" =>
			      trozo1_t_activ <= 2;
			    when X"33" =>
			      trozo1_t_activ <= 3;
			    when X"34" =>
			      trozo1_t_activ <= 4;
			    when X"35" =>
			      trozo1_t_activ <= 5;
			    when X"36" =>
			      trozo1_t_activ <= 6;
			    when X"37" =>
			      trozo1_t_activ <= 7;
			    when X"38" =>
			      trozo1_t_activ <= 8;
			    when X"39" =>
			      trozo1_t_activ <= 9;
			    when others =>
			      trozo1_t_activ <= 0;
			  end case;
			  
			  case cmd( 79 downto 72 ) is
			    when X"30" =>
			      trozo2_t_activ <= 0;
			    when X"31" =>
			      trozo2_t_activ <= 1;
			    when X"32" =>
			      trozo2_t_activ <= 2;
			    when X"33" =>
			      trozo2_t_activ <= 3;
			    when X"34" =>
			      trozo2_t_activ <= 4;
			    when X"35" =>
			      trozo2_t_activ <= 5;
			    when X"36" =>
			      trozo2_t_activ <= 6;
			    when X"37" =>
			      trozo2_t_activ <= 7;
			    when X"38" =>
			      trozo2_t_activ <= 8;
			    when X"39" =>
			      trozo2_t_activ <= 9;
			    when others =>
			      trozo2_t_activ <= 0;
			  end case;
			  
			  
			  -------------------------
			  --  Traducci�n de t_des
			  -------------------------
			  -- t_des est� en ---> cmd ( 63 downto 48)
			  case cmd( 63 downto 56 ) is
			    when X"30" =>
			      trozo1_t_des <= 0;
			    when X"31" =>
			      trozo1_t_des <= 1;
			    when X"32" =>
			      trozo1_t_des <= 2;
			    when X"33" =>
			      trozo1_t_des <= 3;
			    when X"34" =>
			      trozo1_t_des <= 4;
			    when X"35" =>
			      trozo1_t_des <= 5;
			    when X"36" =>
			      trozo1_t_des <= 6;
			    when X"37" =>
			      trozo1_t_des <= 7;
			    when X"38" =>
			      trozo1_t_des <= 8;
			    when X"39" =>
			      trozo1_t_des <= 9;
			    when others =>
			      trozo1_t_des <= 0;
			  end case;
			  
			  case cmd( 55 downto 48 ) is
			    when X"30" =>
			      trozo2_t_des <= 0;
			    when X"31" =>
			      trozo2_t_des <= 1;
			    when X"32" =>
			      trozo2_t_des <= 2;
			    when X"33" =>
			      trozo2_t_des <= 3;
			    when X"34" =>
			      trozo2_t_des <= 4;
			    when X"35" =>
			      trozo2_t_des <= 5;
			    when X"36" =>
			      trozo2_t_des <= 6;
			    when X"37" =>
			      trozo2_t_des <= 7;
			    when X"38" =>
			      trozo2_t_des <= 8;
			    when X"39" =>
			      trozo2_t_des <= 9;
			    when others =>
			      trozo2_t_des <= 0;
			  end case;
		end if;	  
		END IF;
		
		timestamp <= trozo1*100000000 + trozo2*10000000 + trozo3*1000000 + trozo4*100000 + trozo5*10000 + trozo6*1000 + trozo7*100 + trozo8*10 + trozo9;
		t_des <= trozo1_t_des*10 + trozo2_t_des;
		t_activ <= trozo1_t_activ*10 + trozo2_t_activ;
	END PROCESS;		
	
----------------------
-- convertir_password
----------------------
	PROCESS (clk,reset,cargar_comando)	
	BEGIN
		if reset = '1' then
			--password <= "00000000000000000000000000000000";
			password_aux <= X"33333333";
		elsif clk'EVENT AND clk='1' THEN
			if cargar_comando ='1' and comando_comp = "010" then
					-- MK+CONF
					password_aux <= cmd( 39 downto 8 );
			elsif cargar_comando ='1' and comando_comp = "011" then
					-- MK+PASS
					password_aux <= cmd( 167 downto 136 );
			else
					password_aux <= password_aux;
			end if;
		END IF;
	END PROCESS;
	
comando <= comando_comp;
password <= password_aux;

END arq_rx_comando;

