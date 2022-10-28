------------------------------------------------------------------------------------------------------
-- Project		: SAFEPOWER
-- Module       : Configuration manager
-- File			: configman.vhd
-- Author		: Hamidreza Ahmadian
-- created		: September, 1st 2015
-- last mod. by	: Hamidreza Ahmadian
-- last mod. on	:
-- contents		: constants, datatypes, and component declarations of the ttel
------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------
-- library includes
------------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
-- use IEEE.std_logic_unsigned.all;
use IEEE.STD_LOGIC_TEXTIO.all;

library STD;
use STD.TEXTIO.all;

library unisim;
use unisim.vcomponents.all;
--use unisim.vpkg.all;

-----------------------------------------------------------------------------------------------------
-- package "configman"
-----------------------------------------------------------------------------------------------------

package configman is

    constant MAX_NR_TILES               : integer :=16; 
    constant MAX_NR_PORTS               : integer :=256;
    constant MAX_NR_BRANCHES            : integer := 16;
    constant PORTCONFIG_DATA_WIDTH      : integer := 128; 
    type at_nr_ports is array (0 to MAX_NR_TILES) of integer range 0 to MAX_NR_PORTS; 
    subtype t_pcfg_entry  is std_logic_vector (PORTCONFIG_DATA_WIDTH - 1 downto 0); 
    type at_pcfg is array (0 to MAX_NR_PORTS - 1) of t_pcfg_entry;
    type t_disp_conf is
    record
      MSB_PER_BIT        :    std_logic_vector (7 downto 0);    
      PER_DELTA          :    std_logic_vector (7 downto 0);    
      NR_PER             :    std_logic_vector (7 downto 0);
      PHSLICE_WDTH       :    std_logic_vector (7 downto 0);    
      PER_EN             :    std_logic_vector (63 downto 0);    
          
      
    end record;    
    
    impure function nr_tiles (file_name : string) return integer; 
    impure function timely_block_enabled (file_name : string) return std_logic; 
    impure function tt_config (file_name : string) return t_disp_conf; 
    impure function et_config (file_name : string) return t_disp_conf; 
    impure function nr_ports (file_name : string) return at_nr_ports;
    impure function nr_out_ports (file_name : string) return at_nr_ports;
    impure function ttel_pcfg (file_path, file_name : string; ttel_id : integer) return at_pcfg;
end configman;


---------------------------------------------------------------------------------------------------
-- body of the package "configman"
---------------------------------------------------------------------------------------------------

