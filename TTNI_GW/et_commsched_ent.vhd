---------------------------------------------------------------------------------------------------
-- Project		: SAFEPOWER
-- Module       : TTCommSched
-- File			: etcommsched.vhd
-- Author		: Hamidreza Ahmadian
-- created		: September, 1st 2015
-- last mod. by	: Hamidreza Ahmadian
-- last mod. on	:
-- contents		: architecture of the time-triggered communication schedule memory
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
-- library includes
---------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;	-- for conv_integer
use IEEE.std_logic_unsigned.all;

library SAFEPOWER;
use SAFEPOWER.TTEL.all;        		-- constants, datatypes, and component declarations of the current TISS
use SAFEPOWER.memorymap.all;		-- helper subprograms for mapping between record datatypes and physical memory

library SYSTEMS;
use SYSTEMS.system_parameter.all;	-- parameters of the current NoC instance
use SYSTEMS.auxiliary.all;         	-- for extracting configuration parameters from the files


Library UNISIM;
use UNISIM.vcomponents.all;

Library UNIMACRO;
use UNIMACRO.vcomponents.all;


-----------------------------------------------------------------------
--  READ_WIDTH | BRAM_SIZE | READ Depth  | RDADDR Width |            --
-- WRITE_WIDTH |           | WRITE Depth | WRADDR Width |  WE Width  --
-- ============|===========|=============|==============|============--
--    37-72    |  "36Kb"   |      512    |     9-bit    |    8-bit   --
--    19-36    |  "36Kb"   |     1024    |    10-bit    |    4-bit   --
--    19-36    |  "18Kb"   |      512    |     9-bit    |    4-bit   --
--    10-18    |  "36Kb"   |     2048    |    11-bit    |    2-bit   --
--    10-18    |  "18Kb"   |     1024    |    10-bit    |    2-bit   --
--     5-9     |  "36Kb"   |     4096    |    12-bit    |    1-bit   --
--     5-9     |  "18Kb"   |     2048    |    11-bit    |    1-bit   --
--     3-4     |  "36Kb"   |     8192    |    13-bit    |    1-bit   --
--     3-4     |  "18Kb"   |     4096    |    12-bit    |    1-bit   --
--       2     |  "36Kb"   |    16384    |    14-bit    |    1-bit   --
--       2     |  "18Kb"   |     8192    |    13-bit    |    1-bit   --
--       1     |  "36Kb"   |    32768    |    15-bit    |    1-bit   --
--       1     |  "18Kb"   |    16384    |    14-bit    |    1-bit   --
-----------------------------------------------------------------------


entity etcommsched is
   generic
   (
	 	InitFile	:	string
	 );
	port
	(
    rdaddress	:	in	t_etcommsched_addr;
    rddata		:	out	t_etcommsched;
    wraddress	:	in	t_etcommsched_addr;
    wrdata		:	in	t_etcommsched;
    wren	   	:	in	std_logic;
    clk		   	:	in	std_logic
);

end etcommsched;