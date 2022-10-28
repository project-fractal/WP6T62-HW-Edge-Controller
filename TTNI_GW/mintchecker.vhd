---------------------------------------------------------------------------------------------------
-- Project		: SAFEPOWER
-- Module       : MINT Checker
-- File			: mintchecker.vhd
-- Author		: Hamidreza Ahmadian
-- created		: November, 11th 2015
-- last mod. by	: Hamidreza Ahmadian
-- last mod. on	:
-- contents		: Top level and architecture
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
-- library includes
---------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

library SAFEPOWER;
use SAFEPOWER.TTEL.all;        		-- constants, datatypes, and component declarations of the current TTEL
use SAFEPOWER.ttel_parameter.all;	-- NR_OUT_PORTS

library SYSTEMS;
use SYSTEMS.system_parameter.all;	-- parameters of the current NoC instance
use SYSTEMS.auxiliary.all;         	-- for extracting configuration parameters from the files


entity mintchecker is
  -- generic
  -- (
  -- );
  port
  (
    bFullIn         : in std_logic;
    pEmptyIn        : in std_logic;
    -- portDeq         : in std_logic;
    pTimeCnt        : in t_timeformat;
    bFullOut        : out std_logic;
    mint_value      : in t_timeformat;
    reset_n         : in std_logic;
    clk             : in std_logic
  );
end mintchecker;

architecture safepower of mintchecker is

  type st_type is (
        IDLE,       -- waiting for the new bFull signal, the MINT is already elapsed
        WAITING,    -- the new message is enqueued before the MINT is elapsed
        ELAPSED     -- the MINT is already elapsed and the message can be enqueued in to the PQU
        );

  signal state          : st_type;
  signal nextstate      : st_type;

  -- signals for enqueue and dequeue timestamps
  -- signal rLastDqTime    : t_timeformat;
  signal rNextDqTime    : t_timeformat;
  signal rMintElapsed   : std_logic;
  signal rMint          : t_timeformat;
  signal rBFull         : std_logic;
  signal wBFullOut      : std_logic;



  begin
---------------------------------------------------------------------------------------------------
-- wire-through connections
---------------------------------------------------------------------------------------------------
  bFullOut <= wBFullOut;

---------------------------------------------------------------------------------------------------
-- state machines
---------------------------------------------------------------------------------------------------

	fsm_reg : process(clk, reset_n)
	begin
		if reset_n = '0' then
			state <= IDLE;
		elsif rising_edge(clk) then
      rMint <= mint_value;    -- TODO: the location at which rMint can be updated might be improvded
			state <= nextstate;
		end if;
	end process;

	fsm_cmb : process(state, bFullIn, rMintElapsed, wBFullOut)
	begin
		nextstate <= state;
		case state is
			when IDLE =>
				if bFullIn = '1' then
					nextstate <= ELAPSED;
				end if;
			when ELAPSED =>
        if wBFullOut = '1' then
          nextstate <= WAITING;
        end if;
      when WAITING =>
        if rMintElapsed = '1' then
          if pEmptyIn = '1' then
            nextstate <= IDLE;
          else
					  nextstate <= ELAPSED;
          end if;
				end if;
      end case;
	end process;



  ---------------------------------------------------------------------------------------------------
  -- wire-through connections
  ---------------------------------------------------------------------------------------------------
  -- process for assigning
  --    rLastDqTime
  --    rNextDqTime
  --    rMintElapsed
  -- based on the value of
  --    wBFullOut
  --    pTimeCnt
  process (clk)
  begin
    if reset_n = '0' then
      -- rLastDqTime <= (others => '0');
      rNextDqTime <= (others => '0');
      rMintElapsed <= '1';
    elsif rising_edge (clk) then
      if wBFullOut = '1' then
        -- rLastDqTime <= pTimeCnt;
        rNextDqTime <= pTimeCnt + rMint;
        rMintElapsed <= '0';
      else
        if rNextDqTime < pTimeCnt then
          rMintElapsed <= '1';
        end if;
      end if;
    end if;
  end process;

  --process for assigning
  --    wBFullOut
  -- based on the value of
  --    state
  process (clk)
  begin
  if reset_n = '0' then
    wBFullOut <= '0';
  elsif rising_edge (clk) then
    if state = ELAPSED then
      if wBFullOut = '0' then
        wBFullOut <= '1';
      else
        wBFullOut <= '0';
      end if;
    end if;
  end if;
  end process;
end safepower;
