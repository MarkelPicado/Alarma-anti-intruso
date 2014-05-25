--  Library Clause
LIBRARY IEEE;
LIBRARY work;


--  Use Clause
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_unsigned.all;


entity tx_comando IS
  port
  (
    reset, clk            : in std_logic;
    trans_OK              : in std_logic;
    start_tx              : in std_logic;
    comando_tx            : in unsigned(2 downto 0);
    timestamp_tx          : in natural range 0 to 999999999;
    OK                    : in std_logic;
    activado              : in std_logic;
    res_act               : in natural range 0 to 99;
    intrusion             : in std_logic;
	  t_res		               : in natural range 0 to 99;
	  alarma                : in std_logic;
	  firmware              : in std_logic_vector(31 downto 0);
	  
    byte                  : out std_logic_vector(7 downto 0);
	  trans                 : out std_logic;
    start_tx_ack          : out std_logic
     
  );
end tx_comando;

architecture a of tx_comando is
  
  -- señales internas de UP
  signal contByte         : unsigned(4 downto 0);
  signal cn               : unsigned(4 downto 0);
  signal cmd              : unsigned(2 downto 0);
  signal comando_envio    : std_logic_vector(207 downto 0);
  signal indice           : natural range 0 to 207 := 207;
  
  --Señales para concatenar los tiempos
  signal timestamp_tx_ascii : std_logic_vector(71 downto 0);
  signal t_res_ascii  : std_logic_vector(15 downto 0);
  signal res_act_ascii  : std_logic_vector(15 downto 0);
  
  --Señales para la conversión a ascii de las señales alarma, intrusión y activado
  signal cmActivado : std_logic_vector(7 downto 0);
  signal cmIntrusion : std_logic_vector(7 downto 0);
  signal cmAlarma : std_logic_vector(7 downto 0);
  
  --Señales para la traducción de binario a ascii del timestamp
  signal digito1              : std_logic_vector(7 downto 0);
  signal digito2              : std_logic_vector(7 downto 0);
  signal digito3              : std_logic_vector(7 downto 0);
  signal digito4              : std_logic_vector(7 downto 0);
  signal digito5              : std_logic_vector(7 downto 0);
  signal digito6              : std_logic_vector(7 downto 0);
  signal digito7              : std_logic_vector(7 downto 0);
  signal digito8              : std_logic_vector(7 downto 0);
  signal digito9              : std_logic_vector(7 downto 0);
  
  signal resto1  : natural range 0 to 99999999;
  signal resto2  : natural range 0 to 9999999;
  signal resto3  : natural range 0 to 999999;
  signal resto4  : natural range 0 to 99999;
  signal resto5  : natural range 0 to 9999;
  signal resto6  : natural range 0 to 999;
  signal resto7  : natural range 0 to 99;
  signal resto8  : natural range 0 to 9;

  signal trozo1 : natural range 0 to 9;
  signal trozo2 : natural range 0 to 9;
  signal trozo3 : natural range 0 to 9;
  signal trozo4 : natural range 0 to 9;
  signal trozo5 : natural range 0 to 9;
  signal trozo6 : natural range 0 to 9;
  signal trozo7 : natural range 0 to 9;
  signal trozo8 : natural range 0 to 9;
  signal trozo9 : natural range 0 to 9;
  
  --Señales para la traducción de binario a ascii del t_res
  signal t_res_digito1  : std_logic_vector(7 downto 0);
  signal t_res_digito2  : std_logic_vector(7 downto 0);
  signal t_res_resto1  : natural range 0 to 9;
  signal t_res_trozo1 : natural range 0 to 9;
  signal t_res_trozo2 : natural range 0 to 9;
  
  --Señales para la traducción de binario a ascii del res_act
  signal res_act_digito1  : std_logic_vector(7 downto 0);
  signal res_act_digito2  : std_logic_vector(7 downto 0);
  signal res_act_resto1  : natural range 0 to 9;
  signal res_act_trozo1 : natural range 0 to 9;
  signal res_act_trozo2 : natural range 0 to 9;
  
  
   -- estados presentes y siguiente de UC
  type estado is (e0,e1,e2,e3,e4,e5,e6);
  signal ep,es : estado;
  
  -- señales UC->UP
  signal CL_cont, CL_indice, INC_cont, LD_cmd, DEC_indice: std_logic;  
  
  -- señales UP->UC
  signal fin : std_logic;
  
  begin
   --=====================================
  -- Unidad de Control
  --=====================================
  ---------------------------------------
  -- Transicion de estados
  process (ep, start_tx, fin, trans_OK)
  begin
    case ep is
      when e0 =>
        if start_tx = '1' then es <= e1;
        else es <= e0;
        end if;
      when e1 =>
         es <= e2;
      when e2 =>
        es <= e3;
      when e3 =>
        if trans_OK = '1' then es <= e4; 
        else es <= e3; 
        end if;  
      when e4 =>
        if fin = '1' then es <= e6; 
        else  es <= e5;
        end if;
      when e5 =>
        es <= e3;
	  when e6 =>
        es <= e0;
        
	  
    end case;            
  end process;
  
  ---------------------------------------
  -- REGISTRO de estados
  process (clk, reset)
	begin
		if (reset='1') then 
		  ep <= e0;
		elsif (clk'EVENT and clk='1') then	
		  ep <= es;
		end if;
end process;
	
  ---------------------------------------
  -- salidas de la unidad de control
  CL_indice <='1' when ep = e0 else '0';
  CL_cont <= '1' when ep = e0 else '0';
  LD_cmd <= '1'  when ep = e1 else '0';
  trans <='1' when (ep = e3) else '0';
  DEC_indice <= '1' when ep = e5 else '0';
  INC_cont <= '1'  when ep = e2 or ep=e5 else '0';
  start_tx_ack <= '1' when ep = e6 else '0';
  
 --=====================================
  -- Unidad de Proceso
  --=====================================
  -------------------------------
  -- CMD
  process (clk, reset)
  begin
      if reset ='1' then
        cmd <= "000";
      elsif clk'event and clk='1' then
      if LD_cmd = '1' then
        cmd <= comando_tx;
      end if;
    end if;
  end process;
  
  --------------------------
  -- Comparador
   fin <='1' when contByte = cn else '0';
   
  -------------------------------
  -- Contador
  process (clk, reset)
  begin
    if reset = '1' then
      cn <= "00000";
    elsif clk'event and clk='1' then
	      if CL_cont = '1' then
          cn <= "00000";  
        elsif INC_cont = '1' then
		      cn <= cn+1;    
	       end if;
    end if;
  end process; 
  
  -------------------------------
  -- ContadorByte
  process (clk, reset)
  begin
    if reset ='1' then
      indice <= 207;
    elsif clk'event and clk='1' then
		if CL_indice ='1' then
			indice <= 207;
		end if;
      if DEC_indice ='1' then
        indice <= indice - 8;
      end if;
    end if;
  end process;

	-------------------------------
  -- controladorTimestamp
	process (clk, reset)
	begin
	  
		-------------------------------------------------------------------------
		-------Paso del tiempo a su valor hexadecimal ascii correspondiente------
		-------------------------------------------------------------------------
				
		trozo1 <= timestamp_tx/100000000;
		resto1  <= timestamp_tx - (trozo1*100000000);
					
		trozo2 <= (resto1/10000000);
		resto2  <= resto1 - (trozo2*10000000);
					
		trozo3 <= resto2 / 1000000;
		resto3  <= resto2 - (trozo3*1000000);
					
		trozo4 <= resto3 / 100000;
		resto4  <= resto3 - (trozo4*100000);
					
		trozo5 <= resto4 / 10000;
		resto5  <= resto4 - (trozo5*10000);
					
		trozo6 <= resto5 / 1000;
		resto6  <= resto5 - (trozo6*1000);
					
		trozo7 <= resto6 / 100;
		resto7  <= resto6 - (trozo7*100);
					
		trozo8 <= resto7 / 10;
		resto8  <= resto7 - (trozo8*10);
					
		trozo9 <= resto8;                 
                    
		-- PASAR CADA TROZO A SU VALOR HEXADECIMAL DEL ASCII PARA QUE LO PUEDA REPRESENTAR LA APLICACION
		case trozo1 is
		  when 9 => digito1 <= X"39";
		  when 8 => digito1 <= X"38";
			when 7 => digito1 <= X"37";
			when 6 => digito1 <= X"36";
			when 5 => digito1 <= X"35";
			when 4 => digito1 <= X"34";
			when 3 => digito1 <= X"33";
			when 2 => digito1 <= X"32";
			when 1 => digito1 <= X"31";	
			when 0 => digito1 <= X"30";
		end case;
    case trozo2 is
		  when 9 => digito2 <= X"39";
		  when 8 => digito2 <= X"38";
			when 7 => digito2 <= X"37";
			when 6 => digito2 <= X"36";
			when 5 => digito2 <= X"35";
			when 4 => digito2 <= X"34";
			when 3 => digito2 <= X"33";
			when 2 => digito2 <= X"32";
			when 1 => digito2 <= X"31";	
			when 0 => digito2 <= X"30";
		end case;
	  case trozo3 is
		  when 9 => digito3 <= X"39";
		  when 8 => digito3 <= X"38";
			when 7 => digito3 <= X"37";
			when 6 => digito3 <= X"36";
			when 5 => digito3 <= X"35";
			when 4 => digito3 <= X"34";
			when 3 => digito3 <= X"33";
			when 2 => digito3 <= X"32";
			when 1 => digito3 <= X"31";	
			when 0 => digito3 <= X"30";
		end case;
		case trozo4 is
		  when 9 => digito4 <= X"39";
		  when 8 => digito4 <= X"38";
			when 7 => digito4 <= X"37";
			when 6 => digito4 <= X"36";
			when 5 => digito4 <= X"35";
			when 4 => digito4 <= X"34";
			when 3 => digito4 <= X"33";
			when 2 => digito4 <= X"32";
			when 1 => digito4 <= X"31";	
			when 0 => digito4 <= X"30";
		end case;
		case trozo5 is
		  when 9 => digito5 <= X"39";
		  when 8 => digito5 <= X"38";
			when 7 => digito5 <= X"37";
			when 6 => digito5 <= X"36";
			when 5 => digito5 <= X"35";
			when 4 => digito5 <= X"34";
			when 3 => digito5 <= X"33";
			when 2 => digito5 <= X"32";
			when 1 => digito5 <= X"31";	
			when 0 => digito5 <= X"30";
		end case;
		case trozo6 is
		  when 9 => digito6 <= X"39";
		  when 8 => digito6 <= X"38";
			when 7 => digito6 <= X"37";
			when 6 => digito6 <= X"36";
			when 5 => digito6 <= X"35";
			when 4 => digito6 <= X"34";
			when 3 => digito6 <= X"33";
			when 2 => digito6 <= X"32";
			when 1 => digito6 <= X"31";	
			when 0 => digito6 <= X"30";
		end case;
		case trozo7 is
		  when 9 => digito7 <= X"39";
		  when 8 => digito7 <= X"38";
			when 7 => digito7 <= X"37";
			when 6 => digito7 <= X"36";
			when 5 => digito7 <= X"35";
			when 4 => digito7 <= X"34";
			when 3 => digito7 <= X"33";
			when 2 => digito7 <= X"32";
			when 1 => digito7 <= X"31";	
			when 0 => digito7 <= X"30";
		end case;
		case trozo8 is
		  when 9 => digito8 <= X"39";
		  when 8 => digito8 <= X"38";
			when 7 => digito8 <= X"37";
			when 6 => digito8 <= X"36";
			when 5 => digito8 <= X"35";
			when 4 => digito8 <= X"34";
			when 3 => digito8 <= X"33";
			when 2 => digito8 <= X"32";
			when 1 => digito8 <= X"31";	
			when 0 => digito8 <= X"30";
		end case;
		case trozo9 is
		  when 9 => digito9 <= X"39";
		  when 8 => digito9 <= X"38";
			when 7 => digito9 <= X"37";
			when 6 => digito9 <= X"36";
			when 5 => digito9 <= X"35";
			when 4 => digito9 <= X"34";
			when 3 => digito9 <= X"33";
			when 2 => digito9 <= X"32";
			when 1 => digito9 <= X"31";	
			when 0 => digito9 <= X"30";
		end case;
			timestamp_tx_ascii <= digito1&digito2&digito3&digito4&digito5&digito6&digito7&digito8&digito9;
end process;

  
	-------------------------------
  -- controlador t_res
	process (clk, reset)
	begin
	  
    -------------------------------------------------------------------------
		-------Paso del tiempo a su valor hexadecimal ascii correspondiente------
		-------------------------------------------------------------------------
				
		t_res_trozo1 <= t_res/10;
		t_res_resto1  <= t_res - (t_res_trozo1*10);
					
		t_res_trozo2 <= t_res_resto1;
		              
		-- PASAR CADA TROZO A SU VALOR HEXADECIMAL DEL ASCII PARA QUE LO PUEDA REPRESENTAR LA APLICACION
		case t_res_trozo1 is
		  when 9 => t_res_digito1 <= X"39";
		  when 8 => t_res_digito1 <= X"38";
			when 7 => t_res_digito1 <= X"37";
			when 6 => t_res_digito1 <= X"36";
			when 5 => t_res_digito1 <= X"35";
			when 4 => t_res_digito1 <= X"34";
			when 3 => t_res_digito1 <= X"33";
			when 2 => t_res_digito1 <= X"32";
			when 1 => t_res_digito1 <= X"31";	
			when 0 => t_res_digito1 <= X"30";
		end case;
    case t_res_trozo2 is
		  when 9 => t_res_digito2 <= X"39";
		  when 8 => t_res_digito2 <= X"38";
			when 7 => t_res_digito2 <= X"37";
			when 6 => t_res_digito2 <= X"36";
			when 5 => t_res_digito2 <= X"35";
			when 4 => t_res_digito2 <= X"34";
			when 3 => t_res_digito2 <= X"33";
			when 2 => t_res_digito2 <= X"32";
			when 1 => t_res_digito2 <= X"31";	
			when 0 => t_res_digito2 <= X"30";
		end case;
		
			t_res_ascii <= t_res_digito1&t_res_digito2;
end process;

  -------------------------------
  -- controlador res_act
	process (clk, reset)
	begin
	  
    -------------------------------------------------------------------------
		-------Paso del tiempo a su valor hexadecimal ascii correspondiente------
		-------------------------------------------------------------------------
				
		res_act_trozo1 <= res_act/10;
		res_act_resto1  <= res_act - (res_act_trozo1*10);
					
		res_act_trozo2 <= res_act_resto1;
		              
		-- PASAR CADA TROZO A SU VALOR HEXADECIMAL DEL ASCII PARA QUE LO PUEDA REPRESENTAR LA APLICACION
		case res_act_trozo1 is
		  when 9 => res_act_digito1 <= X"39";
		  when 8 => res_act_digito1 <= X"38";
			when 7 => res_act_digito1 <= X"37";
			when 6 => res_act_digito1 <= X"36";
			when 5 => res_act_digito1 <= X"35";
			when 4 => res_act_digito1 <= X"34";
			when 3 => res_act_digito1 <= X"33";
			when 2 => res_act_digito1 <= X"32";
			when 1 => res_act_digito1 <= X"31";	
			when 0 => res_act_digito1 <= X"30";
		end case;
    case res_act_trozo2 is
		  when 9 => res_act_digito2 <= X"39";
		  when 8 => res_act_digito2 <= X"38";
			when 7 => res_act_digito2 <= X"37";
			when 6 => res_act_digito2 <= X"36";
			when 5 => res_act_digito2 <= X"35";
			when 4 => res_act_digito2 <= X"34";
			when 3 => res_act_digito2 <= X"33";
			when 2 => res_act_digito2 <= X"32";
			when 1 => res_act_digito2 <= X"31";	
			when 0 => res_act_digito2 <= X"30";
		end case;
		
			res_act_ascii <= res_act_digito1&res_act_digito2;
end process;

	-------------------------------
  -- controladorState
process (clk,reset)
begin
  if activado = '1' then
		  cmActivado <= X"59";
  else
		  cmActivado <= X"4E";
  end if;
		  
  if intrusion = '1' then
	   cmIntrusion <= X"59";
  else
	   cmIntrusion <= X"4E";
  end if;

  if alarma = '1' then
	 	 cmAlarma <= X"59";
  else
		 cmAlarma <= X"4E";
  end if;
end process;
					          	         
 -------------------------------
  -- Envio_comando  
  process (clk,cmd,OK)
  begin
         case cmd is
             WHEN  "000"  => 
               if OK = '1' then
                    -- Nº de bytes, incluyendo los dos bytes del fin de línea y el retorno de carro: 9 
                    contByte <= "01001";
                    -- +MK:,OK
                    comando_envio <= X"2B4D4B3A2C4F4B0A0D0000000000000000000000000000000000";                 
               else
					          -- Nº de bytes, incluyendo los dos bytes del fin de línea y el retorno de carro: 12 
					          contByte <= "01100";
					          -- +MK:,ERROR
					          comando_envio <= X"2B4D4B3A2C4552524F520A0D0000000000000000000000000000";
               end if;                
                
             WHEN  "001"  => 
               if OK = '1' then
				            -- Nº de bytes, incluyendo los dos bytes del fin de línea y el retorno de carro: 12 
				            contByte <= "01100";
							      -- +V:<ASCII>,OK
				            comando_envio <= X"2B563A"&firmware&X"2C4F4B0A0D0000000000000000000000000000";
                else
				            -- Nº de bytes, incluyendo los dos bytes del fin de línea y el retorno de carro: 15 
				            contByte <= "01111";
							      -- +V:<ASCII>,ERROR
				            comando_envio <= X"2B563A"&firmware&X"2C4552524F520A0D0000000000000000000000";
                end if;
                
             WHEN  "010"  =>  
               if OK = '1' then
				            -- Nº de bytes, incluyendo los dos bytes del fin de línea y el retorno de carro: 11 
				            contByte <= "01011";
							      -- +CONF:,OK
				            comando_envio <= X"2B434F4E463A2C4F4B0A0D000000000000000000000000000000";
                else
				            -- Nº de bytes, incluyendo los dos bytes del fin de línea y el retorno de carro: 14 
				            contByte <= "01110";
							      -- +CONF:,ERROR
				            comando_envio <= X"2B434F4E463A2C4552524F520A0D000000000000000000000000";
                end if;
                
             WHEN  "011"  => 
               if OK = '1' then
			              -- Nº de bytes, incluyendo los dos bytes del fin de línea y el retorno de carro: 11 
				            contByte <= "01011";
							      -- +PASS:,OK
						    comando_envio <= X"2B504153533A2C4F4B0A0D000000000000000000000000000000";
                else
				            -- Nº de bytes, incluyendo los dos bytes del fin de línea y el retorno de carro: 14
				            contByte <= "01110";
				            -- +PASS:,ERROR
							comando_envio <= X"2B504153533A2C4552524F520A0D000000000000000000000000";
                end if;
                
             WHEN  "100"  =>  
               if OK = '1' then
				            -- Nº de bytes, incluyendo los dos bytes del fin de línea y el retorno de carro: 10 
				            contByte <= "01010";
                    -- +ACT:,OK
				            comando_envio <= X"2B4143543A2C4F4B0A0D00000000000000000000000000000000";
                else
				            -- Nº de bytes, incluyendo los dos bytes del fin de línea y el retorno de carro: 13 
				            contByte <= "01101";
                    -- +ACT:,ERROR
				            comando_envio <= X"2B4143543A2C4552524F520A0D00000000000000000000000000";
                end if;
                
             WHEN  "101"  =>
               if OK = '1' then
					         -- Nº de bytes, incluyendo los dos bytes del fin de línea y el retorno de carro: 17 
					         contByte <= "10001";
					         -- +D&H:<timestamp>,OK
				           comando_envio <= X"2B4426483A"&timestamp_tx_ascii&X"2C4F4B0A0D00000000000000";				  
               else
					         -- Nº de bytes, incluyendo los dos bytes del fin de línea y el retorno de carro: 20 
					         contByte <= "10100";
					         -- +D&H:<timestamp>,ERROR
					         comando_envio <= X"2B4426483A"&timestamp_tx_ascii&X"2C4552524F520A0D00000000";
               end if;
                
             WHEN  "110"  =>  
               if OK = '1' then
					         -- Nº de bytes, incluyendo los dos bytes del fin de línea y el retorno de carro: 23 
					         contByte <="10111";
					         -- +STATE:<ACTIVADO YES O NO>, <TIEMPO RESTANTE PARA LA ACTIVACION DE LA ALARMA>,
					         -- <INTRUSION Y O N>, <TIEMPO RESTANTE PARA SEÑAL DE ALARMA>, <ALARMA Y O N>,OK
					        comando_envio <= X"2B53544154453A"&cmActivado&X"2C"&res_act_ascii&X"2C"&cmIntrusion&X"2C"&t_res_ascii&X"2C"&cmalarma&X"2C4F4B0A0D000000";
			         else
                  -- Nº de bytes, incluyendo los dos bytes del fin de línea y el retorno de carro: 26 
				          contByte <="11010";
                  -- +STATE:<ACTIVADO YES O NO>, <TIEMPO RESTANTE PARA LA ACTIVACION DE LA ALARMA>,
					        -- <INTRUSION Y O N>, <TIEMPO RESTANTE PARA SEÑAL DE ALARMA>, <ALARMA Y O N>,ERROR
					         comando_envio <= X"2B53544154453A"&cmActivado&X"2C"&res_act_ascii&X"2C"&cmIntrusion&X"2C"&t_res_ascii&X"2C"&cmAlarma&X"2C4552524F520A0D";
                end if;
                
             WHEN  "111"  => 
               if OK = '1' then
				          -- Nº de bytes, incluyendo los dos bytes del fin de línea y el retorno de carro: 12 
				          contByte <= "01100";
                  -- +DEACT:,OK
				          comando_envio <= X"2B44454143543A2C4F4B0A0D0000000000000000000000000000";
               else
                  -- Nº de bytes, incluyendo los dos bytes del fin de línea y el retorno de carro: 15 
				          contByte <= "01111";
                  -- +DEACT:,ERROR
				          comando_envio <= X"2B44454143543A2C4552524F520A0D0000000000000000000000";
                end if;
            WHEN OTHERS =>
                contByte <= "11111";
                comando_envio <= X"0000000000000000000000000000000000000000000000000000";
         END CASE;         
end process;

 byte <=  comando_envio(indice downto indice - 7);
 
END a;