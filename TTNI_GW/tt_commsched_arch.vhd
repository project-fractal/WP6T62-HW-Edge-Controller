--------------------------------------------------------------------------------------------------------
-- Project		: SAFEPOWER
-- Module       : TTCommSched
-- File			: ttcommsched.vhd
-- Author		: Hamidreza Ahmadian
-- created		: September, 1st 2015
-- last mod. by	: Hamidreza Ahmadian
-- last mod. on	:
-- contents		: architecture of the time-triggered communication schedule memory
--------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------
-- library includes
--------------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;	-- for conv_integer
use IEEE.std_logic_unsigned.all;
use std.textio.all;
-- use IEEE.std_logic_textio; 


library SAFEPOWER;
use SAFEPOWER.TTEL.all;        		-- constants, datatypes, and component declarations of the current TISS
use SAFEPOWER.memorymap.all;		-- helper subprograms for mapping between record datatypes and physical memory
use SAFEPOWER.ttel_parameter.all;	-- for TTCOMMSCHED_SIZE

library SYSTEMS;
use SYSTEMS.system_parameter.all;	-- parameters of the current NoC instance
use SYSTEMS.auxiliary.all;         	-- for extracting configuration parameters from the files


Library UNISIM;
use UNISIM.vcomponents.all;

Library UNIMACRO;
use UNIMACRO.vcomponents.all;


architecture xil_7series of ttcommsched is

  constant WE_WIDTH : integer := GetWEWidth("18Kb", "7SERIES", TTCOMMSCHED_DATA_WIDTH);
  constant C_WE     : std_logic_vector (WE_WIDTH - 1 downto 0) := (others => '1');
  constant C_RDADDR_WIDTH : integer := GetADDRWidth(TTCOMMSCHED_DATA_WIDTH, "18Kb", "7SERIES");

  ---------------------------------------------------------------------------------------------------
  -- local signals for memory mapping
  ---------------------------------------------------------------------------------------------------

  	signal srddata		:	vt_ttcommsched;
    signal swrdata		:	vt_ttcommsched;
    signal reset      : std_logic := '1';
    signal srdaddr    : std_logic_vector (C_RDADDR_WIDTH - 1 downto 0);
    signal swraddr    : std_logic_vector (C_RDADDR_WIDTH - 1 downto 0);
    signal rden         : std_logic; 
    signal zeros        : std_logic_vector (6 downto 0) := (others => '0');
    signal data_in      : std_logic_vector (31 downto 0);
    signal data_out      : std_logic_vector (31 downto 0);
    
  begin
    rden <= '1';--, '0' after 15 ns, '1' after 155 ns; --, '0' after 7420 ns;
  ---------------------------------------------------------------------------------------------------
  -- mapping between physical memory and record datatype
  ---------------------------------------------------------------------------------------------------
  srdaddr (TTCOMMSCHED_ADDR_WIDTH - 1 downto 0) <= rdaddress;
  srdaddr (C_RDADDR_WIDTH - 1 downto TTCOMMSCHED_ADDR_WIDTH ) <= (others => '0');

  swraddr (TTCOMMSCHED_ADDR_WIDTH - 1 downto 0) <= wraddress;
  swraddr (C_RDADDR_WIDTH - 1 downto TTCOMMSCHED_ADDR_WIDTH ) <= (others => '0');
