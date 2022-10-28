-----------------------------------------------------------------------------------------------------
-- Project		: SAFEPOWER
-- Module       : tt_dispatcher
-- File			: burstdisp.vhd
-- Author		: Christian Paukovits
-- created		: February, 20th 2009
-- last mod. by	: Hamidreza Ahmadian
-- last mod. on	: October, 25th 2015
-- contents		: the Burst Dispatcher
-----------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------
-- library includes
-----------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

library SAFEPOWER;
use SAFEPOWER.TTEL.all;        		-- constants, datatypes, and component declarations of the current TTEL
use SAFEPOWER.ttel_parameter.all;	-- for ETCOMMSCHED_INIT_TIME

library SYSTEMS;
use SYSTEMS.system_parameter.all;	-- parameters of the current NoC instance
use SYSTEMS.auxiliary.all;         	-- for extracting configuration parameters from the files

-----------------------------------------------------------------------------------------------------
-- entity declaration
-----------------------------------------------------------------------------------------------------

entity et_dispatcher is
	generic
	(
		-- use boot-strap application or live start-up configuration
		USE_BOOTSTRAP	: boolean		-- true...boot-strapping / false...start-up
	);
	port
	(
		-- reference to current operation (to remainder of the TTEL)
		ActOpId						: out t_opid;
		-- control signal indicating arrival of new burst (to remainder of the TTEL)
		InfoValid					: out std_logic;
		-- read address of next entry (to Time-Triggered Communication Schedule)
		ETCommSchedAddr		: out t_etcommsched_addr;
		-- shared input / read data bus (from Time-Triggered Communication Schedule)
		ETCommSchedData		: in t_etcommsched;
		-- -- trigger signal for reconfiguration instant
		ReconfInst				: in std_logic;
		-- activation / deactivation of specific periods
		PeriodEna					: in std_logic_vector(NR_PERIODS-1 downto 0);
		-- part of the global time base covering phase slices of all periods
		PhaseSlices				: in std_logic_vector(MSB_PERIODBIT-1 downto MSB_PERIODBIT-NR_PERIODS*PERIOD_DELTA-ETPHASESLICE_WIDTH+1);
		-- standard signals
		clk								: in std_logic;	-- system clock
		reset_n						: in std_logic	-- hardware reset
	);
end et_dispatcher;

-----------------------------------------------------------------------------------------------------
-- behavioural architecture
-----------------------------------------------------------------------------------------------------

architecture behavioural of et_dispatcher is

	-- processing delay to Time-Triggered Communication Schedule until proper read data is availabe during initialization
	constant ETCOMMSCHED_PROC_DELAY	: integer := 3 + ETCOMMSCHED_INIT_TIME;

	-- local state machine datatype
	type st_bd is (BD_RESET, BD_INIT, BD_RUNNING, BD_RECONF);

	-- signals of state machine
	signal state		: st_bd;
	signal nextstate	: st_bd;

-----------------------------------------------------------------------------------------------------
-- auxiliary datatypes
-----------------------------------------------------------------------------------------------------

	-- vector datatype for phase slices
	type vt_etphaseslice is array(integer range <>) of t_etphaseslice;
	-- vector datatype for entries of the Time-Triggered Communication Schedule
	type vt_etcommsched is array(integer range <>) of t_etcommsched;

-----------------------------------------------------------------------------------------------------
-- components declaration
-----------------------------------------------------------------------------------------------------
component ETPeriodCtrl
	generic (
		-- delay for this Period Controller at initialization
		INITWAIT		: integer
	);
	port 	(
		-- indicate a compare match (from its paired Phase Comparator)
		CmpMatch		: in std_logic;
		-- control signals for setting the next phase offset (to its paired Phase Comparator)
		SetPhaseOff		: out std_logic;
		-- current entry in Time-Triggered Communication Schedule (to multiplexer, Phase Comparator)
		ActEntry		: out t_etcommsched;
		-- shared input / read data bus (from Time-Triggered Communication Schedule)
		NextEntry		: in t_etcommsched;
		-- standard signals
		clk				: in std_logic;		-- system clock
		reset_n			: in std_logic		-- hardware reset
	);
end component;

component ETPhCmp
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
end component;

component VectorCoder
	generic (
		INVECTOR_WIDTH	: integer
	);
	port 	(
		-- input vector
		InVector	: in std_logic_vector(INVECTOR_WIDTH-1 downto 0);
		-- output vector
		OutVector	: out std_logic_vector(ld(INVECTOR_WIDTH)-1 downto 0);
		-- signaling validity of output vector
		OutEna		: out std_logic
	);
end component;

