-----------------------------------------------------------------------------------------------------------
-- Project		: TTSoC-NG
-- Module       : package "memorymap" / Memories of the TISS
-- File			: memorymap.vhd
-- Author		: Christian Paukovits
-- created		: March, 3rd 2009
-- last mod. by	: Hamidreza Ahmadian
-- last mod. on	:
-- contents		: helper functions and helper procedures
-- usage		: map record datatypes to vector datatypes of physical memories
-----------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------------
-- library includes
-----------------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library SAFEPOWER;
use SAFEPOWER.ttel_parameter.all;	-- parameters of the current TTEL
use SAFEPOWER.TTEL.all;        		-- constants, datatypes, and component declarations of the current TTEL
--use SAFEPOWER.stnoc.all;        	-- constants, datatypes, and component declarations of the STNoC (for t_lane_data)

library SYSTEMS;
use SYSTEMS.auxiliary.all;         	-- helper functions and helper procedures
use SYSTEMS.configman.all;         	-- for extracting configuration parameters from the files
use SYSTEMS.system_parameter.all;	-- parameters of the current NoC instance

-----------------------------------------------------------------------------------------------------------
-- package "memorymap"
-----------------------------------------------------------------------------------------------------------

package memorymap is

	-- procedure map_pcfg_in(d : in t_pcfg; v : out std_logic_vector(PCFGMEM_DATA_WIDTH-1 downto 0));
	-- procedure map_pcfg_out(d: out t_pcfg; v : in std_logic_vector(PCFGMEM_DATA_WIDTH-1 downto 0));
	procedure map_ttcommsched_in(d : in t_ttcommsched; v : out std_logic_vector(TTCOMMSCHED_DATA_WIDTH-1 downto 0));
	procedure map_ttcommsched_out(d: out t_ttcommsched; v : in std_logic_vector(TTCOMMSCHED_DATA_WIDTH-1 downto 0));
	procedure map_etcommsched_in(d : in t_etcommsched; v : out std_logic_vector(ETCOMMSCHED_DATA_WIDTH-1 downto 0));
	procedure map_etcommsched_out(d: out t_etcommsched; v : in std_logic_vector(ETCOMMSCHED_DATA_WIDTH-1 downto 0));
	-- procedure map_bcfg_in(d : in t_bcfg; v : out std_logic_vector(BCFGMEM_DATA_WIDTH-1 downto 0));
	-- procedure map_bcfg_out(d: out t_bcfg; v : in std_logic_vector(BCFGMEM_DATA_WIDTH-1 downto 0));
	-- procedure map_ri_in(d : in t_ri; v : out std_logic_vector(RIMEM_DATA_WIDTH-1 downto 0));
	-- procedure map_ri_out(d: out t_ri; v : in std_logic_vector(RIMEM_DATA_WIDTH-1 downto 0));
	-- procedure map_psync_in(d : in t_psync; v : out std_logic_vector(PSYNCMEM_DATA_WIDTH-1 downto 0));
	-- procedure map_psync_out(d: out t_psync; v : in std_logic_vector(PSYNCMEM_DATA_WIDTH-1 downto 0));
--	procedure map_pcfg (d: out rt_pcfg; v : in t_pcfg_entry);
	function map_pcfg (PCFG_ENTRY : in t_pcfg_entry) return rt_pcfg; 

end memorymap;

package body memorymap is

-----------------------------------------------------------------------------------------------------------
-- mapping of Time-Triggered Communication Schedule
-----------------------------------------------------------------------------------------------------------

	-- incoming record datatype to physical memory
	procedure map_ttcommsched_in(d : in t_ttcommsched; v : out std_logic_vector(TTCOMMSCHED_DATA_WIDTH-1 downto 0)) is
	begin
		v(TTCOMMSCHED_ADDR_WIDTH-1 downto 0) := d.NextPtr;
		v(TTPHASESLICE_WIDTH+TTCOMMSCHED_ADDR_WIDTH-1 downto TTCOMMSCHED_ADDR_WIDTH) := d.Instant;
		v(PORTID_WIDTH+TTPHASESLICE_WIDTH+TTCOMMSCHED_ADDR_WIDTH-1 downto TTPHASESLICE_WIDTH+TTCOMMSCHED_ADDR_WIDTH) := d.PortId;
		v(BRANCHID_WIDTH+PORTID_WIDTH+TTPHASESLICE_WIDTH+TTCOMMSCHED_ADDR_WIDTH-1 downto PORTID_WIDTH+TTPHASESLICE_WIDTH+TTCOMMSCHED_ADDR_WIDTH) := d.BranchId;
	end procedure map_ttcommsched_in;

	-- outgoing record datatype from physical memory
	procedure map_ttcommsched_out(d: out t_ttcommsched; v : in std_logic_vector(TTCOMMSCHED_DATA_WIDTH-1 downto 0)) is
	begin
		d.NextPtr := v(TTCOMMSCHED_ADDR_WIDTH-1 downto 0);
		d.Instant := v(TTPHASESLICE_WIDTH+TTCOMMSCHED_ADDR_WIDTH-1 downto TTCOMMSCHED_ADDR_WIDTH);
		d.PortId := v(PORTID_WIDTH+TTPHASESLICE_WIDTH+TTCOMMSCHED_ADDR_WIDTH-1 downto TTPHASESLICE_WIDTH+TTCOMMSCHED_ADDR_WIDTH);
		d.BranchId := v(BRANCHID_WIDTH+PORTID_WIDTH+TTPHASESLICE_WIDTH+TTCOMMSCHED_ADDR_WIDTH-1 downto PORTID_WIDTH+TTPHASESLICE_WIDTH+TTCOMMSCHED_ADDR_WIDTH);
	end procedure map_ttcommsched_out;

