----------------------------------------------------------------------------------
-- Company: Universität Siegen
-- Engineer: Farzad Nekouei
-- Modified and debugged by: Hamidreza Ahmadian
-- Create Date:    01:49:50 01/24/2016
-- Design Name:
-- Module Name:    rmi_err_int - Behavioral
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


entity rmi_err_int is
generic (
	count1_length   : integer :=10;
	NR_PORTS        : integer
);
port(
	clk						: in std_logic;
    rstn			  		: in std_logic;
    error_data				: in std_logic_vector (31 downto 0);
	send_error_id			: out t_portid;
	error_flags				: in std_logic_vector (NR_PORTS - 1 downto 0);
	errp_enq				: out std_logic;
	errp_term				: out std_logic;
	errp_data				: out std_logic_vector (PORTDATA_WIDTH - 1 downto 0)
);
end rmi_err_int;

architecture Behavioral of rmi_err_int is

TYPE e_ctr_state is (RESET, IDLE, CHK_PORT, RD_WR_ERROR);

-- reset: reset
-- IDLE: waiting for error_flags
-- CHK_PORT: after error_flag /= 0, checks the ports to find the faulty port
-- RD_WR_ERROR: reads the error data from the port and writes to the ERRP


SIGNAL  present_state       : e_ctr_state;
SIGNAL  next_state          : e_ctr_state;


signal  PORT_ID_CNTR : integer := 0;
signal  OP_CNTR      : unsigned (2 downto 0):= (others => '0');
signal  zero         : STD_LOGIC_VECTOR (NR_PORTS - 1 downto 0):=(others => '0');

begin

PROCESS (clk, rstn)
BEGIN
  IF rising_edge (clk) THEN
     IF rstn = '0' THEN
        present_state <= RESET;
     ELSE
        present_state <= next_state;
     END IF;
  END IF;
END PROCESS;

state_hndlr: PROCESS (present_state, error_flags, PORT_ID_CNTR, OP_CNTR)
BEGIN

    next_state <= present_state;

    CASE present_state IS
        WHEN RESET  =>
            next_state <= IDLE;
        WHEN IDLE =>
            IF error_flags /= zero THEN -- zhengming dangqian you erorr
               next_state <= CHK_PORT;
            ELSE
               next_state <= IDLE;
            END IF;

        WHEN CHK_PORT =>
            IF error_flags (PORT_ID_CNTR) = '1' THEN
                next_state <= RD_WR_ERROR;
            ELSIF PORT_ID_CNTR = NR_PORTS - 1 then  
            	next_state <= IDLE;
            ELSE 
                next_state <= CHK_PORT;
            END IF;
        WHEN RD_WR_ERROR =>
           IF OP_CNTR = 7 THEN
            next_state <= CHK_PORT;
            ELSE
            next_state <= RD_WR_ERROR;
            END IF;

        WHEN OTHERS => next_state <= IDLE;

    END CASE;
END PROCESS;

report_proc: process(clk)
begin
if rising_edge(clk) then
    if present_state = RESET then
        errp_enq <= '0';
        errp_term <= '0';
        send_error_id <= (others => '0');
        errp_data <= (others => '0');
        PORT_ID_CNTR <= 0;
        OP_CNTR <= (others => '0');
    elsif present_state = CHK_PORT then
       if PORT_ID_CNTR >= NR_PORTS - 1 then
          PORT_ID_CNTR <= 0;
       else
          PORT_ID_CNTR <= PORT_ID_CNTR + 1;
          OP_CNTR<=(others => '0');
       end if;
    elsif present_state = RD_WR_ERROR then
     case OP_CNTR is
        when "000"  =>  OP_CNTR <= OP_CNTR+1; send_error_id <= std_logic_vector(to_unsigned(PORT_ID_CNTR - 1,PORTID_WIDTH));
        when "001"  =>  OP_CNTR <= OP_CNTR+1;
        when "010"  =>  OP_CNTR <= OP_CNTR+1;
        when "011"  =>  OP_CNTR <= OP_CNTR+1; errp_data <= error_data; errp_enq<='1';
        when "100"  =>  OP_CNTR <= OP_CNTR+1; errp_data <= error_data;
        when "101"  =>  OP_CNTR <= OP_CNTR+1; errp_data <= error_data;
        when "110"  =>  OP_CNTR <= OP_CNTR+1; send_error_id<=(others => '0'); errp_term<='1';
        when "111"  =>  OP_CNTR <= OP_CNTR+1; errp_term<='0'; errp_enq<='0';
        when others => null;
     end case;
    end if;
end if;
end process;

end Behavioral;
