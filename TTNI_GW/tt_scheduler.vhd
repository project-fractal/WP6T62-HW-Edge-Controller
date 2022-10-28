-----------------------------------------------------------------------------------------------------
-- Project		: SAFEPOWER
-- Module       : TT-Scheduler
-- File			: tt_scheduler.vhd
-- Author		: Hamidreza Ahmadian
-- created		: October, 09th 2015
-- last mod. by	: Rakotojaona Nambinina
-- last mod. on	: October, 10th 2021
-- contents		: TT-Scheduler
-----------------------------------------------------------------------------------------------------


-- TODOs: interface to the RMI is missing.
-----------------------------------------------------------------------------------------------------
-- library includes
-----------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;	-- for conv_integer
use IEEE.std_logic_unsigned.all;

library SAFEPOWER;
use SAFEPOWER.TTEL.all;        		-- constants, datatypes, and component declarations of the current TTEL
use SAFEPOWER.ttel_parameter.all;	-- for TTCOMMSCHED_SIZE

library SYSTEMS;
use SYSTEMS.system_parameter.all;	-- parameters of the current NoC instance


entity tt_scheduler is
	 generic
	 (
	       MY_ID                   : integer := 0;
		 -- use boot-strap application or live start-up configuration
		 USE_BOOTSTRAP	: boolean := false		-- true...boot-strapping / false...start-up
	 );
  port (
        CoreInterrupt   : out std_logic;
		pTTDeqOut       : out std_logic;
		pPortIdOut	    : out t_portid;
		pTimeCntIn     	: in t_timeformat;
    -- ports for initialization and reconfiguration of the t_ttcommsched
    pTTCommSchedAddrIn	     :	in t_ttcommsched_addr;
    pTTCommSchedDataIn		   :	in t_ttcommsched;
    pTTCommSchedWrEnIn		   :	in std_logic;
    
    
    --------------input for the second BRAM which store the second Schedule s2----------
    -- added by Rakotojaona Nambinina, 
    
    pTTCommSchedAddrIn2	     :	in t_ttcommsched_addr;
    pTTCommSchedDataIn2		   :	in t_ttcommsched;
    pTTCommSchedWrEnIn2		   :	in std_logic;
    
    ------------------------------------------------------------------------------------
    sel                        : in bit;
    
		-- standard signals
    pPeriodEnIn		  : in std_logic_vector(NR_PERIODS-1 downto 0);
    -- -- trigger signal for reconfiguration instant
		pReconfInstIn		: in std_logic;

		clk							: in std_logic;	-- system clock
		reset_n					: in std_logic	-- hardware reset
	);
end tt_scheduler;

-----------------------------------------------------------------------------------------------------
-- behavioural architecture
-----------------------------------------------------------------------------------------------------

architecture behavioural of tt_scheduler is

--  constant TTCOMMSCHED_INITFILE                  : string := PROJECT_PATH & INITDIR & "lrs_" & integer'image (MY_ID) & "/ttcommsched.mem";
  constant TTCOMMSCHED_INITFILE                  : string := "NONE";
--  constant TTCOMMSCHED_INITFILE                  : string := "ttcommsched" & integer'image (MY_ID) & ".mif";
--  constant TTCOMMSCHED_INITFILE                  : string := "/home/hamid/Projects/HP/lrs_tests/dhp_2_20160119s/dhp_2.srcs/sources_1/imports/init_mif/ttcommsched" & integer'image (MY_ID) & ".mif";



  component tt_dispatcher
  	generic
  	(
  	    MY_ID                   : integer := 0;
  		-- use boot-strap application or live start-up configuration
  		USE_BOOTSTRAP	: boolean		-- true...boot-strapping / false...start-up
  	);
  	port (
  	  CoreInterrupt   : out std_logic;
      ActPortId		: out t_portid;
      --selection line only for simulation
  		InfoValid		: out std_logic;
  		TTCommSchedAddr	: out t_ttcommsched_addr;
  		TTCommSchedData	: in t_ttcommsched;
		  PhaseSlices				: in std_logic_vector(MSB_PERIODBIT-1 downto MSB_PERIODBIT-NR_PERIODS*PERIOD_DELTA-TTPHASESLICE_WIDTH+1);
      ReconfInst			: in std_logic;
      PeriodEna		: in std_logic_vector(NR_PERIODS-1 downto 0);
  		clk				: in std_logic;	-- system clock
  		reset_n			: in std_logic	-- hardware reset
  	);
  end component;


  component ttcommsched
     generic
     (
  	 	InitFile	:	string
  	 );
  	port (
      rdaddress	:	in	t_ttcommsched_addr;
      rddata		:	out	t_ttcommsched;
--        rden	   	:	in	std_logic;      
      wraddress	:	in	t_ttcommsched_addr;
      wrdata		:	in	t_ttcommsched;
      wren	   	:	in	std_logic;
      clk		   	:	in	std_logic
  );

