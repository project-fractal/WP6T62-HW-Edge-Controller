-----------------------------------------------------------------------------------------------------
-- Project		: TTSoC-NG
-- Module       : PhCmp
-- File			: phcmd.vhd
-- Author		: Christian Paukovits
-- created		: September, 1st 2015
-- last mod. by	: Hamidreza Ahmadian
-- last mod. on	:
-- contents		: the Phase Comparator to indicate instants of bursts
-----------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------
-- library includes
-----------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

library SAFEPOWER;
use SAFEPOWER.TTEL.all;        		-- constants, datatypes, and component declarations of the current TTEL

-----------------------------------------------------------------------------------------------------
-- entity declaration
-----------------------------------------------------------------------------------------------------

entity ETPhCmp is
	port (
		-- phase slice for the associated period (from the global time base)
		MyPhaseSlice	: in t_etphaseslice;
		-- signals for setting the next phase offset
		NextPhaseOff	: in t_etphaseslice;	-- next offset value
		SetPhaseOff		: in std_logic;		-- control signal
		-- indicate a compare match
		CmpMatch		: out std_logic;
		-- activate / deactivate associated period (from Configurator)
		PeriodEna		: in std_logic;
		-- standard signals
		clk				: in std_logic;		-- system clock
		reset_n			: in std_logic		-- hardware reset
	);
end ETPhCmp;

-----------------------------------------------------------------------------------------------------
-- behavioural architecture
-----------------------------------------------------------------------------------------------------

architecture behavioural of ETPhCmp is

	-- local state machine datatype
	type st_cmp is (CMP_IDLE, CMP_MATCH, CMP_WAIT);

	-- signals of state machine
	signal state		: st_cmp;
	signal nextstate	: st_cmp;

	-- the current phase offset to be triggered
	signal sOffset		: t_etphaseslice;

	-- helper signal for compare match signalling
	signal sCmpMatch	: std_logic;

begin

-----------------------------------------------------------------------------------------------------
-- state machine
-----------------------------------------------------------------------------------------------------

	fsm_reg : process(clk, reset_n)
	begin
		if reset_n = '0' then
			state <= CMP_IDLE;
		elsif rising_edge(clk) then
			state <= nextstate;
		end if;
	end process;

	fsm_cmb : process(state, MyPhaseSlice, sOffset)
	begin
		nextstate <= state;
		case state is
			when CMP_IDLE =>
				if MyPhaseSlice = sOffset then
					nextstate <= CMP_MATCH;
				end if;
			when CMP_MATCH =>
					nextstate <= CMP_WAIT;
			when CMP_WAIT =>
				if MyPhaseSlice /= sOffset then
					nextstate <= CMP_IDLE;
				end if;
		end case;
	end process;

-----------------------------------------------------------------------------------------------------
-- fetching next phase offset
-----------------------------------------------------------------------------------------------------

	fetch : process(clk, reset_n, SetPhaseOff)
	begin
		if reset_n = '0' then
			sOffset <= (others=>'0');
		elsif rising_edge(clk) then
			if SetPhaseOff = '1' then
				sOffset <= NextPhaseOff;
			end if;
		end if;
	end process;

-----------------------------------------------------------------------------------------------------
-- signalling compare match (not buffered)
-----------------------------------------------------------------------------------------------------

	-- assign helper signal, incorporate PeriodEna
	sCmpMatch <= '1' when state = CMP_MATCH and PeriodEna = '1' else '0';
	-- wire-through of compare match signal (not buffered)
	CmpMatch <= sCmpMatch;

end behavioural;
