---------------------------------------------------------------------------------------------------
-- Project		: SAFEPOWER
-- Module       : OUT port DQ selector
-- File			: outportdeqselector.vhd
-- Author		: Hamidreza Ahmadian
-- created		: November, 3rd 2015
-- last mod. by	: Hamidreza Ahmadian
-- last mod. on	:
-- contents		: Top level and architecture
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
-- library includes
---------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.ALL;


library SAFEPOWER;
use SAFEPOWER.TTEL.all;        		-- constants, datatypes, and component declarations of the current TTEL
use SAFEPOWER.ttel_parameter.all;	-- parameters of the current NoC instance

library SYSTEMS;
use SYSTEMS.system_parameter.all;	-- parameters of the current NoC instance
use SYSTEMS.auxiliary.all;         	-- for extracting configuration parameters from the files


entity outportdeqselector is
    generic
(
  NR_OUT_PORTS      : integer 
);
  port
  (
    pTTDeqIn            : in std_logic;
    pTTPortId           : in t_portid;
    pETDeqIn            : in std_logic;
    pETPortId           : in t_portid;
    pOUTPortEmpty       : in std_logic_vector (NR_OUT_PORTS - 1 downto 0);
    pOUTPortId          : out t_portid;
    pTrigAxiOut         : out std_logic;
    -- pPortDeqEn          : out std_logic_vector (NR_OUT_PORTS - 1 downto 0);
    -- pError              : out t_errorid;
    clk                 : in std_logic;
    reset_n             : in std_logic
  );
end outportdeqselector;

architecture safepower of outportdeqselector is

  begin
    process (clk)
    begin
      if reset_n = '0' then
        pOUTPortId <= (others => '0');
        pTrigAxiOut <= '0';
      elsif rising_edge (clk) then
        if pTTDeqIn = '1' then
         if pOUTPortEmpty (to_integer (unsigned (pTTPortId))) /= '1' then    
              pOUTPortId <= pTTPortId; --(to_integer (unsigned (pTTPortId)) => '1', others => '0');
              pTrigAxiOut <= '1';
          else
            pOUTPortId <= (others => '0');

          end if;
        elsif pETDeqIn = '1' then
          if pOUTPortEmpty (to_integer (unsigned (pETPortId))) /= '1' then
            pOUTPortId <= pETPortId; --(to_integer (unsigned (pETPortId)) => '1', others => '0');
            pTrigAxiOut <= '1';
          else
            pOUTPortId <= (others => '0');

          end if; 
                  else
            pTrigAxiOut <= '0';

        end if;
      end if;
    end process;

    -- error <= pTTDeqIn OR pETDeqIn;   TODO

end safepower;
