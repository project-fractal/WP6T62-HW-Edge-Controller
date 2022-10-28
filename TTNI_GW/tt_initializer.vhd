------------------------------------------------------------------------------------------------------
-- Project		: TTSoC-NG
-- Module       : Initializer
-- File			: initializer.vhd
-- Author		: Christian Paukovits
-- created		: September, 1st 2009
-- last mod. by	: Hamidreza Ahmadian
-- last mod. on	:
-- contents		: Initializer component to set-up Period Controllers at start-up or reconfiguration instant
------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------
-- library includes
------------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

library SAFEPOWER;
use SAFEPOWER.TTEL.all;        		-- constants, datatypes, and component declarations of the current TTEL (for t_ttcommsched_addr datatype)
use SAFEPOWER.ttel_parameter.all;	-- parameters of the current NoC instance	(for TTCOMMSCHED_SIZE)

library SYSTEMS;
use SYSTEMS.system_parameter.all;	-- parameters of the current NoC instance


------------------------------------------------------------------------------------------------------
-- entity declaration
------------------------------------------------------------------------------------------------------

entity Initializer is
	port
	(
		-- address bus (to Time-Triggered Communication Schedule)
		InitAddr	: out t_ttcommsched_addr;
		-- signalization output signal (to Burst Dispatcher)
		InitDone	: out std_logic;
		-- standard signals
		clk			: in std_logic;	-- system clock
		reset_n		: in std_logic	-- hardware reset
	);
end Initializer;

------------------------------------------------------------------------------------------------------
-- behavioural architecture
------------------------------------------------------------------------------------------------------

architecture behavioural of Initializer is

	-- special value for wait cycle counter: counting periods
	constant CNT_TOP	: integer := NR_PERIODS - 1;
	-- special value for wait cycle counter: post-processing after counting after all Period Controllers have finished
	constant CNT_DELAY	: integer := CNT_TOP + 5;

	-- local state machine datatype
	-- INIT_RMI is used to let the memory be loaded by the RMI
	type st_init is (INIT_RMI, INIT_DELAY, INIT_CNT, INIT_AFTER_CNT, INIT_DONE, INIT_IDLE);

	-- signals of state machine
	signal state		: st_init;
	signal nextstate	: st_init;

	-- counter for wait cycles, to let the RMI to initialize the TTCommSched
	signal sWaitRMI		: integer;

	-- counter for wait cycles, goes with address bus for Time-Triggered Communication Schedule
	signal sWaitCnt		: t_ttcommsched_addr;

	-- local signal for address bus
	signal sInitAddr	: t_ttcommsched_addr;

begin

------------------------------------------------------------------------------------------------------
-- state machine
------------------------------------------------------------------------------------------------------

	fsm_reg : process(clk, reset_n)
	begin
		if reset_n = '0' then
			state <= INIT_RMI;
		elsif rising_edge(clk) then
			state <= nextstate;
		end if;
	end process;

	fsm_cmb : process(state, sWaitCnt, sWaitRMI)
	begin
		nextstate <= state;
		case state is
			when INIT_RMI =>
				if sWaitRMI = TTCOMMSCHED_INIT_TIME then
					nextstate <= INIT_DELAY;
--				nextstate <= INIT_CNT;
    			end if;
			when INIT_DELAY =>
				nextstate <= INIT_CNT;
			when INIT_CNT =>
				if sWaitCnt = CNT_TOP then
					nextstate <= INIT_AFTER_CNT;
				end if;
			when INIT_AFTER_CNT =>
				if sWaitCnt = CNT_DELAY then
					nextstate <= INIT_DONE;
				end if;
			when INIT_DONE =>
				nextstate <= INIT_IDLE;
			when INIT_IDLE =>
				nextstate <= INIT_IDLE;
		end case;
	end process;

------------------------------------------------------------------------------------------------------
-- counting wait cycles
------------------------------------------------------------------------------------------------------

	process(clk, reset_n, state)
	begin
		if reset_n = '0' then
			sWaitCnt <= (others => '0');	 -- must be '0' by hard
			sInitAddr <= (others => '0');
			sWaitRMI <= 0;
		elsif rising_edge(clk) then
			-- count wait cycles
			if state = INIT_RMI then
				sWaitRMI <= sWaitRMI + 1;
			elsif state = INIT_CNT or state = INIT_AFTER_CNT then
				sWaitCnt <= sWaitCnt + '1';
			end if;
			-- assign address
			if state = INIT_CNT then
				sInitAddr <= sWaitCnt;   ---weishenm 
			end if;
		end if;
	end process;

------------------------------------------------------------------------------------------------------
-- wire-through
------------------------------------------------------------------------------------------------------

	-- signal the completion of initialization
	InitDone <= '1' when state = INIT_DONE else '0';
	-- wire-through of address bus
	InitAddr <= sInitAddr;

end behavioural;
