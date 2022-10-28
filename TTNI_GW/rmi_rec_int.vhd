----------------------------------------------------------------------------------
-- Company: Universität Sigen, Embedded Systems
-- Engineer: Farzad Nekouei
-- Modified and Debugged by: Hamidreza Ahmadian
-- Create Date: 05/19/2016 02:15:33 PM
-- Design Name:
-- Module Name: rmi_rec_int - Behavioral
-- Project Name:
-- Target Devices:
-- Tool Versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments: This module should be updated by adding a new output signal which
-- enables writing the new configutaion at the port side.
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;


library SYSTEMS;
use SYSTEMS.system_parameter.all;	-- parameters of the current NoC instance

library SAFEPOWER;
use SAFEPOWER.TTEL.all;   			-- t_portid, PORTDATA_WIDTH

entity rmi_rec_int is
generic (
	NR_PORTS                  : integer
);
port(
	clk 					: in  std_logic;
   	rstn					: in  std_logic;
	new_conf 				: in  std_logic;
	recp_data      		    : in  std_logic_vector (PORTDATA_WIDTH - 1 downto 0);
    recp_deq 				: out std_logic;
	reconf_data      	    : out std_logic_vector (15 downto 0);
	reconf_port_id          : out t_portid;
	err_out					: out std_logic
);
end rmi_rec_int;

architecture Behavioral of rmi_rec_int is
	signal sig_port_id  		: t_portid;
	signal count  				: unsigned (3 downto 0);
	signal config_data			: std_logic_vector (79 downto 0);
    signal ongoing_reconf 		: std_logic;
    signal sig_err_out	 		: std_logic;

begin

err_out <= sig_err_out;

  -- process for generating ongoing_reconf
ongoing_reconf_proc: process (clk, rstn)
begin
	if rstn = '0' then
		ongoing_reconf <= '0';
	elsif rising_edge (clk) then
		if new_conf = '1' then
			ongoing_reconf <= '1';    --**should change to 0 after 11 clk**
		elsif count = x"C" OR sig_err_out = '1' then
			ongoing_reconf <= '0';
		end if;
	end if;
end process;

  -- process for generating count
count_proc: process (clk, rstn)
begin
	if rstn = '0' OR new_conf = '1' then
		count <= x"0";
	elsif rising_edge (clk) then
		if ongoing_reconf = '1' and sig_err_out = '0' then
			count <= count + x"1";    --**should change to 0 after 11 clk**
		else
			count <= x"0";
		end if;
	end if;
end process;

  -- process for generating sig_err_out
sig_err_out_proc: process (clk, rstn)
begin
	if rstn = '0' OR new_conf = '1' then
		sig_err_out <= '0';
	elsif rising_edge (clk) then
		if count = x"2" then
			if recp_data (7 downto 0) /= preamble_byte then   --is data valid?
				sig_err_out <= '1';			--report the error and terminate the reconfiguration
			else
				sig_err_out <= '0';
			end if;
		end if;
	end if;
end process;


-- process for generating recp_deq
recp_deq_proc: process (clk, rstn)
begin
	if rstn = '0' OR new_conf = '1' then
		recp_deq<= '0';
	elsif rising_edge (clk) then
		if count >= x"0" AND count <= x"3" AND ongoing_reconf = '1' then
			recp_deq <= '1';
		else
			recp_deq <= '0';
		end if;
	end if;
end process;



main_std: process (clk, rstn)
begin
	if rstn = '0' then
		config_data <= (others => '0');
		sig_port_id <= (others => '0');
		reconf_data <= (others => '0');
		reconf_port_id <= (others => 'Z');
	elsif rising_edge(clk) AND ongoing_reconf = '1' then
	case count is
	when x"2"  =>
		--second byte of the first 32 bit data = Port ID
		sig_port_id <= recp_data (15 downto 8);
		--third byte of the first 32 bit data = Command ID
		config_data(79 downto 64) <="00000000" & recp_data (23 downto 16);
	when x"3"  =>
		config_data (31 downto 0) <= recp_data (31 downto 0);
	when x"4"  =>
		config_data (63 downto 32) <= recp_data (31 downto 0);
	when x"5"  =>
		reconf_port_id <= sig_port_id;
	  	reconf_data <= config_data (15 downto 0);
	when x"6"  =>
		reconf_data <= config_data (31 downto 16);
	when x"7"  =>
		reconf_data <= config_data (47 downto 32);
	when x"8"  =>
		reconf_data <= config_data (63 downto 48);
	when x"9"  =>
		reconf_data <= config_data (79 downto 64);
	when x"C"  =>
		reconf_port_id <= (others => 'Z');
	when others =>
  end case;
end if;

end process;
end Behavioral;
