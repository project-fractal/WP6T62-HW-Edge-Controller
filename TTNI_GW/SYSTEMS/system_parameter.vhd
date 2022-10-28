------------------------------------------------------------------------------------------------------
-- Project		: SAFEPOWER
-- Module       : package "system_parameter"
-- File			: system_parameter.vhd
-- Author		: Hamidreza Ahmadian
-- created		: August, 13th 2015
-- last mod. by	: Hamidreza Ahmadian
-- last mod. on	: August, 13th 2015
-- contents		: This file contains constants, which may deviate for a __whole__ ttel instance.
--				: In order to adapt a ttel instance to your needs, modify the constants in here.
------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------
-- library includes
------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library SYSTEMS;
use SYSTEMS.configman.all;         	-- for extracting configuration parameters from the files


------------------------------------------------------------------------------------------------------
-- package "parameter"
------------------------------------------------------------------------------------------------------

package system_parameter is

------------------------------------------------------------------------------------------------------
-- system-wide parameters valid for the whole NoC instance
------------------------------------------------------------------------------------------------------
--C:\Users\User\Desktop\backup\9.3\Task_ttel\Task_ttel\12.23_TASK\TTEL_v2\usr
--C:/Task_ttel/12.23_TASK/TTEL_v2/usr/
--/home/darshak/SEPIA/GIT/TT_lisnoc/source_file/TT_NI/TTEL/usr/C:\Users\Guang\Desktop\TT_lisnoc\TT_lisnoc\source_file\TT_NI\TTEL\usr
	constant PROJECT_PATH				: string := "/home/tsn/Desktop/GW_NI/TTLISNOC_Code/usr/";
	--C:\Users\User\Desktop\CONF\usr
	constant INITDIR                    : string := "meminit/";
    constant HWCONFIGFILE               : string := "hw.cfg"; 
   
--    constant HW_INITIALIZED             : boolean := init_hwconfig (PROJECT_PATH & INITDIR & HWCONFIGFILE); 
--    constant NR_TILES                   : integer := nr_tiles (PROJECT_PATH & INITDIR & HWCONFIGFILE); 


--    constant CONF_NR_PORTS              : at_nr_ports := nr_ports (PROJECT_PATH & INITDIR & HWCONFIGFILE);
--    constant CONF_NR_OUT_PORTS          : at_nr_ports := nr_out_ports (PROJECT_PATH & INITDIR & HWCONFIGFILE);
    
--    constant CONF_TT_CONF               : t_disp_conf := tt_config (PROJECT_PATH & INITDIR & HWCONFIGFILE); 
--    constant CONF_ET_CONF               : t_disp_conf := et_config (PROJECT_PATH & INITDIR & HWCONFIGFILE); 

