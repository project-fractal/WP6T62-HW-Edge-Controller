------------------------------------------------------------------------------------------------------
-- Project		: SAFEPOWER
-- Module       : Interrupt Generator
-- File			: interrupt_gen.vhd
-- Author		: Hamidreza Ahmadian
-- created		: February, 09th 2016
-- last mod. by	: Hamidreza Ahmadian
-- last mod. on	:
-- contents		: architecture of an interrupt generator inside the core interface
------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------
-- library includes
------------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

library SAFEPOWER;
use SAFEPOWER.TTEL.all;  -- for t_portid

entity int_gen is
  generic (
    NR_OUT_PORTS              : integer; 
    NR_IN_PORTS               : integer
  );
  port (
    interrupt2core            : out std_logic;
    portIdCore                : out t_portid;
    newMsg                    : in std_logic_vector (NR_IN_PORTS - 1 downto 0);
    clk                       : in std_logic;
    reset_n                   : in std_logic
  );
end int_gen;

architecture safepower of int_gen is

begin

  process (clk, reset_n)
  variable temp_int   : std_logic;
  variable temp_pid     : integer; 
  variable cntr          : integer;
  begin
    if reset_n = '0' then
      interrupt2core <= '0';
    elsif rising_edge (clk) then
        temp_int := newMsg (0); 
      for cntr in 1 to NR_IN_PORTS - 1 loop
        temp_int := temp_int or newMsg (cntr);
        if newMsg (cntr) = '1' then 
            temp_pid := cntr + NR_OUT_PORTS;  
            end if; 
      end loop;
      interrupt2core <= temp_int;
      portIdCore <= std_logic_vector (to_unsigned (temp_pid, PORTID_WIDTH));
    end if;
  end process;

end safepower;
