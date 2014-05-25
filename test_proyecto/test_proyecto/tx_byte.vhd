-------------------------------------------------------------
-- tx_byte.vhd
-------------------------------------------------------------
-- unidad de proceso de juego tx en VHDL
-- 
-- Andoni Arruti, 4-oct-2011
-------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tx_byte IS
  port
  (
    reset, clk     : in std_logic;
	  byte		   : in unsigned(7 downto 0);
    trans    : in std_logic;
    trans_OK    : out std_logic;
    tx          : out std_logic
  );
end tx_byte;

architecture a of tx_byte is
  
  -- se�ales internas de UP
  signal Qcbits			    : unsigned(2 downto 0);
  signal Qctmp				    : unsigned(12 downto 0);
  signal Qbyte				    : unsigned(7 downto 0);
  -- estados presentes y siguiente de UC
  type estado is (e0,e1,e2,e3,e4,e5,e6,e7,e8,e9);
    signal ep,es : estado;
  -- se�ales UC->UP
  signal bit , putbit, ld_byte, cl_cbits, cl_ctmp, INC_ctmp, right, INC_cbits : std_logic; 
  -- se�ales UP->UC
  signal fintmp,ultimo : std_logic;
  begin
   --=====================================
  -- Unidad de Control
  --=====================================
  ---------------------------------------
  -- Transicion de estados
  process (ep, trans, fintmp, ultimo)
  begin
    case ep is
      when e0 =>
        if trans = '1' then es <= e1; 
        else  es <= e0;
        end if;
      when e1 =>
         es <= e2;
      when e2 =>
        if fintmp = '1' then es <= e3; 
        else  es <= e2;
        end if;
      when e3 =>
        es<=e4;
      when e4 =>
        if fintmp = '1' then es <= e5; 
        else  es <= e4;
        end if;
      when e5 =>
        es<=e6;
      when e6 =>
        if fintmp = '1' then 
          if ultimo = '1' then es <= e7;
          else es<=e5;
          end  if; 
        else  es <= e6;
        end if;
      when e7 =>
        es<=e8;
      when e8 =>
        if fintmp = '1' then es <= e9; 
        else  es <= e8;
        end if; 
      when e9 =>
        if trans='1' then
          es<=e9;
        else es<=e0;
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
  bit <= '1' when (ep = e0 or ep=e7 or ep=e8 or ep=e9) else '0';
  putbit <= '1'  when (ep = e0 or ep = e1 or ep=e2 or ep=e7 or ep=e8 or ep=e9) else '0';
  ld_byte <= '1' when ep = e1 else '0';
  cl_cbits <= '1' when ep = e1 else '0';
  cl_ctmp <= '1'  when (ep = e1 or ep=e3 or ep=e5 or ep=e7) else '0';
  INC_ctmp <= '1'  when (ep = e2 or ep=e4 or ep=e6 or ep=e8) else '0';
  right <= '1'  when ep = e5 else '0';
  trans_OK <= '1' when ep = e9 else '0';
  INC_cbits <= '1' when ep = e5 else '0';
  
  --=====================================
  -- Unidad de Proceso
  --=====================================
  -------------------------------
  -- registro desplazamiento
  process (clk, reset)
  begin
    if reset = '1' then
      Qbyte <= "00000000";
    elsif clk'event and clk='1' then
      if ld_byte = '1' then
        Qbyte <= byte;
      elsif right = '1' then
		    Qbyte(6 downto 0) <= Qbyte(7 downto 1);
      end if;
    end if;
  end process;
  -------------------------------
  -- MUX
  tx <= bit when putbit='1' else Qbyte(0);
  -------------------------------
  -- CBITS
  process (clk, reset)
  begin
    if reset = '1' then
      Qcbits <= "000";
    elsif clk'event and clk='1' then
	      if cl_cbits = '1' then
          Qcbits <= "000";  
        elsif INC_cbits = '1' then
		      Qcbits <= Qcbits+1;
	       end if;
    end if;
  end process;
  
  ultimo <= '1' when Qcbits="111" else '0';
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
 
 
 fintmp <= '1' when Qctmp="1010001011000" else '0';

END a;