end component;

component mux_4_2
port (
-- write addresse input
-- write data input
    write_data1 : in t_ttcommsched;
    write_data2 : in t_ttcommsched;
    sel : in bit;
    
 -- write data output 
    write_data : out t_ttcommsched
    
);
end component;

-- wire-through signals for Time-Triggered Communication Schedule
	signal wrdaddress_ttcommsched1	:	t_ttcommsched_addr;
	signal wrddata_ttcommsched1		:	t_ttcommsched;
	signal wrdaddress_ttcommsched2	:	t_ttcommsched_addr;
	signal wrddata_ttcommsched2		:	t_ttcommsched;
	
	
	signal wrdaddress_ttcommsched	:	t_ttcommsched_addr;
	signal wrddata_ttcommsched		:	t_ttcommsched;
	
	-- signal wwraddress_ttcommsched	:	t_ttcommsched_addr;
	-- signal wwrdata_ttcommsched		:	t_ttcommsched;
	-- signal wwren_ttcommsched		:	std_logic;


  begin

    -- pTTCommSchedAddrIn	=> wwraddress_ttcommsched;
    -- pTTCommSchedDataIn	=> wwrdata_ttcommsched;
    -- pTTCommSchedWrEnIn	=> wwren_ttcommsched;

    ttdispatcher_inst: tt_dispatcher
    generic map (
    MY_ID => MY_ID,
    USE_BOOTSTRAP => true      --HA: TODO
    )
    port map (
      CoreInterrupt  => CoreInterrupt,
      ActPortId => pPortIdOut,
      InfoValid => pTTDeqOut,
      TTCommSchedAddr => wrdaddress_ttcommsched,
      TTCommSchedData => wrddata_ttcommsched,
      ReconfInst => pReconfInstIn,  -- HA: TODO
      PeriodEna => pPeriodEnIn,   --HA: TODO
      PhaseSlices => pTimeCntIn (MSB_PERIODBIT-1 downto MSB_PERIODBIT-NR_PERIODS*PERIOD_DELTA-TTPHASESLICE_WIDTH+1),
      clk => clk,
      reset_n => reset_n
    );

    -- Time-Triggered Communication Schedule
  	ttcommsched_inst1 : ttcommsched
  	 generic map
  	 (
  	 	InitFile		=> TTCOMMSCHED_INITFILE
  	 )
  	port map
  	(
  		rdaddress		=> wrdaddress_ttcommsched,
  		rddata			=> wrddata_ttcommsched1,
--  		rden            => pTTDeqOut,-- OR pTTCommSchedRdEnIn,
  		wraddress		=> pTTCommSchedAddrIn,
  		wrdata			=> pTTCommSchedDataIn,
  		wren			=> pTTCommSchedWrEnIn,
  		clk				=> clk
  	);
  	
  	ttcommsched_inst2 : ttcommsched
  	 generic map
  	 (
  	 	InitFile		=> TTCOMMSCHED_INITFILE
  	 )
  	port map
  	(
  		rdaddress		=> wrdaddress_ttcommsched,
  		rddata			=> wrddata_ttcommsched2,
--  		rden            => pTTDeqOut,-- OR pTTCommSchedRdEnIn,
  		wraddress		=> pTTCommSchedAddrIn2,
  		wrdata			=> pTTCommSchedDataIn2,
  		wren			=> pTTCommSchedWrEnIn2,
  		clk				=> clk
  	);
  	
  	mux : mux_4_2 
  	port map
  	(
  	     -- write addresse input
-- write data input
    write_data1 => wrddata_ttcommsched1,
    write_data2 =>wrddata_ttcommsched2,
    sel => sel,    
 -- write data output 
    write_data =>wrddata_ttcommsched
    
    
    
  	);






end behavioural;
