library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rx_byte IS
  port
  (
    reset, clk     : in std_logic;
    rx             : in std_logic;
    rec_OK         : in std_logic;
	  byte		         : out unsigned(7 downto 0);
	  rec          : out std_logic 
  );
end rx_byte;

architecture a of rx_byte is
  
  -- señales internas de UP
  signal rx_s         : std_logic;
  signal Qcbits        : unsigned(3 downto 0);
  signal Qrbyte				    : unsigned(7 downto 0);
  signal Qctmp				    : unsigned(12 downto 0);
   
   -- estados presentes y siguiente de UC
  type estado is (e0,e1,e2,e3,e4,e5,e6,e7,e8,e9);
  signal ep,es : estado;
  
  -- señales UC->UP
  signal cl_cbits, cl_ctmp, INC_ctmp, right, INC_cbits : std_logic;  
  
  -- señales UP->UC
  signal fintmp1, fintmp2: std_logic;
  
  begin
   --=====================================
  -- Unidad de Control
  --=====================================
  ---------------------------------------
  -- Transicion de estados
  process (clk)
  begin
    case ep is
      when e0 =>
        if rx_s = '1' then es <= e0; 
        else  es <= e1;
        end if;
      when e1 =>
         es <= e2;
      when e2 =>
        if fintmp1 = '1' and rx_s = '0' then es <= e3; 
        elsif fintmp1 = '0' then es <= e2;
        else es <= e0;
        end if;
      when e3 =>
        es<=e4;
      when e4 =>
        if fintmp2 = '1' then es <= e5; 
        else  es <= e4;
        end if;
      when e5=>
        es<=e8;
      when e8 =>
        if Qcbits = "1000" then es <= e9; 
        else  es <= e4;
        end if;
	 when e9 =>
        if fintmp2 = '1' then es <= e6; 
        else  es <= e9;
        end if;
      when e6 =>
        if rec_OK = '1' then es <= e7;
        else  es <= e6;
        end if;
      when e7 =>
		if rx_s = '0' then
			es<=e7;
		else
			es<=e0;
		end if;
        
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
  cl_cbits <= '1' when (ep = e1  or ep=e7)else '0';
  cl_ctmp <= '1'  when (ep = e1 or ep=e3 or ep=e8) else '0';
  INC_ctmp <= '1'  when (ep = e2 or ep=e4 or ep=e9) else '0';
  right <= '1'  when ep = e5 else '0';
  INC_cbits <= '1' when ep = e5 else '0';
  
  --=====================================
  -- Unidad de Proceso
  --=====================================
  -------------------------------
  -- registro desplazamiento
  process (clk, reset)
  begin
    if reset = '1' then
      Qrbyte <= "00000000";
    elsif clk'event and clk='1' then
      if right = '1' then
        Qrbyte(6 downto 0) <= Qrbyte(7 downto 1);
        Qrbyte(7) <= rx_s;
      end if;
    end if;
  end process;

  -------------------------------
  -- CBITS
  process (clk, reset)
  begin
    if reset = '1' then
      Qcbits <= "0000";
    elsif clk'event and clk='1' then
	      if cl_cbits = '1' then
          Qcbits <= "0000";  
        elsif INC_cbits = '1' then
		      Qcbits <= Qcbits+1;
		      
	       end if;
    end if;
  end process;  
 
    -------------------------------
  -- CTMP
  process (clk, reset)
  begin
    if reset = '1' then
      Qctmp <= "0000000000000";
    elsif clk'event and clk='1' then
	      if cl_ctmp = '1' then
          Qctmp <= "0000000000000";
        end if;
        if (INC_ctmp='1' and Qctmp<"1010001011000") then
		      Qctmp <= Qctmp+1;
	      end if;
    end if;
 end process;
 -------------------------------------
 -- D
 process (clk)
   begin
   if clk'event and clk='1' then
     rx_s <= rx;
   end if;
 end process;
 
 fintmp2 <= '1' when Qctmp="1010001011000" else '0';
 fintmp1 <= '1' when Qctmp="0101000101100" else '0';
 byte <= Qrbyte;
 rec <= '1' when ep = e6 else '0';
END a;