package body configman is
---------------------------------------------------------------------------------------------------
-- implementation of subprograms
----------------------------------------------------------------------------------------------------

    impure function ttel_pcfg (file_path, file_name : string; ttel_id : integer) return at_pcfg is
        file infile : text;
        variable i : integer := 0;
        variable good_data : boolean := false;
        variable open_status : file_open_status;
        variable pcfg_entry : t_pcfg_entry;
        variable ttel_pcfg   : at_pcfg; 
        variable data_line : line;
        variable ignore_line : boolean := false;
        constant INIT_FILE : string := file_path & "ttel_" & integer'image (ttel_id) & "/" & file_name;
        
      begin
        -- if (INIT_FILE /= "NONE") then
          file_open(open_status, infile, INIT_FILE, read_mode); 
          while not endfile(infile) loop
            readline(infile, data_line);
    --        while (data_line /= null and data_line'length > 0) loop
              hread(data_line, pcfg_entry, good_data);
              ttel_pcfg (i) := pcfg_entry;
              i := i + 1; 
    --          end loop;
          end loop;
          file_close (infile); 
        -- end if;
        return ttel_pcfg;
    end; 



  impure function nr_tiles (file_name : string) return integer is
      file infile : text;
      variable good_data : boolean := false;
      variable open_status : file_open_status;
      variable output_nr_tiles : std_logic_vector (7 downto 0);
      variable data_line : line;
      variable ignore_line : boolean := false;
      
    begin
      report "hello world!"; 
      file_open(open_status, infile, file_name, read_mode);
      readline(infile, data_line);
      hread(data_line, output_nr_tiles, good_data);
      file_close (infile); 
      return to_integer (unsigned (output_nr_tiles));
  end;

  impure function timely_block_enabled (file_name : string) return std_logic is
      file infile : text;
      variable i : integer := 0;
      variable good_data : boolean := false;
      variable open_status : file_open_status;
      variable tb_enabled : std_logic_vector (15 downto 0);
      variable data_line : line;
      variable ignore_line : boolean := false;
      variable hwcfg_entry : std_logic_vector (15 downto 0);
      
    begin
      file_open(open_status, infile, file_name, read_mode);
      while not endfile(infile) loop
        readline(infile, data_line);
--        while (data_line /= null and data_line'length > 0) loop
          hread(data_line, hwcfg_entry, good_data);
          if i = 1 then 
            tb_enabled := hwcfg_entry;
          end if; 
          i := i + 1; 
--          end loop;
      end loop;
      file_close (infile); 
      return tb_enabled (0); 
  end;

  impure function tt_config (file_name : string) return t_disp_conf is
      file infile : text;
      variable i : integer := 0;
      variable good_data : boolean := false;
      variable open_status : file_open_status;
      variable data_line : line;
      variable ignore_line : boolean := false;
      variable disp_cfg_entry : std_logic_vector (95 downto 0);
      variable des_config : t_disp_conf;
      
    begin
      file_open(open_status, infile, file_name, read_mode);
      while not endfile(infile) loop
        readline(infile, data_line);
--        while (data_line /= null and data_line'length > 0) loop
          hread(data_line, disp_cfg_entry, good_data);
          if i = 2 then 
            des_config.PER_EN := disp_cfg_entry (63 downto 0);
            des_config.PHSLICE_WDTH := disp_cfg_entry (71 downto 64);
            des_config.NR_PER := disp_cfg_entry (79 downto 72);
            des_config.PER_DELTA := disp_cfg_entry (87 downto 80);
            des_config.MSB_PER_BIT := disp_cfg_entry (95 downto 88);
          end if; 
          i := i + 1; 
--          end loop;
      end loop;
      file_close (infile); 
      return des_config; 
  end;


  impure function et_config (file_name : string) return t_disp_conf is
      file infile : text;
      variable i : integer := 0;
      variable good_data : boolean := false;
      variable open_status : file_open_status;
      variable data_line : line;
      variable ignore_line : boolean := false;
      variable disp_cfg_entry : std_logic_vector (95 downto 0);
      variable des_config : t_disp_conf;
      
    begin
      file_open(open_status, infile, file_name, read_mode);
      while not endfile(infile) loop
        readline(infile, data_line);
--        while (data_line /= null and data_line'length > 0) loop
          hread(data_line, disp_cfg_entry, good_data);
          if i = 3 then 
            des_config.PER_EN := disp_cfg_entry (63 downto 0);
            des_config.PHSLICE_WDTH := disp_cfg_entry (71 downto 64);
            des_config.NR_PER := disp_cfg_entry (79 downto 72);
            des_config.PER_DELTA := disp_cfg_entry (87 downto 80);
            des_config.MSB_PER_BIT := disp_cfg_entry (95 downto 88);
          end if; 
          i := i + 1; 
--          end loop;
      end loop;
      file_close (infile); 
      return des_config; 
  end;

  
  impure function nr_ports (file_name : string) return at_nr_ports is
    file infile : text;
    variable i : integer := 0;
    variable good_data : boolean := false;
    variable open_status : file_open_status;
    variable hwcfg_entry : std_logic_vector (15 downto 0);
    variable output_nr_ports   : at_nr_ports; 
    variable data_line : line;
    variable ignore_line : boolean := false;
  begin
    -- if (INIT_FILE /= "NONE") then
      file_open(open_status, infile, file_name, read_mode);
      while not endfile(infile) loop
        readline(infile, data_line);
--        while (data_line /= null and data_line'length > 0) loop
          hread(data_line, hwcfg_entry, good_data);
          if i > 3 then 
            output_nr_ports (i - 4) := to_integer (unsigned (hwcfg_entry (15 downto 8)));
         end if; 
         i := i + 1; 
--          end loop;
      end loop;
      file_close (infile);
    -- end if;
    return output_nr_ports;
  end;



  impure function nr_out_ports (file_name : string) return at_nr_ports is
    file infile : text;
    variable i : integer := 0;
    variable good_data : boolean := false;
    variable open_status : file_open_status;
    variable hwcfg_entry : std_logic_vector (15 downto 0);
    variable output_nr_out_ports   : at_nr_ports; 
    variable data_line : line;
    variable ignore_line : boolean := false;
  begin
    -- if (INIT_FILE /= "NONE") then
      file_open(open_status, infile, file_name, read_mode);
      while not endfile(infile) loop
        readline(infile, data_line);
--        while (data_line /= null and data_line'length > 0) loop
          hread(data_line, hwcfg_entry, good_data);
          if i > 3 then 
            output_nr_out_ports (i - 4) := to_integer (unsigned (hwcfg_entry (7 downto 0)));
         end if; 
         i := i + 1; 
--          end loop;
      end loop;
      file_close (infile); 
    -- end if;
    return output_nr_out_ports;
  end;



end configman;