-----------------------------------------------------------------------------------------------------------
-- mapping of Time-Triggered Communication Schedule
-----------------------------------------------------------------------------------------------------------

	-- incoming record datatype to physical memory
	procedure map_etcommsched_in(d : in t_etcommsched; v : out std_logic_vector(ETCOMMSCHED_DATA_WIDTH-1 downto 0)) is
	begin
		v(ETCOMMSCHED_ADDR_WIDTH-1 downto 0) := d.NextPtr;
		v(ETPHASESLICE_WIDTH+ETCOMMSCHED_ADDR_WIDTH-1 downto ETCOMMSCHED_ADDR_WIDTH) := d.Instant;
		v(OPID_WIDTH+ETPHASESLICE_WIDTH+ETCOMMSCHED_ADDR_WIDTH-1 downto ETPHASESLICE_WIDTH+ETCOMMSCHED_ADDR_WIDTH) := d.OpId;
	end procedure map_etcommsched_in;

	-- outgoing record datatype from physical memory
	procedure map_etcommsched_out(d: out t_etcommsched; v : in std_logic_vector(ETCOMMSCHED_DATA_WIDTH-1 downto 0)) is
	begin
		d.NextPtr := v(ETCOMMSCHED_ADDR_WIDTH-1 downto 0);
		d.Instant := v(ETPHASESLICE_WIDTH+ETCOMMSCHED_ADDR_WIDTH-1 downto ETCOMMSCHED_ADDR_WIDTH);
		d.OpId := v(OPID_WIDTH+ETPHASESLICE_WIDTH+ETCOMMSCHED_ADDR_WIDTH-1 downto ETPHASESLICE_WIDTH+ETCOMMSCHED_ADDR_WIDTH);
	end procedure map_etcommsched_out;

-----------------------------------------------------------------------------------------------------------
-- mapping of Port Configuration 
-----------------------------------------------------------------------------------------------------------
	function map_pcfg (PCFG_ENTRY : in t_pcfg_entry) return rt_pcfg is
   variable pcfg_record : rt_pcfg; 
    begin
        pcfg_record.CONF_MINT := PCFG_ENTRY(TIMEFORMAT_COUNTER_WIDTH - 1 downto 0);
    pcfg_record.CONF_DEST := PCFG_ENTRY(TIMEFORMAT_COUNTER_WIDTH + PHYNAME_WIDTH - 1 downto TIMEFORMAT_COUNTER_WIDTH);
    pcfg_record.CONF_QUE_LEN := to_integer (unsigned (PCFG_ENTRY (TIMEFORMAT_COUNTER_WIDTH + PHYNAME_WIDTH + QUELEN_WIDTH - 1 downto TIMEFORMAT_COUNTER_WIDTH + PHYNAME_WIDTH)));   
    pcfg_record.CONF_BUF_SIZ := to_integer (unsigned (PCFG_ENTRY (PORTCONFIG_DATA_WIDTH - 9 downto PORTCONFIG_DATA_WIDTH - BUFSIZ_WIDTH - 8))); 
--        d.CONF_SEM := "STATE" when v(TIMEFORMAT_COUNTER_WIDTH + 4) = '1' else "EVENT";
    pcfg_record.CONF_SEM := PCFG_ENTRY(PORTCONFIG_DATA_WIDTH - 8) ;
    pcfg_record.CONF_DIR := PCFG_ENTRY(PORTCONFIG_DATA_WIDTH - 7) ;
    pcfg_record.CONF_TYPE := PCFG_ENTRY(PORTCONFIG_DATA_WIDTH - 5 downto PORTCONFIG_DATA_WIDTH - 6);        -- todo: 2 and 3!
    pcfg_record.CONF_EN := PCFG_ENTRY(PORTCONFIG_DATA_WIDTH - 4) ;
  

    return pcfg_record; 
    end ;


end memorymap;