component ETInitializer
	port (
		-- address bus (to Time-Triggered Communication Schedule)
		InitAddr	: out t_etcommsched_addr;
		-- signalization output signal (to Burst Dispatcher)
		InitDone	: out std_logic;
		-- standard signals
		clk			: in std_logic;	-- system clock
		reset_n		: in std_logic	-- hardware reset
	);
end component;

-----------------------------------------------------------------------------------------------------
-- local signals
-----------------------------------------------------------------------------------------------------

	-- current entries of Time-Triggered Communication Schedule from Period Controllers (structered in a vector type)
	signal sEntry		: vt_etcommsched(NR_PERIODS-1 downto 0);
	-- phase slices for each period (structered in a vector type)
	signal sPhaseSlice	: vt_etphaseslice(NR_PERIODS-1 downto 0);
	-- wire-through signal for vector of SetPhaseOff control signals
	signal sSetPhaseOff	: std_logic_vector(NR_PERIODS-1 downto 0);
	-- wire-through signal for compare match vector
	signal sCmpMatch	: std_logic_vector(NR_PERIODS-1 downto 0);
	-- register for period activation / deactivation
	signal sPeriodEna	: std_logic_vector(NR_PERIODS-1 downto 0);

	-- read addresses for Time-Triggered Communication Schedule during initialization
	signal sInitRDAddr	: t_etcommsched_addr;
	-- control signal concerning initialization
	signal sInitDone	: std_logic;
	-- control signal to reset specific components on initialization
	signal sTrigInit_n	: std_logic;

	-- multiplexer selector signals
	signal sMuxSel		: std_logic_vector(ld(NR_PERIODS)-1 downto 0);
	-- multiplexer enable
	signal sMuxEna		: std_logic;
	-- output of multiplexer: read address for Time-Triggered Communication Schedule
	signal sMuxRDAddr	: t_etcommsched_addr;
	-- -- output of multiplexer: burst reference (for remainder of TTEL)
	-- signal sMuxBurstRef	: t_burstid;
	-- output of multiplexer: port ID (for remainder of TTEL)
	signal sMuxOpId	: t_opid;

	-- wire-through signal for ActBurstRef
	signal sActOpId		: t_opid;
	-- wire-through signal for ETCommSchedAddr
	signal sETCommSchedAddr	: t_etcommsched_addr;

begin

-----------------------------------------------------------------------------------------------------
-- multiplexing
-----------------------------------------------------------------------------------------------------

	mux : process(clk, reset_n, sMuxEna, sMuxSel)
	begin
		if reset_n = '0' then
			sMuxOpId <= (others=>'0');
			sMuxRDAddr <= (others=>'0');
		elsif rising_edge(clk) then
			if sMuxEna = '1' then
				sMuxOpId <= sEntry(conv_integer(unsigned(sMuxSel))).OpId;
				sMuxRDAddr <= sEntry(conv_integer(unsigned(sMuxSel))).NextPtr;
			end if;
		end if;
	end process;

-----------------------------------------------------------------------------------------------------
-- period activation / deactivation
-----------------------------------------------------------------------------------------------------

	PeriodEna_drive : process(clk, reset_n, state, ReconfInst)
	begin
		for i in 0 to NR_PERIODS-1
		loop
			if reset_n = '0' or ReconfInst = '1' then
				sPeriodEna(i) <= '0';
			elsif rising_edge(clk) then
				if state = BD_RECONF then
					sPeriodEna(i) <= PeriodEna(i);
				end if;
			end if;
		end loop;
	end process;

-----------------------------------------------------------------------------------------------------
-- state machine: switches operation between initialization and normal operation
-----------------------------------------------------------------------------------------------------

	fsm_reg : process(clk, reset_n)
	begin
		if reset_n = '0' then
			state <= BD_RESET;
		elsif rising_edge(clk) then
			state <= nextstate;
		end if;
	end process;

	fsm_cmb : process(state, sInitDone, ReconfInst)
	begin
		nextstate <= state;
		case state is
			-- BD_RESET is the state at hardware reset
			when BD_RESET =>
				if USE_BOOTSTRAP = true then
					-- initialize from boot-strap application
					nextstate <= BD_INIT;
				else
					-- use live start-up configuration
					nextstate <= BD_RUNNING;
				end if;
			when BD_INIT =>
				if sInitDone = '1' then
					nextstate <= BD_RECONF;
				end if;
			when BD_RUNNING =>
				if ReconfInst = '1' then
					nextstate <= BD_INIT;
				end if;
			when BD_RECONF =>
					nextstate <= BD_RUNNING;
		end case;
	end process;

	-- cause initialization on hardware reset or reconfiguration instant
	sTrigInit_n <= '0' when reset_n = '0' or ReconfInst = '1' else '1';

	-- select read address for Time-Triggered Communication Schedule: Initializer or multiplexer output
	sETCommSchedAddr <= sInitRDAddr when state = BD_INIT else sMuxRDAddr;

