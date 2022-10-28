----------------------------------------------------------------------------------
-- Company: University of Siegen, Embedded Systems
-- Engineer: Farzad Nekouei
-- Modified and debugged by: Hamidreza Ahmadian
-- Create Date: 05/20/2016 02:51:25 AM
-- Design Name:
-- Module Name: port_reconf - Behavioral
-- Project Name:
-- Target Devices:
-- Tool Versions:
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
use SYSTEMS.system_parameter.all;	-- parameters of the current NoC instance

library SAFEPOWER;
use SAFEPOWER.ttel.all;	-- t_timeformat, t_portid


entity port_reconf is
generic (
  PORT_ID                : integer := 0;
	MINT_initialization    : t_timeformat := x"000000000000000F";
	DEST_initialization    : t_phyname := x"0000000F";
	port_EN_initialization : std_logic :='1'
);
port(
	clk                    : in std_logic;
  reset_n                : in std_logic;
  --reconf_port_sel 			: in  std_logic;
	reconf_port_id         : in t_portid;
	config_data            : in std_logic_vector (15 downto 0);--preamble (127:120)  reserve(119:80) port_ID (79:72) command_ID (71:64) new_value(63:0)
	MINT_config_value      : out t_timeformat;
	DEST_config_value      : out t_phyname;
	port_EN_value          : out std_logic;
  	newConfValid           : out std_logic;
	err_out                : out std_logic
);
end port_reconf;

architecture Behavioral of port_reconf is

signal MINT_config_data          : t_timeformat;
signal DEST_config_data          : t_phyname;
signal port_EN_data              : std_logic;
--preamble (127:120)  reserve(119:80) port_ID (79:72) command_ID (71:64) new_value(63:0)
signal rConfigData               : std_logic_vector (71 downto 0):= (others => '0');
signal counter                   : unsigned (3 downto 0);
signal MY_ID                     : t_portid;
signal ongoing_reconf            : std_logic;


begin
	MY_ID <= std_logic_vector (to_unsigned (PORT_ID, PORTID_WIDTH));
  MINT_config_value <= MINT_config_data;
	DEST_config_value <= DEST_config_data;
	port_EN_value <= port_EN_data;

count_proc : process (clk, reset_n)
begin
  if reset_n = '0' then
    counter <= (others => '0');
  elsif rising_edge(clk) then
    if ongoing_reconf = '1' then
      counter <= counter + x"1";
    else
        counter <= x"0";  -- SOFH
--      counter <= counter;
    end if;
  end if;
end process;


rec_proc : process (reconf_port_id, counter, reset_n)
begin
  if reset_n = '0' then
    ongoing_reconf <= '0';
  elsif reconf_port_id = MY_ID then
    ongoing_reconf <= '1';
  elsif counter = x"8" then
    ongoing_reconf <= '0';
  end if;
end process;


main_proc: process (clk, reset_n)
begin
  if reset_n = '0' then
    err_out <= '0';
    newConfValid <= '0';
    port_EN_data <= port_EN_initialization;
    MINT_config_data <= MINT_initialization;
    DEST_config_data <= DEST_initialization;
  elsif rising_edge (clk) then
    case counter is
		when x"0" =>
		rConfigData (15 downto 0) <= config_data;
		when x"1" =>
		rConfigData (31 downto 16) <= config_data;
		when x"2" =>
		rConfigData (47 downto 32) <= config_data;
		when x"3" =>
		rConfigData (63 downto 48) <= config_data;
		when x"4" =>
		-- command ID
		rConfigData (71 downto 64) <= config_data (7 downto 0);
		when x"5" =>
		case rConfigData (71 downto 64) is
		  --update MINT data
		  when "00000001"  =>  MINT_config_data <= rConfigData (63 downto 0);
		  err_out<='0';
		  --update DEST data
		  when "00000010"  =>  DEST_config_data <= rConfigData (31 downto 0);
		  err_out<='0';
		  --PORT Enable or Disable
		  when "00000100"  =>  port_EN_data <= rConfigData (0);
		  err_out<='0';
		  -- Invalid command
		  when others      =>
		  err_out<='1' ;
		end case;
		when x"6" =>
		  newConfValid <= '1';
		  err_out <= '0';
		when x"7" =>
		  newConfValid <= '0';
		  rConfigData  <= (others => '0'); -- SOFH
		when others      =>
		end case;
  end if;

end process;

end Behavioral;
