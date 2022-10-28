------------------------------------------------------------------------------------------------------------
-- Project		: SAFEPOWER
-- Module       : EBU
-- File			: ebu.vhd
-- Author		: Hamidreza Ahmadian
-- created		: September, 1st 2015
-- last mod. by	: Hamidreza Ahmadian
-- last mod. on	:
-- contents		: constants, datatypes, and component declarations of the TTEL
------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------
-- library includes
------------------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

library SAFEPOWER;
use SAFEPOWER.ttel_parameter.all;	-- parameters of the current TTEL
--use SAFEPOWER.stnoc_parameter.all;        	-- constants, datatypes, and component declarations of the STNoC
-- use SAFEPOWER.auxiliary.all;    	-- helper functions and helper procedures

library SYSTEMS;
use SYSTEMS.auxiliary.all;         	-- helper functions and helper procedures
use SYSTEMS.configman.all;         	-- for extracting configuration parameters from the files
use SYSTEMS.system_parameter.all;	-- parameters of the current NoC instance


-----------------------------------------------------------------------------------------------------
-- package "TTEL"
-----------------------------------------------------------------------------------------------------

package TTEL is

-----------------------------------------------------------------------------------------------------
-- constants & datatypes
-----------------------------------------------------------------------------------------------------


	constant PORTMEM_SIZE								: integer := 64;

	-- width of the address bus of the Time-Triggered Communication Schedule
	constant TTCOMMSCHED_ADDR_WIDTH			: integer		:= ld(TTCOMMSCHED_SIZE);
	-- width of the address bus of the Event-Triggered Communication Schedule
	constant ETCOMMSCHED_ADDR_WIDTH			: integer		:= ld(ETCOMMSCHED_SIZE);

	-- width of the address bus of the Burst Configuration Memory
	-- constant BCFGMEM_ADDR_WIDTH				: integer		:= ld(BCFGMEM_SIZE);
	-- width of the port identifier and address bus of Port Configuration Memory and Port Synchronization Memory


	-- width of the addresses in the Port Memory / width of the address bus of the Port Interface
	--Adele Add
	constant PORTID_WIDTH					: integer		:= ld(MAX_NR_PORTS);
	--constant PORTID_WIDTH					: integer		:= 4;--ADDed by adele
	
	constant BRANCHID_WIDTH                 : integer      := ld(MAX_NR_BRANCHES);

	-- width of the addresses in the Port Memory / width of the address bus of the Port Interface
	constant OPID_WIDTH					: integer		:= 2; --ld(NR_PORTS);
	constant PORTDATA_WIDTH                                 : integer := 32;


    constant ETCLOSE  : std_logic_vector (OPID_WIDTH - 1 downto 0) := b"10";
    constant ETOPEN   : std_logic_vector (OPID_WIDTH - 1 downto 0) := b"01";


  -- datatype for the counter vector of the time format of the global time base
	subtype t_timeformat is std_logic_vector(TIMEFORMAT_COUNTER_WIDTH-1 downto 0);


  -- datatype for the address bus / "Next" field of the Time-Triggered Communication Schedule
  subtype t_ttcommsched_addr is std_logic_vector(TTCOMMSCHED_ADDR_WIDTH-1 downto 0);
	-- datatype for the address bus / "Next" field of the Event-Triggered Communication Schedule
  subtype t_etcommsched_addr is std_logic_vector(ETCOMMSCHED_ADDR_WIDTH-1 downto 0);

  -- datatype for the phase slice in the time format of the global time base
  subtype t_ttphaseslice is std_logic_vector(TTPHASESLICE_WIDTH-1 downto 0);
  subtype t_etphaseslice is std_logic_vector(ETPHASESLICE_WIDTH-1 downto 0);

  -- -- datatype for reference to data words in the Burst Configuration Memory
  -- subtype t_burstid is std_logic_vector(BCFGMEM_ADDR_WIDTH-1 downto 0);
  -- datatype for port identifier and address bus of Port Configuration Memory and Port Synchronization Memory
  subtype t_portid is std_logic_vector(PORTID_WIDTH-1 downto 0);
  subtype t_branchid is std_logic_vector (BRANCHID_WIDTH-1 downto 0);
  -- datatype of data words in the Port Memory / Port Interface
  -- subtype t_pi_word is std_logic_vector(PI_WORD_WIDTH-1 downto 0);
  -- -- datatype of addresses in the Port Memory / Port Interface
  -- --subtype t_pi_addr is std_logic_vector(PI_ADDR_WIDTH-1 downto 0);
  -- -- datatype for the address bus of the Routing Information Memory
  -- subtype t_ri_addr is std_logic_vector(RIMEM_ADDR_WIDTH-1 downto 0);
  -- -- datatype for length of routing information
  -- subtype t_ri_len is std_logic_vector(RILEN_WIDTH-1 downto 0);
	--
	--subtype t_porttype is std_logic_vector (1 downto 0);
	subtype t_porttype is std_logic_vector (1 downto 0);


	type vt_porttype   	is array (integer range <>) of t_porttype;

	subtype t_phyname is std_logic_vector (PHYNAME_WIDTH - 1 downto 0);        -- ClusterID, NodeID, TileID, PortID (each 8 bits)
	type at_phyname    is array (integer range <>) of t_phyname;

	subtype t_opid is std_logic_vector (1 downto 0);
  -- datatype for entries of the Time-Triggered Communication Schedule
  type t_ttcommsched is
  record
    BranchId    :   t_branchid;         -- refernce to the branch
    NextPtr		:	t_ttcommsched_addr;	-- next pointer
    Instant		:	t_ttphaseslice;		-- instant field
    PortId		:	t_portid;			-- reference to the port
  end record;

  -- width/sum of all elements of the record data type t_ttcommsched
   constant TTCOMMSCHED_DATA_WIDTH			: integer		:= TTCOMMSCHED_ADDR_WIDTH + TTPHASESLICE_WIDTH + PORTID_WIDTH + BRANCHID_WIDTH;

	 type t_etcommsched is
   record
     NextPtr			:	t_etcommsched_addr;	-- next pointer
     Instant			:	t_etphaseslice;		-- instant field
     OpId	      	:	t_opid;			-- reference to the operation
   end record;

   -- width/sum of all elements of the record data type t_ttcommsched
    constant ETCOMMSCHED_DATA_WIDTH			: integer		:= ETCOMMSCHED_ADDR_WIDTH + ETPHASESLICE_WIDTH + OPID_WIDTH;


	 -- datatype for the address bus / "Next" field of the Time-Triggered Communication Schedule
   subtype vt_ttcommsched is std_logic_vector(TTCOMMSCHED_DATA_WIDTH-1 downto 0);
	 -- datatype for the address bus / "Next" field of the Event-Triggered Communication Schedule
   subtype vt_etcommsched is std_logic_vector(ETCOMMSCHED_DATA_WIDTH-1 downto 0);



  type rt_pcfg is
  record
    CONF_TYPE		: t_porttype;	-- type of the port
    CONF_DIR        : std_logic; -- string (1 to 5);		-- semantics of the port, State or Event
    CONF_SEM        : std_logic; -- string (1 to 5);		-- semantics of the port, State or Event
    CONF_EN         : std_logic; 
    CONF_DEST	    : t_phyname;			-- destination which is coupled with the port
    CONF_BUF_SIZ    : integer;
    CONF_QUE_LEN    : integer; 
    CONF_MINT       : t_timeformat;         -- mint value for RC ports
  end record;

  type art_pcfg is array (0 to MAX_NR_PORTS) of rt_pcfg;
    

end TTEL;