-----------------------------------------------------------------------------------------------------
-- output to remainder of the TTEL
-----------------------------------------------------------------------------------------------------

	-- wire-through from multiplexer output
	sActOpId <= sMuxOpId;

	-- wire-through without delay
	ActOpId	 <= sActOpId;
	ETCommSchedAddr <= sETCommSchedAddr;

	output_drive : process(clk, reset_n)
	begin
		if reset_n = '0' then
			InfoValid <= '0';
		elsif rising_edge(clk) then
			InfoValid <= sMuxEna;	-- same cylce as multiplexer output
		end if;
	end process;

-----------------------------------------------------------------------------------------------------
-- structuring phase slices into vector type
-----------------------------------------------------------------------------------------------------

	phase_struct : process(PhaseSlices)
		variable lowend		: integer;
		variable highend	: integer;
		variable dist		: integer;
	begin
		for i in 0 to NR_PERIODS-1
		loop
			-- higher end of the phase slice (index in counter vector of time format)
			highend := MSB_PERIODBIT - (NR_PERIODS-i) * PERIOD_DELTA;
			-- lower end of the phase slice (index in counter vector of time format)
			lowend := highend - ETPHASESLICE_WIDTH + 1;
			-- distance of lower end of the phase slice to the macro tick bit
			dist := MACROTICK_BIT - lowend;

			if highend <= MACROTICK_BIT then
				-- phase slice already begins at or beyond (to the right) the macro tick bit
				sPhaseSlice(i) <= (others=>'0');
			else
				-- phase slice begins before (to the left) the macro tick bit
				if dist > 0 then
					-- lower end of phase slice exceeds the macro tick bit (to the right)
					-- cut off the exceeding bits
					sPhaseSlice(i)(ETPHASESLICE_WIDTH-1 downto dist) <= PhaseSlices(highend downto lowend+dist);
					sPhaseSlice(i)(dist-1 downto 0) <= (others=>'0');
				else
					-- lower end of phase slice does not exceed the macro tick bit
					-- assign whole phase slice
					sPhaseSlice(i) <= PhaseSlices(highend downto lowend);
				end if;
			end if;
		end loop;
	end process;

-----------------------------------------------------------------------------------------------------
-- component instances
-----------------------------------------------------------------------------------------------------

	-- Phase Comparators
	PhCmp_gen : for i in 0 to NR_PERIODS-1
	generate
		PhCmp_inst: ETPhCmp
		port map
		(
			MyPhaseSlice	=> sPhaseSlice(i),
			NextPhaseOff	=> sEntry(i).Instant,
			SetPhaseOff		=> sSetPhaseOff(i),
			CmpMatch		=> sCmpMatch(i),
			PeriodEna		=> sPeriodEna(i),
			clk				=> clk,
			reset_n			=> reset_n
		);
	end generate;

	-- Period Controllers
	PeriodCtrl_gen : for i in 0 to NR_PERIODS-1
	generate
		PeriodCtrl_inst: ETPeriodCtrl
		generic map
		(
			INITWAIT		=> i + ETCOMMSCHED_PROC_DELAY
		)
		port map
		(
			CmpMatch		=> sCmpMatch(i),
			SetPhaseOff		=> sSetPhaseOff(i),
			ActEntry		=> sEntry(i),
			NextEntry		=> ETCommSchedData,
			clk				=> clk,
			reset_n			=> sTrigInit_n
		);
	end generate;

	-- Initializer
	Initializer_inst: ETInitializer
	port map
	(
		InitAddr	=> sInitRDAddr,
		InitDone	=> sInitDone,
		clk			=> clk,
		reset_n		=> sTrigInit_n
	);

	-- Vector Coder
	ONE_PERIOD: if NR_PERIODS = 1 generate
        sMuxEna <= sCmpMatch (0);
        sMuxSel <= b"0";
    end generate ONE_PERIOD;
  MUL_PERIOD: if NR_PERIODS > 1 generate
      vc_inst: VectorCoder
      generic map
      (
          INVECTOR_WIDTH    => NR_PERIODS
      )
      port map
      (
          InVector    => sCmpMatch,
          OutVector    => sMuxSel,
          OutEna        => sMuxEna
      );
  end generate MUL_PERIOD;	
--	vc_inst: VectorCoder
--	generic map
--	(
--		INVECTOR_WIDTH	=> NR_PERIODS
--	)
--	port map
--	(
--		InVector	=> sCmpMatch,
--		OutVector	=> sMuxSel,
--		OutEna		=> sMuxEna
--	);

end behavioural;
