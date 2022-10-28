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


entity ttcommsched is
   generic
   (
	 	InitFile	:	string
	 );
	port
	(
    rdaddress	:	in	t_ttcommsched_addr;
    rddata		:	out	t_ttcommsched;
--    rden	   	:	in	std_logic;
    wraddress	:	in	t_ttcommsched_addr;
    wrdata		:	in	t_ttcommsched;
    wren	   	:	in	std_logic;
    clk		   	:	in	std_logic
);

end ttcommsched;	