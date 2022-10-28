----------------------------------------------------------------------------------
-- Company:
-- Engineer: Farzad Nekouei
--
-- Create Date:    19:40:40 01/20/2016
-- Design Name:
-- Module Name:    port_status - Behavioral
-- Project Name:
-- Target Devices:
-- Tool versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library SYSTEMS;
use SYSTEMS.system_parameter.all;	-- count1_lengt

library SAFEPOWER;
use SAFEPOWER.TTEL.all;        		-- constants, datatypes, and component declarations of the current TTEL


entity port_status is
generic (
	PORT_ID         		     : integer := 0;
	PORTDATA_WIDTH				 : integer := 32;
	BUFF_ADDR_WIDTH              : integer := 15;
	FIFO_ADDR_WIDTH      	     : integer := 11
);
port(
	port_full						 : in  std_logic;
	port_empty						 : in  std_logic;--£ø£ø
	buffer_full						 : in  std_logic;--£ø£ø
    buffer_empty					 : in  std_logic;
	nqd_port 					     : in  std_logic_vector (FIFO_ADDR_WIDTH downto 0);
	nqd_buffer 						 : in  std_logic_vector (BUFF_ADDR_WIDTH downto 0);
	port_add 						 : in  t_portid;
	port_data 						 : out std_logic_vector (PORTDATA_WIDTH - 1 downto 0)
);
end port_status;

--structure of the data:
--nqd_buffer bit 0 to 17, 18 bits
--nqd_port bit 18 to 27, 10 bits

--buffer_empty bit 28
--buffer_full bit 29
--port_empty bit 30
--port_full bit 31

architecture Behavioral of port_status is

signal rNqdPort				: std_logic_vector (C_MONP_NQDMSG_WIDTH - 1 downto 0);
signal rNqdBuffer			: std_logic_vector (C_MONP_MSGLEN_WIDTH - 1 downto 0);

begin
	rNqdPort (FIFO_ADDR_WIDTH downto 0) <= nqd_port;
	rNqdPort (C_MONP_NQDMSG_WIDTH - 1 downto FIFO_ADDR_WIDTH + 1) <= (others => '0');--  ”–Œ Ã‚
	rNqdBuffer (BUFF_ADDR_WIDTH downto 0) <= nqd_buffer;
	rNqdBuffer (C_MONP_MSGLEN_WIDTH - 1 downto BUFF_ADDR_WIDTH + 1) <= (others => '0');


	std: process (port_add,port_full,port_empty,buffer_full,buffer_empty,nqd_port,nqd_buffer)
	begin
		if port_add = std_logic_vector (to_unsigned (PORT_ID, PORTID_WIDTH)) then
			port_data (31 downto 0) <= port_full & port_empty & buffer_full & buffer_empty & rNqdPort & rNqdBuffer;
		else
			port_data (31 downto 0) <= (others => 'Z');
		end if;
end process;
end Behavioral;
