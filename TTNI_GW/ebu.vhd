-----------------------------------------------------------------------------------------------------
-- Project		: SAFEPOWER
-- Module       : EBU
-- File			: ebu.vhd
-- Author		: Hamidreza Ahmadian
-- created		: August, 13th 2015
-- last mod. by	: Hamidreza Ahmadian
-- last mod. on	: October, 10th 2015
-- contents		: top level entity of the EBU core
-----------------------------------------------------------------------------------------------------

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


entity EBU is
	generic
	(
        MY_ID                   : integer := 0;
        MY_VNET                     : integer := 1; 
        TIMELY_BLOCK_ACTIVE         : std_logic := '1'; 
        EVENT_TRIGGERED_ENABLE      : integer := 0;
		-- use boot-strap application or live start-up configuration
		USE_BOOTSTRAP	: boolean := false		-- true...boot-strapping / false...start-up
	);
	port
	(
		-- Core Interface side
		CoreInterrupt           : out std_logic;
		pTTDeqOut       	 	: out std_logic;
		pPortIdOut	    	 	: out t_portid;
		--------------------------------------------------
    pTTCommSchedAddrIn	     	:	in t_ttcommsched_addr;
    pTTCommSchedDataIn		   	:	in t_ttcommsched;
    pTTCommSchedWrEnIn		   	:	in std_logic;
    ------------------------------------------------------
     pTTCommSchedAddrIn2	     	:in t_ttcommsched_addr;
     pTTCommSchedDataIn2	   	:	in t_ttcommsched;
     pTTCommSchedWrEnIn2	   	:	in std_logic;
     -------------------------------------------------------

		pETDeqOut       	 	: out std_logic;
		pOpIdOut	    	 	: out t_opid;
		pETCommSchedAddrIn	    :	in t_etcommsched_addr;
       pETCommSchedDataIn		   	:	in t_etcommsched;
       pETCommSchedWrEnIn		   	:	in std_logic;


		-- control signal indicating arrival of new burst (to remainder of TTEL)
		-- HA: I'm not sure whether we need it
		--InfoValid		: out std_logic;

		-- -- trigger signal for reconfiguration instant
		pReconfInstIn		: in std_logic;
		-- activation / deactivation of specific periods
		pPeriodEnIn		: in std_logic_vector(NR_PERIODS-1 downto 0);

		-- Indicates the axi module has injected the message into the NoC
		-- HA: not sure if it's needed
		-- AxiTXDone		: in std_logic;
		-- select for the switch of schedule 
		sel            : in bit;

		-- clock signal
		clk								:	in	std_logic;		-- system operation frequency
		-- The global time base
		pTimeCntIn     		: in t_timeformat;
		-- hardware reset wire
		reset_n						:	in	std_logic
	);
  end EBU;

-----------------------------------------------------------------------------------------------------
-- behavioural architecture
-----------------------------------------------------------------------------------------------------
  architecture behavioural of EBU is

-----------------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------------

	component tt_scheduler
	 generic
    (
          MY_ID                   : integer := 0;
        -- use boot-strap application or live start-up configuration
        USE_BOOTSTRAP    : boolean := false        -- true...boot-strapping / false...start-up
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
    
    ------------------------------------------------------------------------
    pTTCommSchedAddrIn2	     :	in t_ttcommsched_addr;
    pTTCommSchedDataIn2		   :	in t_ttcommsched;
    pTTCommSchedWrEnIn2		   :	in std_logic;
    sel                        : in bit;
    -----------------------------------------------------------------------
		-- standard signals
		pPeriodEnIn		  : in std_logic_vector(NR_PERIODS-1 downto 0);
		pReconfInstIn		: in std_logic;
		clk							: in std_logic;	-- system clock
		reset_n					: in std_logic	-- hardware reset
	);
end component;

	component et_interleaver
    generic
   (
         MY_ID                   : integer := 0;
       -- use boot-strap application or live start-up configuration
       USE_BOOTSTRAP    : boolean := false        -- true...boot-strapping / false...start-up
   );
	port (
		pOpIdValid       					: out std_logic;
		pOpIdOut	    						: out t_opid;
		pTimeCntIn     						: in t_timeformat;
		pETCommSchedAddrIn	     	:	in t_etcommsched_addr;
		pETCommSchedDataIn		   	:	in t_etcommsched;
		pETCommSchedWrEnIn		   	:	in std_logic;
		pPeriodEnIn		  					: in std_logic_vector(NR_PERIODS-1 downto 0);
		pReconfInstIn							: in std_logic;
		clk												: in std_logic;	-- system clock
		reset_n										: in std_logic	-- hardware reset
	);
	end component;


	begin

		vn1_tt_part: if MY_VNET = 1
		generate
			tt_unit: tt_scheduler
			generic map (
				MY_ID => MY_ID
			)
			port map (
			    CoreInterrupt => CoreInterrupt,
				pTTDeqOut => pTTDeqOut,
				pPortIdOut => pPortIdOut,
				pTimeCntIn => pTimeCntIn,
				pTTCommSchedAddrIn => pTTCommSchedAddrIn,
				pTTCommSchedDataIn => pTTCommSchedDataIn,
				pTTCommSchedWrEnIn => pTTCommSchedWrEnIn,
				----------------------------------------
				pTTCommSchedAddrIn2 => pTTCommSchedAddrIn2,
				pTTCommSchedDataIn2 => pTTCommSchedDataIn2,
				pTTCommSchedWrEnIn2 => pTTCommSchedWrEnIn2,
				--------------------------------------------
				sel => sel, 
				pPeriodEnIn => pPeriodEnIn,
				pReconfInstIn => pReconfInstIn,
				clk => clk,
				reset_n => reset_n
			);
		end generate;

		vn2_tt_part: if MY_VNET = 2
		generate
			pTTDeqOut <= '0';
			pPortIdOut <= (others => '0');
		end generate;

        et_part: if EVENT_TRIGGERED_ENABLE = 1
        generate
		et_unit: et_interleaver
		generic map (
            MY_ID => MY_ID
        )
		port map (
			pOpIdValid => pETDeqOut,
			pOpIdOut => pOpIdOut,
			pTimeCntIn => pTimeCntIn,
			pETCommSchedAddrIn => pETCommSchedAddrIn,
			pETCommSchedDataIn => pETCommSchedDataIn,
			pETCommSchedWrEnIn => pETCommSchedWrEnIn,
			pPeriodEnIn => pPeriodEnIn,
			pReconfInstIn => pReconfInstIn,
			clk => clk,
			reset_n => reset_n
		);
        end generate;
  end behavioural;