-- helper process to introduce variables for the VHDL procedure (syntactic sugar!)
  	process(srddata, wrdata)
  		-- data read from the RAM
  		variable v_srddata	:	vt_ttcommsched;
  		-- record which is ready to be used by the dispatcher
  		variable v_rddata	:	t_ttcommsched;

  		-- data to be written into the RAM
  		variable v_swrdata	:	vt_ttcommsched;
  		-- record which is ready to be used by the dispatcher
  		variable v_wrdata	:	t_ttcommsched;
  	begin

  		-- prepare variables
  		v_srddata := srddata;
  		v_wrdata := wrdata;

  		-- map record datatype to physical memory
			-- vector2record
			map_ttcommsched_out(d=>v_rddata, v=>v_srddata);	-- rddata <= srddata
			-- record2vector
			map_ttcommsched_in(d=>v_wrdata, v=>v_swrdata);	-- swrdata <= wrdata

  		-- write back to the real signals
  		rddata <= v_rddata;
  		swrdata <= v_swrdata;

  	end process;

    -- process for the reset
    process (clk)
    begin
      if rising_edge (clk) then
        if reset = '1' then
          reset <= '0';
        end if;
      end if;
    end process;

    ttcommsched_inst: BRAM_SDP_MACRO
    generic map (
      BRAM_SIZE => "18Kb", -- Target BRAM, "18Kb" or "36Kb"
      DEVICE => "7SERIES", -- Target device: "VIRTEX5", "VIRTEX6", "7SERIES", "SPARTAN6"
      -- HA: TODO: values between 37 - 72 is only valid for 36Kb!!!
      WRITE_WIDTH => TTCOMMSCHED_DATA_WIDTH,    -- Valid values are 1-72 (37-72 only valid when BRAM_SIZE="36Kb")
      READ_WIDTH => TTCOMMSCHED_DATA_WIDTH,     -- Valid values are 1-72 (37-72 only valid when BRAM_SIZE="36Kb")
      DO_REG => 0, -- Optional output register (0 or 1)
--      INIT_FILE => "NONE",
--      INIT_FILE => "/home/hamid/Projects/LRS/memfiles/ttcommsched.mem",
     -- INIT_FILE => InitFile,

      SIM_COLLISION_CHECK => "ALL", -- Collision check enable "ALL", "WARNING_ONLY",
                                  -- "GENERATE_X_ONLY" or "NONE"
      SRVAL => X"000000000000000000", --  Set/Reset value for port output
      WRITE_MODE => "WRITE_FIRST", -- Specify "READ_FIRST" for same clock or synchronous clocks
                                 --  Specify "WRITE_FIRST for asynchrononous clocks on ports
      INIT => X"000000000000000000", --  Initial values on output port
      -- The following INIT_xx declarations specify the initial contents of the RAM
        -- 8*8*4= 256 bits or 32 bytes or 8 words (of 32 bits)
--        INIT_00 => b"0010000010000001100010000000100100000000000100000100010000010000001100000000010000010",
--        INIT_00 => b"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000110001000000100100000000001000001000100000000000110000000010000010",
--        INIT_00 => X"0000000000000000000000000000000000000000000020031024008220030082",
        INIT_00 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_01 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_02 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_03 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_04 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_05 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_06 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_07 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_08 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_09 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_0A => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_0B => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_0C => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_0D => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_0E => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_0F => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_10 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_11 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_12 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_13 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_14 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_15 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_16 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_17 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_18 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_19 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_1A => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_1B => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_1C => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_1D => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_1E => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_1F => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_20 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_21 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_22 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_23 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_24 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_25 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_26 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_27 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_28 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_29 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_2A => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_2B => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_2C => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_2D => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_2E => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_2F => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_30 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_31 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_32 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_33 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_34 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_35 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_36 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_37 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_38 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_39 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_3A => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_3B => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_3C => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_3D => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_3E => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_3F => X"0000000000000000000000000000000000000000000000000000000000000000",

         -- The next set of INITP_xx are for the parity bits
--        INITP_00 => X"0000000000000000000000000000000000000000000000000000000000000104",
        INITP_00 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INITP_01 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INITP_02 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INITP_03 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INITP_04 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INITP_05 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INITP_06 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INITP_07 => X"0000000000000000000000000000000000000000000000000000000000000000")

    
    port map (
      DO => srddata,          -- Output read data port, width defined by READ_WIDTH parameter
      DI => swrdata,          -- Input write data port, width defined by WRITE_WIDTH parameter
      RDADDR => srdaddr,    -- Input read address, width defined by read port depth
      RDCLK => clk,           -- 1-bit input read clock
      RDEN => rden,            -- 1-bit input read port enable
      REGCE => '1',           -- 1-bit input read output register enable
      RST => reset,           -- 1-bit input reset
      WE => C_WE,             -- Input write enable, width defined by write port depth
      WRADDR => swraddr,    -- Input write address, width defined by write port depth
      WRCLK => clk,           -- 1-bit input write clock
      WREN => wren            -- 1-bit input write port enable
    );
  end xil_7series;