--    constant HW_INITIALIZED             : boolean := init_hwconfig (PROJECT_PATH & INITDIR & HWCONFIGFILE); 
    constant NR_TILES                   : integer := 4; 


    constant CONF_NR_PORTS              : at_nr_ports := nr_ports (PROJECT_PATH & INITDIR & HWCONFIGFILE);
    constant CONF_NR_OUT_PORTS          : at_nr_ports := nr_out_ports (PROJECT_PATH & INITDIR & HWCONFIGFILE);
    
    constant CONF_TT_CONF               : t_disp_conf := tt_config (PROJECT_PATH & INITDIR & HWCONFIGFILE); 
    constant CONF_ET_CONF               : t_disp_conf := et_config (PROJECT_PATH & INITDIR & HWCONFIGFILE); 


	-- width of the counter vector of the time format of the global time base (not intended for design-time configuration)
	-- NOTE: The Time Stamper is scalable. In case of modifications of this constant, the Time Stamper need not be adapted. However, the Register File
	-- and the Configurator can not scale with respect to the width of the time format's counter vector!
	-- It needs explicit modifications in register mappings. Hence, also look at the package "registermap", when changing this constant.
	constant TIMEFORMAT_COUNTER_WIDTH		: integer		:= 64;


	-- At the moment we consider constant message length for simplicity
	-- This constant represents the length of the message. If the message is shorter
	-- than this value, dummy bytes will fill this space. The unit is in words
	constant MESSAGE_SIZE				: integer 		:= 16;

	-- Width in bits of the data words in the Port Memory
	-- This constant also matches the width of the (unidirectional) data bus in the Port Interface. It __must__ be a multiple of 8.
	-- Furthermore, this constant is internally re-used for the width of the data bus of a lane in the TTNoC.
	constant PI_WORD_WIDTH					: integer		:= 32;

	-- Number of supported periods
	-- This constants determines the number of periods that are supported by the Periodic Control System.
	-- Note that the size (with respect to logic elements / transistor count) of the Message Dispatcher (i.e., the EBU) scales linearly
	-- with this value.
	constant NR_PERIODS						: integer		:= to_integer (unsigned (CONF_TT_CONF.NR_PER)); -- 1;

	-- Period Enable 
	-- bit-wise period enable; 
	-- 1 for activation
	constant TTPERIOD_EN				    : std_logic_vector (63 downto 0)	:= CONF_TT_CONF.PER_EN; 
	constant ETPERIOD_EN				    : std_logic_vector (63 downto 0)	:= CONF_ET_CONF.PER_EN; 


	-- Index of the period bit of the highest period
	-- This constant refers to that bit in the time format of the global time base, which is the period bit of the highest/longest period.
	-- All lower/shorter periods are aligned to the right of this bit. The constant "PERIOD_DELTA" determines the distance in the
	-- time format of the global time base between the period bits of two neighbouring periods.
	constant MSB_PERIODBIT					: integer		:= 18;--to_integer (unsigned (CONF_TT_CONF.MSB_PER_BIT)); --21;

	-- Index of the macro tick bit
	-- This constant is the positional index of that bit in the time format of the global time base, which is used as the macro tick.
	-- Note that the width of the time format of the global time base is hard-coded to 64 bit. The index base is 0.
	constant MACROTICK_BIT					: integer		:= 6;

	-- Width of the phase offset
	-- This constant identifies the number that corresponds to the width of a phase slice of a period's phase in the time format of the
	-- global time base. For a value of X, the setting of this constant results into 2^X offsets for the given period. Each of these offsets
	-- has the local granularity according to the least significant bit of its phase slice.
	constant TTPHASESLICE_WIDTH				: integer		:= 12 ; --to_integer (unsigned (CONF_TT_CONF.PHSLICE_WDTH)); -- 8;
	constant ETPHASESLICE_WIDTH				: integer		:= to_integer (unsigned (CONF_ET_CONF.PHSLICE_WDTH)); -- 10;

	constant TIMELY_BLOCK_ACTIVE			: std_logic := timely_block_enabled (PROJECT_PATH & INITDIR & HWCONFIGFILE);


	-- Distance between two period bits ("period delta")
	-- This constant specifies the distance (in number of bits) between the period bits of two successive periods.
	-- For a given value X, the period bit of period A and period B are X bits apart from each other. As a result,
	-- period A is 2^X times the duration of period B. Usually, a value of X=1 is convenient, so that a the next
	-- higher period is the double duration of a specific period. Any higher value would stretch the boundaries of
	-- phase slices of periods among the time format of the global time base.
	constant PERIOD_DELTA					: integer		:= to_integer (unsigned (CONF_ET_CONF.PER_DELTA)); -- 1;

	-- Top value of Receive Window Counter
	-- This constant defines the number of clock cycles of the system operation frequency, which span the receive window on receive operations.
	constant RECVWIN_TOPVALUE				: integer		:= 64;

	-- HA TODO: a seperate file should be added for SAFEPOWER parameters
	constant PHYNAME_WIDTH				: integer		:= 32;
	constant LOGNAME_WIDTH				: integer		:= 32;


	-- correlation between axi address and noc addresses
	constant C_TILEID_HIGH			: integer := 31;
    constant C_TILEID_LOW                : integer := 24;
    constant C_PORTID_HIGH            : integer := 23;
    constant C_PORTID_LOW                : integer := 16;
	constant C_LAST_BURST_BIT		: integer := 15;
	constant C_PORT_ADDR_RANGE	: integer := 14;
	constant C_PORT_STATUS_BIT	: integer := 14;


-- reconfiguration parameters
    constant      count1_length          :   integer :=4; 
    constant      nqd_port_length        :   integer :=7;
    constant      nqd_buffer_length      :   integer :=9; 
    constant      MINT_initialization    :   std_logic_vector (63 downto 0):= x"000000000000000F";
    constant      DEST_initialization    :   std_logic_vector (31 downto 0):= x"0000000F";
    constant      port_EN_initialization :   std_logic :='1';
    constant      preamble_byte          :   std_logic_vector (7 downto 0):="01011010"; 
    constant      reserved_E0            :   std_logic_vector (20 downto 0) :=(others => '0');
    constant      error_length           :   integer :=5;

	constant C_MONP_NQDMSG_WIDTH		 : integer := 12;  
	constant C_MONP_MSGLEN_WIDTH		 : integer := 16; 


end system_parameter;
