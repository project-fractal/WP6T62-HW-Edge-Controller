-----------------------------------------------------------------------------------------------------
-- Project		: SAFEPOWER
-- Module       : PeriodCtrl
-- File			: periodctrl.vhd
-- Author		: Christian Paukovits
-- created		: September, 1st 2008
-- last mod. by	: Hamidreza Ahmadian
-- last mod. on	:
-- contents		: the Period Controller to traverse cyclic, linked lists of periods in the Time-Triggered Communication Schedule
-----------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------
-- library includes
-----------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

library SAFEPOWER;
use SAFEPOWER.TTEL.all;        		-- constants, datatypes, and component declarations of the current TTEL

library SYSTEMS;
use SYSTEMS.system_parameter.all;	-- parameters of the current NoC instance
use SYSTEMS.auxiliary.all;         	-- for extracting configuration parameters from the files


-----------------------------------------------------------------------------------------------------
-- entity declaration
-----------------------------------------------------------------------------------------------------

entity PeriodCtrl is
	generic
	(
	    MY_ID                   : integer := 0;
		-- delay for this Period Controller at initialization
		INITWAIT		: integer
	);
	port
	(
		-- indicate a compare match (from its paired Phase Comparator)
		CmpMatch		: in std_logic;
		-- control signals for setting the next phase offset (to its paired Phase Comparator)
		SetPhaseOff		: out std_logic;
		-- current entry in Time-Triggered Communication Schedule (to multiplexer, Phase Comparator)
		ActEntry		: out t_ttcommsched;
		-- shared input / read data bus (from Time-Triggered Communication Schedule)
		NextEntry		: in t_ttcommsched;
		-- standard signals
		clk				: in std_logic;		-- system clock
		reset_n			: in std_logic		-- hardware reset
	);
end PeriodCtrl;

-- NOTE	:	ActEntry is split up into its elements in the Burst Dispatcher. The respective signals go to the following components:
--			ActEntry.NextPtr -> Multiplexer
--			ActEntry.Instant -> paired Phase Comparator
--			ActEntry.PortId -> Multiplexer

-----------------------------------------------------------------------------------------------------
-- behavioural architecture
-----------------------------------------------------------------------------------------------------

architecture behavioural of PeriodCtrl is

component adaptation_manager is
  generic (
   MY_ID                   : integer := 0
  );
  Port (
   clk                    : in std_logic;    -- system clock
   reset_n             : in std_logic;    -- hardware reset
   CmpMatch		: in std_logic;
   Event_ID            : in std_logic_vector (31 downto 0);
   ScheduledEntry      : in t_ttcommsched;--64bits
   BranchedEntry       : out t_ttcommsched;
   BranchDone          : out std_logic
 );
end component;

	-- local state machine datatype
	type st_pc is (PC_INIT_WAIT, PC_IDLE, PC_SETUP, PC_WAIT, PC_FETCH, PC_DONE);

	-- signals of state machine
	signal state		: st_pc;
	signal nextstate	: st_pc;

	-- counter for wait cycles (during initialization)
	signal sWaitCnt		: integer; --by HA std_logic_vector(ld(NR_PERIODS) + 1 downto 0);	-- must have one extra bit to embrace the additional delay cycles

	-- buffer for entry of Time-Triggered Communication Schedule
	signal sEntry		: t_ttcommsched;

	-- local helper signals
	signal sSetPhaseOff	: std_logic;
	
	signal sBranchedEntry : t_ttcommsched;
	
	signal sBranchDone     :std_logic;

begin

-----------------------------------------------------------------------------------------------------
-- state machine
-----------------------------------------------------------------------------------------------------

	fsm_reg : process(clk, reset_n)
	begin
		if reset_n = '0' then
			state <= PC_INIT_WAIT;
		elsif rising_edge(clk) then
			state <= nextstate;
		end if;
	end process;

	fsm_cmb : process(state, CmpMatch, sWaitCnt)
	begin
		nextstate <= state;
		case state is
			when PC_INIT_WAIT =>
				if sWaitCnt = INITWAIT then
					nextstate <= PC_FETCH;
				end if;
			when PC_IDLE =>
				if CmpMatch = '1' then
					nextstate <= PC_SETUP;
				end if;
			when PC_SETUP =>
			     if sBranchDone = '1' then
				nextstate <= PC_WAIT;
				end if;
			when PC_WAIT =>
				nextstate <= PC_FETCH;
			when PC_FETCH =>
				nextstate <= PC_DONE;
			when PC_DONE =>
				nextstate <= PC_IDLE;
		end case;
	end process;

-----------------------------------------------------------------------------------------------------
-- counting wait cycles during initialization
-----------------------------------------------------------------------------------------------------

	wait_cnt : process(clk, reset_n, state)
	begin
		if reset_n = '0' then
			sWaitCnt <= 0;
		elsif rising_edge(clk) then
			if state = PC_INIT_WAIT then
				sWaitCnt <= sWaitCnt + 1;
			end if;
		end if;
	end process;

-----------------------------------------------------------------------------------------------------
-- fetching the next entry from Time-Triggered Communication Schedule
-----------------------------------------------------------------------------------------------------

	fetch : process(clk, reset_n, state)
	begin
		if reset_n = '0' then
			sEntry <= (BranchId=>(others=>'0'), NextPtr=>(others=>'0'), Instant=>(others=>'0'), PortId=>(others=>'0'));
		elsif rising_edge(clk) then
			if state = PC_FETCH then
				sEntry <= sBranchedEntry;--NextEntry;
			end if;
		end if;
	end process;

-----------------------------------------------------------------------------------------------------
-- trigger the setting of next phase offset in the paired Phase Comparator
-----------------------------------------------------------------------------------------------------

	sSetPhaseOff <= '1' when state = PC_DONE else '0';

-----------------------------------------------------------------------------------------------------
-- wire-through
-----------------------------------------------------------------------------------------------------

	SetPhaseOff <= sSetPhaseOff;
	ActEntry <= sEntry;
	
	AM: adaptation_manager
	  generic map(
	   MY_ID => MY_ID
	  )
      Port map(
       clk   => clk,
       reset_n   => reset_n,
       CmpMatch	 => CmpMatch,
       Event_ID  => x"00000001",
       ScheduledEntry  => NextEntry,
       BranchedEntry   => sBranchedEntry,
       BranchDone      => sBranchDone
     );

end behavioural;
