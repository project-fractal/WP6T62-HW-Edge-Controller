-----------------------------------------------------------------------------------------------------
-- Project		: SAFEPOWER
-- Module       : ET-Interleaver
-- File			: et_interleaver.vhd
-- Author		: Hamidreza Ahmadian
-- created		: October, 09th 2015
-- last mod. by	: Hamidreza Ahmadian
-- last mod. on	: October, 10th 2015
-- contents		: ET-Interleaver
-----------------------------------------------------------------------------------------------------

-- TODOs: interface to the RMI is missing.
-- Improvement: different types of guarding windwos can be defined for different length of msgs.

-----------------------------------------------------------------------------------------------------
-- library includes
-----------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;	-- for conv_integer
use IEEE.std_logic_unsigned.all;

library SAFEPOWER;
use SAFEPOWER.TTEL.all;        		-- constants, datatypes, and component declarations of the current TTEL

library SYSTEMS;
use SYSTEMS.system_parameter.all;	-- parameters of the current NoC instance


entity et_interleaver is
	 generic
	 (
	       MY_ID                   : integer := 0;
		 -- use boot-strap application or live start-up configuration
		 USE_BOOTSTRAP	: boolean := false		-- true...boot-strapping / false...start-up
	 );
  port (
		pOpIdValid       : out std_logic;
		pOpIdOut	    : out t_opid;
		pTimeCntIn     	: in t_timeformat;
    pETCommSchedAddrIn	     :	in t_etcommsched_addr;
    pETCommSchedDataIn		   :	in t_etcommsched;
    pETCommSchedWrEnIn		   :	in std_logic;
		-- standard signals
    pPeriodEnIn		  : in std_logic_vector(NR_PERIODS-1 downto 0);
    -- -- trigger signal for reconfiguration instant
		pReconfInstIn		: in std_logic;


		-- standard signals
		clk							: in std_logic;	-- system clock
		reset_n					: in std_logic	-- hardware reset
	);
end et_interleaver;

-----------------------------------------------------------------------------------------------------
-- behavioural architecture
-----------------------------------------------------------------------------------------------------

architecture behavioural of et_interleaver is

--	 constant ETCOMMSCHED_INITFILE                  : string := PROJECT_PATH & INITDIR & "ttel_" & integer'image (MY_ID) & "/etcommsched.mem";
     constant ETCOMMSCHED_INITFILE                  : string := "NONE";

--     constant ETCOMMSCHED_INITFILE                  : string := "etcommsched" & integer'image (MY_ID) & ".mif";
--     constant ETCOMMSCHED_INITFILE                  : string := "/home/hamid/Projects/HP/lrs_tests/dhp_2_20160119s/dhp_2.srcs/sources_1/imports/init_mif/etcommsched" & integer'image (MY_ID) & ".mif";




  component et_dispatcher
  	 generic
  	 (
  	 	-- use boot-strap application or live start-up configuration
  	 	USE_BOOTSTRAP	: boolean		-- true...boot-strapping / false...start-up
  	 );
  	port (
      ActOpId						: out t_opid;
      InfoValid                    : out std_logic;
      ETCommSchedAddr        : out t_etcommsched_addr;
      ETCommSchedData        : in t_etcommsched;
      ReconfInst                : in std_logic;
      PeriodEna                    : in std_logic_vector(NR_PERIODS-1 downto 0);
      PhaseSlices                : in std_logic_vector(MSB_PERIODBIT-1 downto MSB_PERIODBIT-NR_PERIODS*PERIOD_DELTA-ETPHASESLICE_WIDTH+1);
      clk                                : in std_logic;    -- system clock
      reset_n                        : in std_logic    -- hardware reset
 	);
  end component;


  component etcommsched
     generic
     (
  	 	InitFile	:	string
  	 );
  	port (
      rdaddress	:	in	t_etcommsched_addr;
      rddata		:	out	t_etcommsched;
      wraddress	:	in	t_etcommsched_addr;
      wrdata		:	in	t_etcommsched;
      wren	   	:	in	std_logic;
      clk		   	:	in	std_logic
  );

end component;

-- wire-through signals for Event-Triggered Communication Schedule
	signal wrdaddress_etcommsched	:	t_etcommsched_addr;
	signal wrddata_etcommsched		:	t_etcommsched;


  begin

    etdispatcher_inst: et_dispatcher
    generic map (
    USE_BOOTSTRAP => true      --HA: TODO
    )    
    port map (
      ActOpId => pOpIdOut,
      InfoValid => pOpIdValid,
      ETCommSchedAddr => wrdaddress_etcommsched,
      ETCommSchedData => wrddata_etcommsched,
      ReconfInst => pReconfInstIn,  -- HA: TODO
      PeriodEna => pPeriodEnIn,   --HA: TODO
      PhaseSlices => pTimeCntIn (MSB_PERIODBIT-1 downto MSB_PERIODBIT-NR_PERIODS*PERIOD_DELTA-ETPHASESLICE_WIDTH+1),
      clk => clk,
      reset_n => reset_n
    );

    -- Event-Triggered Communication Schedule
  	etcommsched_inst : etcommsched
  	generic map
  	(
  		InitFile		=> ETCOMMSCHED_INITFILE
  	)
  	port map
  	(
  		rdaddress		=> wrdaddress_etcommsched,
  		rddata			=> wrddata_etcommsched,
  		wraddress		=> pETCommSchedAddrIn,
  		wrdata			=> pETCommSchedDataIn,
  		wren			=> pETCommSchedWrEnIn,
  		clk				=> clk
  	);

end behavioural;
