---------------------------------------------------------------------------------------------------
-- Project		: SAFEPOWER
-- Module       : ET Opcode decoder
-- File			: etopcodedecoder.vhd
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
use IEEE.std_logic_arith.all;	-- for conv_integer
use IEEE.std_logic_unsigned.all;

library SAFEPOWER;
use SAFEPOWER.TTEL.all;        		-- constants, datatypes, and component declarations of the current TTEL

library SYSTEMS;
use SYSTEMS.system_parameter.all;	-- parameters of the current NoC instance
use SYSTEMS.auxiliary.all;         	-- for extracting configuration parameters from the files


entity etopcodedecoder is
  -- generic
  -- (
  -- );
  port
  (
  pAxiTxDone              : in std_logic;
  pETDeqIn                : in std_logic;
  pPQEmpty                : in std_logic;
  pOpIdIn_Ebu             : in std_logic_vector (OPID_WIDTH - 1 downto 0);
  pInjectETMsg            : out std_logic;
  pBypassLetIt            : out std_logic;

  clk                     : in std_logic;
  reset_n                 : in std_logic
  );
  end etopcodedecoder;

  architecture safepower of etopcodedecoder is

  signal rGWOpen          : std_logic := '0'; --£¿£¿
  signal rInjectAsserted  : std_logic := '0'; --£¿£¿
  signal rInjectETMsg     : std_logic := '0';  --£¿£¿
  signal rBypassOpen      : std_logic := '0'; -- £¿£¿


  begin
  pInjectETMsg <= rInjectETMsg;
    pBypassLetIt <= rBypassOpen;

    -- process for the generation of the rGWOpen  -- 
    process (clk)
    begin
      if reset_n = '0' then
        rGWOpen <= '0';
        rBypassOpen <= '0';
      else
        if rising_edge (clk) then
          if pETDeqIn = '1' then
            if pOpIdIn_Ebu = ETOPEN then --- ET can be send ,here no TT
              rGWOpen <= '1';
            elsif pOpIdIn_Ebu = ETCLOSE then
              rGWOpen <= '0';
            elsif pOpIdIn_Ebu = "11" then
                rBypassOpen <= '1';
              elsif pOpIdIn_Ebu = "00" then
                rBypassOpen <= '0';
            end if;
          end if;
        end if;
      end if;
    end process;

    -- process for the generation of the rInjectAsserted
    process (clk)
    begin
      if reset_n = '0' then
        rInjectAsserted <= '0';
      else
        if rising_edge (clk) then
          if pAxiTxDone = '1' or rGWOpen = '0' then
            rInjectAsserted <= '0';
          elsif rInjectETMsg = '1' then
            rInjectAsserted <= '1';
          end if;
        end if;
      end if;
    end process;

--     -- process for the generation of rInjectETMsg
     process (clk)
     begin
       if reset_n = '0' then
         rInjectETMsg <= '0';
       else
         if rising_edge (clk) then
           if rInjectETMsg = '0' then
             if rGWOpen = '1' then
               if rInjectAsserted = '0' and pPQEmpty = '0' then
                 rInjectETMsg <= '1';
               end if;
             else
               rInjectETMsg <= '0';
             end if;
           else
             rInjectETMsg <= '0';
           end if;
         end if;
       end if;
     end process;

    -- process for the generation of rInjectETMsg
--    process (clk)
--    begin
--      if reset_n = '0' then
--        rInjectETMsg <= '0';
--      else
--        if rising_edge (clk) then
--          if rInjectETMsg = '0' then
--            if rGWOpen = '1' then
--              if pAxiMBusy = '0' then
--                rInjectETMsg <= '1';
--              end if;
--            else
--              rInjectETMsg <= '0';
--            end if;
--          else
--            rInjectETMsg <= '0';
--          end if;
--        end if;
--      end if;
--    end process;


  end safepower;
