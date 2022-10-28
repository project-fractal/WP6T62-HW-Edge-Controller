------------------------------------------------------------------------------------------------------------
-- Project		: TTSoC-NG
-- Module       : Clock
-- File			: clock.vhd
-- Author		: Christian Paukovits
-- created		: February, 23rd 2009
-- last mod. by	: Christian Paukovits
-- last mod. on	: September, 17th 2009
-- contents		: the clock module that houses the local replication of the global time base
------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------
-- library includes
------------------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

library SAFEPOWER;
use SAFEPOWER.TTEL.all;        		-- constants, datatypes, and component declarations of the current LRS

library SYSTEMS;
use SYSTEMS.system_parameter.all;	-- parameters of the current NoC instance


------------------------------------------------------------------------------------------------------------
-- entity declaration
------------------------------------------------------------------------------------------------------------

entity Clock is
	port(
    -- standard signals
    clk          :    in std_logic;    -- system clock
    reset_n      :    in std_logic;    -- hardware reset
    -- macro tick input
    mtclk        :    in std_logic;
    -- state-set of the counter vector
    SetTimeVal   :    in std_logic;    -- control signal
    NewTimeVal    :    in t_timeformat;-- value vector
    -- reconfiguration instant to issue switch to new value
    ReconfInst   :    in std_logic;
    -- the outgoing counter vector
		TimeCnt		:	out t_timeformat
	);
end Clock;

------------------------------------------------------------------------------------------------------------
-- behavioural architecture
------------------------------------------------------------------------------------------------------------

architecture behavioural of Clock is

	-- local state machine type: for update of counter
	type st_upd is (S_IDLE, S_PEND, S_CAPT);

	-- local signals of state machine
	signal state			: st_upd;
	signal nextstate		: st_upd;

	-- register of counter vector
	signal sCnt				: t_timeformat;
	-- next value of counter vector (output of multiplexer)
	signal sNextCnt			: t_timeformat;

--	-- register of counter vector
--	signal sCnt				: std_logic_vector(63 downto 0);
--	-- next value of counter vector (output of multiplexer)
--	signal sNextCnt			: std_logic_vector(63 downto 0);


	-- signals for pulse synchronization
	signal smtclk			: std_logic;
	signal sync				: std_logic;

	-- signals for sensing a rising edge of the macro tick
	signal sOldMT			: std_logic;
	signal sMTRising		: std_logic;

	-- the bit pattern for increments of the counter vector
	constant MACROTICK_INC	: t_timeformat := (MACROTICK_BIT => '1', others=>'0');

--	-- set syn_preserve attribute to avoid the warning "removing sequential statement ..." in Synplifiy Pro, when synthesizing severeal TISSs
--	-- in an NoC design
--	attribute syn_preserve	: boolean;
--	attribute syn_preserve of sync : signal is true;
--	attribute syn_preserve of smtclk : signal is true;
--	attribute syn_preserve of sOldMT : signal is true;

begin

------------------------------------------------------------------------------------------------------------
-- state machine: for update of counter
------------------------------------------------------------------------------------------------------------

	fsm_reg : process(clk, reset_n, nextstate)
	begin
		if reset_n = '0' then
			state <= S_IDLE;
		elsif rising_edge(clk) then
			state <= nextstate;
		end if;
	end process;

	fsm_cmb : process(state, SetTimeVal, ReconfInst, sMTRising)
	begin
		nextstate <= state;
		case state is
			when S_IDLE	=>
				-- during configuration burst the new value for the counter is distributed
				if SetTimeVal = '1' then
					nextstate <= S_PEND;
				end if;
			when S_PEND	=>
				-- wait until reconfiguration instant occurs
				if ReconfInst = '1' then
					nextstate <= S_CAPT;
				end if;
			when S_CAPT =>
				-- select new value until capture at the next rising edge of the macro tick
				if sMTRising = '1' then
					nextstate <= S_IDLE;
				end if;
		end case;
	end process;

------------------------------------------------------------------------------------------------------------
-- clock counting process
------------------------------------------------------------------------------------------------------------

	-- synchronous assignment of next value
	cnt : process(clk, reset_n, sMTRising)
	begin
		if reset_n = '0' then
			sCnt <= (others => '0');
		elsif rising_edge(clk) then
			if sMTRising = '1' then
				sCnt <= sNextCnt;
			end if;
		end if;
	end process;

	-- asynchronous determination of next value
	-- also considers pending states (multiplex between register and output of adder)
	sNextCnt <= NewTimeVal when state = S_CAPT else sCnt + MACROTICK_INC;

------------------------------------------------------------------------------------------------------------
-- clock-domain crossing (pulse) synchronization
------------------------------------------------------------------------------------------------------------

sync_drive : process(clk, reset_n)
begin
	if reset_n = '0' then
		sync <= '0';
		smtclk <= '0';
		sOldMT <= '0';
	elsif rising_edge(clk) then
		sync <= mtclk;		-- first buffer stage of pulse synchronization
		smtclk <= sync;		-- second buffer stage of pulse synchronization
		sOldMT <= smtclk;	-- store old level of macro tick for edge detection
	end if;
end process;

	-- rising edge detection of macro tick
	sMTRising <= '1' when sOldMT = '0' and smtclk = '1' else '0';

------------------------------------------------------------------------------------------------------------
-- wire-through
------------------------------------------------------------------------------------------------------------

	TimeCnt <= sCnt;

end behavioural;

