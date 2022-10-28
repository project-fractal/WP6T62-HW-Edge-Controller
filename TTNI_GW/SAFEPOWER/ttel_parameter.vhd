-----------------------------------------------------------------------------------------------------
-- Project		: SAFEPOWER
-- Module    : package "ttel_parameter"
-- File			: ttel_parameter.vhd
-- Author		: Hamidreza Ahmadian
-- created		: August, 13th 2015
-- last mod. by	: Hamidreza Ahmadian
-- last mod. on	: August, 13th 2015
-- contents		: This file contains constants that a specific for a single ttel.
--				: In order to adapt the current ttel to your needs, modify the constants in here.
-----------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------
-- library includes
-----------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;


library SYSTEMS;
use SYSTEMS.auxiliary.all;         	-- helper functions and helper procedures
use SYSTEMS.configman.all;         	-- for extracting configuration parameters from the files

--library work;
--use work.configman.all;         	-- for extracting configuration parameters from the files
--use work.auxiliary.all;         	-- for extracting configuration parameters from the files

-----------------------------------------------------------------------------------------------------
-- package "ttel_parameter"
-----------------------------------------------------------------------------------------------------

package ttel_parameter is


--	constant TTEL_NAME						: string := "ttel_0";
	
-----------------------------------------------------------------------------------------------------
-- parameters that are specific for a single TTEL
-----------------------------------------------------------------------------------------------------

	-- Number of provided architectural ports
	-- This constants denotes the total number of ports, which are the end points of an Encapsulated Communication Channel that are
	-- provided to the host in a TTEL. However, keep in mind that the last 3 ports are reserved for special purposes.
	-- As a result, for a given value X, just X - 3 different ports are available to the host's application.
	-- This value should be a power of 2. Also note that the memory required in each TTEL is dependent on this value.
	-- In general, it affects the number of data words in the Port Configuration Memory and Port Synchronization Memory, as well as the
	-- width of a single data word in the Message Configuration Memory. Additionally, it influences the width of the address bus of
	-- the Control Interface.

--	constant NR_OUT_PORTS						: integer		:= 6;
--	constant NR_PORTS							: integer		:= 12;

    constant C_PQ_NUMBERS       			    : integer        := 4;

	-- represents the queue length for the event/queueing ports
--	constant GC_QUEUE_LENGTH									: integer := 16;

	-- Number of addressable data words at the Port Interface (i.e. data words in the Port Memory that is attached to a given TTEL).
	-- The data words are of the width "PI_WORD_WIDTH", which is common to the whole NoC instance.
	-- This constant is used to derive the width of the address bus of the Port Manager.
	-- It should be a power of 2, so that there are no unassigned addresses left in the address space.
--	constant PI_WORD_NUMBER					: integer		:= 512;		-- 16 Kbit = 2 KB of Port Memory
	constant PI_WORD_NUMBER					: integer		:= 256;	-- 128 Kbit = 16 KB of Port Memory

	-- Number of entries in the Time-Triggered Communication Schedule
	-- This constants specifies the total number of data words in that internal memories of a TTEL, which host the
	-- entries of the Time-Triggered Communication Cchedule.
	-- It should be a power of 2, so that there are no unassigned addresses left in the address space.
	-- Also keep in mind that you have to consider the initialization vector, which goes with the number of
	-- supported periods of the Periodic Control System.
	-- Note that the memory required in a given TTEL is dependent on this value.
	constant TTCOMMSCHED_SIZE					: integer		:= 256;
	constant ETCOMMSCHED_SIZE					: integer		:= 32;

	constant TTCOMMSCHED_INIT_TIME				: integer		:= 15;
	constant ETCOMMSCHED_INIT_TIME				: integer		:= 15;
	
    constant MAX_QUE_LEN                		: integer := 256; 
	constant MAX_BUF_SIZ               			: integer := 4094; 
	constant QUELEN_WIDTH               		: integer := 12; -- for port configuration
	constant BUFSIZ_WIDTH              			: integer := 12; -- for port configuration
	constant MAX_QUELEN_WIDTH               	: integer :=  (MAX_QUE_LEN);  
	constant MAX_BUFSIZ_WIDTH              		: integer :=  (MAX_BUF_SIZ);  



end ttel_parameter;
