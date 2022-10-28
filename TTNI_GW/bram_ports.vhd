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
library UNIMACRO;
use unimacro.Vcomponents.all;
-- BRAM_SDP_MACRO: Simple Dual Port RAM
-- 7 Series
-- Xilinx HDL Libraries Guide, version 14.7
-- Note - This Unimacro model assumes the port directions to be "downto".
-- Simulation of this model with "to" in the port directions could lead to erroneous results.
-----------------------------------------------------------------------
-- READ_WIDTH    | BRAM_SIZE | READ Depth | RDADDR Width | --
-- WRITE_WIDTH | | WRITE Depth | WRADDR Width | WE Width --
-- ============|===========|=============|==============|============--
-- 37-72 | "36Kb" | 512 | 9-bit | 8-bit --
-- 19-36 | "36Kb" | 1024 | 10-bit | 4-bit --
-- 19-36 | "18Kb" | 512 | 9-bit | 4-bit --
-- 10-18 | "36Kb" | 2048 | 11-bit | 2-bit --
-- 10-18 | "18Kb" | 1024 | 10-bit | 2-bit --
-- 5-9 | "36Kb" | 4096 | 12-bit | 1-bit --
-- 5-9 | "18Kb" | 2048 | 11-bit | 1-bit --
-- 3-4 | "36Kb" | 8192 | 13-bit | 1-bit --
-- 3-4 | "18Kb" | 4096 | 12-bit | 1-bit --
-- 2 | "36Kb" | 16384 | 14-bit | 1-bit --
-- 2 | "18Kb" | 8192 | 13-bit | 1-bit --
-- 1 | "36Kb" | 32768 | 15-bit | 1-bit --
-- 1 | "18Kb" | 16384 | 14-bit | 1-bit --
-----------------------------------------------------------------------
entity BRAM_Ports is
   generic
   (
	 	--WordWidth         : natural := 32;
	 	DATA_WIDTH        : natural := 36;
	 	Addr_Width        : natural := 10
	 );
	port
	(
	   clk		: in  std_logic;
	   reset    : in  std_logic;
	   
       wren		: in  std_logic;
       WRADDR   : in  std_logic_vector (Addr_Width-1 downto 0); 
       DI       : in  std_logic_vector (DATA_WIDTH-1 downto 0);    
         
       rden		: in  std_logic;
       RDADDR   : in  std_logic_vector (Addr_Width-1 downto 0);
       DO       : out std_logic_vector (DATA_WIDTH-1 downto 0)
);

end BRAM_Ports;

architecture xil_7series of BRAM_Ports is

    constant WE_WIDTH : integer := GetWEWidth("36Kb", "7SERIES", DATA_WIDTH);
    constant C_WE     : std_logic_vector (WE_WIDTH - 1 downto 0) := (others => '1');

begin
BRAM_inst : BRAM_SDP_MACRO
generic map(
    BRAM_SIZE => "36Kb", -- Target BRAM, "18Kb" or "36Kb"
    DEVICE => "7SERIES", -- Target device: "VIRTEX5", "VIRTEX6", "7SERIES", "SPARTAN6"
    WRITE_WIDTH => DATA_WIDTH, -- Valid values are 1-72 (37-72 only valid when BRAM_SIZE="36Kb")
    READ_WIDTH => DATA_WIDTH, -- Valid values are 1-72 (37-72 only valid when BRAM_SIZE="36Kb")
    DO_REG => 0, -- Optional output register (0 or 1)
    INIT_FILE => "NONE",
    SIM_COLLISION_CHECK => "ALL", -- Collision check enable "ALL", "WARNING_ONLY",
    -- "GENERATE_X_ONLY" or "NONE"
    SRVAL => X"000000000000000000", -- Set/Reset value for port output
    WRITE_MODE => "WRITE_FIRST", -- Specify "READ_FIRST" for same clock or synchronous clocks
    -- Specify "WRITE_FIRST for asynchrononous clocks on ports
    INIT => X"000000000000000000", -- Initial values on output port
    -- The following INIT_xx declarations specify the initial contents of the RAM
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
    -- The next set of INIT_xx are valid when configured as 36Kb
    INIT_40 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_41 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_42 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_43 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_44 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_45 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_46 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_47 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_48 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_49 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_4A => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_4B => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_4C => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_4D => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_4E => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_4F => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_50 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_51 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_52 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_53 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_54 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_55 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_56 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_57 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_58 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_59 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_5A => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_5B => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_5C => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_5D => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_5E => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_5F => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_60 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_61 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_62 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_63 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_64 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_65 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_66 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_67 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_68 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_69 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_6A => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_6B => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_6C => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_6D => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_6E => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_6F => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_70 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_71 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_72 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_73 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_74 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_75 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_76 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_77 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_78 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_79 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_7A => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_7B => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_7C => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_7D => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_7E => X"0000000000000000000000000000000000000000000000000000000000000000",
    INIT_7F => X"0000000000000000000000000000000000000000000000000000000000000000",
    -- The next set of INITP_xx are for the parity bits
    INITP_00 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INITP_01 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INITP_02 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INITP_03 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INITP_04 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INITP_05 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INITP_06 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INITP_07 => X"0000000000000000000000000000000000000000000000000000000000000000",
    -- The next set of INIT_xx are valid when configured as 36Kb
    INITP_08 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INITP_09 => X"0000000000000000000000000000000000000000000000000000000000000000",
    INITP_0A => X"0000000000000000000000000000000000000000000000000000000000000000",
    INITP_0B => X"0000000000000000000000000000000000000000000000000000000000000000",
    INITP_0C => X"0000000000000000000000000000000000000000000000000000000000000000",
    INITP_0D => X"0000000000000000000000000000000000000000000000000000000000000000",
    INITP_0E => X"0000000000000000000000000000000000000000000000000000000000000000",
    INITP_0F => X"0000000000000000000000000000000000000000000000000000000000000000")

    port map (
        DO => DO, -- Output read data port, width defined by READ_WIDTH parameter
        DI => DI, -- Input write data port, width defined by WRITE_WIDTH parameter
        RDADDR => RDADDR, -- Input read address, width defined by read port depth
        RDCLK => clk, -- 1-bit input read clock
        RDEN => rden, -- 1-bit input read port enable
        REGCE => '1', -- 1-bit input read output register enable
        RST => '0', -- 1-bit input reset
        WE => C_WE, -- Input write enable, width defined by write port depth
        WRADDR => WRADDR, -- Input write address, width defined by write port depth
        WRCLK => clk, -- 1-bit input write clock
        WREN => wren -- 1-bit input write port enable
    );
end xil_7series;
-- End of BRAM_SDP_MACRO_inst instantiation