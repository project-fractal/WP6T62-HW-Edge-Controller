----------------------------------------------------------------------------------
-- Company: University of Siegen, Embedded Systems
-- Engineer: Hamidreza Ahmadian
--
-- Create Date: 05/28/2015 03:52:19 PM
-- Design Name:
-- Module Name: dataArea - blockram
-- Project Name:
-- Target Devices:
-- Tool Versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments: one can use the nqd value to identify wether the buffer is empty or full
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ent_buffer is
  Generic (
    AddrWidth     : natural := 4;  -- Depth of the RAM = 2^AddrWidth
    WordWidth     : natural := 32
  );
  Port (
    clk           : in std_logic;
    reset_n       : in std_logic;
    enq           : in std_logic;
    din           : in std_logic_vector (WordWidth - 1 downto 0);
    full          : out std_logic;
    deq           : in std_logic;
    dout          : out std_logic_vector (WordWidth - 1 downto 0);
    msglen        : out std_logic_vector (AddrWidth downto 0);
    empty         : out std_logic 
  );
end;

architecture behavioral of ent_buffer is

  constant C_MAX_NUM_ELEMENTS : unsigned (AddrWidth downto 0) := (AddrWidth => '1', others => '0');

  type buffer_type is array(0 to (2 ** AddrWidth - 1)) of unsigned ( WordWidth - 1 downto 0 );
  signal buffer_inst : buffer_type;

  signal wrpntr     : unsigned (AddrWidth  downto 0) := (others => '0');
  signal rdpntr     : unsigned (AddrWidth  downto 0) := (others => '0');

  signal full_loc   : std_logic;
  signal empty_loc  : std_logic;

  signal nqd        : unsigned (AddrWidth downto 0) := (others => '0');

begin
  process (clk)
  begin
    IF rising_edge (clk) then
      if (reset_n = '0') then
        wrpntr <= (others => '0');
        rdpntr <= (others => '0');
      elsif (enq = '1' AND full_loc = '0') then
        buffer_inst (to_integer (wrpntr (AddrWidth - 1 downto 0))) <= unsigned(din);
        wrpntr <= wrpntr+1;
      end if;
      IF (deq = '1' AND empty_loc = '0') then
        dout <= std_logic_vector (buffer_inst (to_integer(rdpntr (AddrWidth - 1 downto 0))));
        rdpntr <= rdpntr + 1;
      end if;
    end if;
  end process;
  -- full_loc  <= '1' when (wrpntr (AddrWidth - 1  downto 0) = rdpntr (AddrWidth - 1  downto 0)) and (wrpntr (AddrWidth) = not rdpntr (AddrWidth))  else '0';
  -- empty_loc <= '1' when rdpntr = wrpntr else '0';


  full_loc  <= '1' when nqd = C_MAX_NUM_ELEMENTS else '0';
  empty_loc <= '1' when nqd = 0 else '0';

  full  <= full_loc;
  empty <= empty_loc;
  nqd <= wrpntr - rdpntr;
  msglen <= std_logic_vector (nqd); --  when nqd >= 1 else 0; -- todo
end behavioral;
