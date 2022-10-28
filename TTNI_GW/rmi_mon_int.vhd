----------------------------------------------------------------------------------
-- Company:
-- Engineer: Farzad Nekouei
--
-- Create Date:    21:04:54 01/25/2016
-- Design Name:
-- Module Name:    port_status_interface - Behavioral
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
library UNISIM;
use UNISIM.VComponents.all;

library SAFEPOWER;
use SAFEPOWER.TTEL.all;        		-- constants, datatypes, and component declarations of the current TTEL


library SYSTEMS;
use SYSTEMS.system_parameter.all;	-- parameters of the current NoC instance
use SYSTEMS.configman.all;         	-- for extracting configuration parameters from the files


entity port_status_interface is
generic(
    count1_length   : integer :=8;
    PORTDATA_WIDTH	: integer := 32;
    NR_PORTS        : integer
);
port(
    clk               : in  std_logic;
    rstn			  : in std_logic;
    freq              : in  std_logic;                      -- clk > 2freq  hz
    pTimeCnt          : in  t_timeformat;
    port_data         : in std_logic_vector (31 downto 0);
    port_add          : out std_logic_vector (PORTID_WIDTH - 1 downto 0);  --Max Port=255
    monp_data         : out std_logic_vector (31 downto 0);
    monp_addr         : out std_logic_vector (8 downto 0);
    monp_enq          : out std_logic;  --fagei core Ni
    monp_term         : out std_logic  --fagei core NI
);

end port_status_interface;

architecture Behavioral of port_status_interface is

signal   count1       : unsigned(count1_length downto 0);
signal   empty        : std_logic_vector(MAX_NR_PORTS - 1 downto 0);
signal   full         : std_logic_vector(MAX_NR_PORTS - 1 downto 0);
signal   empty_byte   : std_logic_vector(31 downto 0);
signal   full_byte    : std_logic_vector(31 downto 0);
--
signal   lock         : std_logic:= '0';
--
signal   set_data     : std_logic :='0';
--
signal   wr_control   : std_logic :='0';
signal   k            : integer:= 0;


begin

  std: process (freq , clk, rstn)
  begin
  if rstn = '0' then
   monp_enq <= '0';
   empty <= (others => '1');
   full <= (others => '0');
   monp_data <= (others => '0');
   monp_addr <= (others => 'Z');
   port_add <= (others => 'Z');
   monp_term <= '0';
   count1 <= (others => '0');
   wr_control <= '0';

  elsif rising_edge(clk) then
    if lock='0' AND freq='1' then
      lock<='1';
    end if;
    if lock='1' then
    -- this case writes the PORT_STATUS entries into the MONP
      if count1 >= 0 AND count1 < NR_PORTS  then
        full(k)<=port_data(31);  -- houliangwei daibiao kong man 
        empty(k)<=port_data(30);
        port_add <= std_logic_vector (count1(PORTID_WIDTH - 1 downto 0));  --??selecting port 0 to port 255 (from address 0x10 to 0x10F
        monp_addr <= std_logic_vector (count1 + 16); --16dao FFshi shuju 
        monp_data <= port_data;
        monp_enq <= '0';
        monp_term <= '0';
        wr_control <= '1';
      end if;
    -- this case writes the empty and full words into the MONP (address 0x00 to 0x15)
      if count1 >= NR_PORTS AND count1 < NR_PORTS + 8 then
        empty_byte <= empty (32 * (to_integer (count1) - NR_PORTS) + 31 downto 32* (to_integer (count1) - NR_PORTS));-- meici chuansong 32ge ports d empty xinxi
        monp_addr<= std_logic_vector (count1- NR_PORTS);--0-7 meici 32wei kong xinxi
        monp_data<=empty_byte;
        monp_enq<='0';
        monp_term<='0';
        wr_control<='1';
      end if;
      if count1 >= NR_PORTS + 8 AND count1 < NR_PORTS + 16 then
        full_byte <= full (32 * (to_integer (count1) - NR_PORTS - 8) + 31 downto 32* (to_integer (count1) - NR_PORTS - 8));
--        full<=full srl 8;
        monp_addr <= std_logic_vector (count1 - NR_PORTS);--0-7 meici 32wei kong xinxi
        monp_data <= full_byte;
        monp_enq<='0';
        monp_term<='0';
        wr_control<='1';
	-- global time base # 0
      elsif count1 = NR_PORTS + 16 then
        monp_addr <= b"100010000";
        monp_data <= pTimeCnt (31 downto 0);
        monp_enq <='0';
        monp_term <='0';
        wr_control <='1';
	-- global time base # 0
      elsif count1 = NR_PORTS + 17 then
        monp_addr <= b"100010001";
        monp_data <= pTimeCnt (63 downto 32);
        monp_enq <= '0';
        monp_term <= '0';
        wr_control <= '1';
      elsif count1 = NR_PORTS + 18 then
	    monp_enq <= '0';
        wr_control <= '1';
        monp_addr <= (others => '0');
      elsif count1 = NR_PORTS + 19 then
	    monp_enq <= '0';
	    port_add <= (others => 'Z');
        wr_control <= '1';
      elsif count1 = NR_PORTS + 20 then
        monp_enq <= '0';
        monp_term <= '0';
        count1 <= (others => '0');
        k <= 0;
        wr_control <= '0';
        lock <= '0';              -- wait until the next positive edge of freq
      end if;

      if wr_control='1' then
		if count1 = NR_PORTS + 18 then
        	monp_term <='1';
        else
        	monp_term <= '0';
        end if;
        if count1 < NR_PORTS + 19 then
        	monp_enq<='1';
        end if;
        wr_control<='0';     -- Ê²Ã´ÒâË¼
        count1 <= count1+1;
        k <= k+1;
      end if;

    end if;                   --end lock=1
  end if;						  --end rising edge clk
end process;
end Behavioral;
