-----------------------------------------------------------------------------------------------------
-- Project		: SAFEPOWER
-- Module       : Error capture interface
-- File			: err_capture.vhd
-- Author		: Farzad Nekouei,
-- created		: October, 12th 2015
-- last mod. by	: Hamidreza Ahmadian
-- last mod. on	: October, 10th 2015
-- contents		: The entity and the architecture of the error capture unit
-----------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------
-- library includes
-----------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

library SYSTEMS;
use SYSTEMS.system_parameter.all;	-- count1_lengt

library SAFEPOWER;
use SAFEPOWER.TTEL.all;	-- count1_lengt


entity err_capture is

generic (
	MY_PORT_ID         	: integer := 0;
	ERROR_LENGTH			: integer := 7;
	RESERVED	      	: std_logic_vector (20 downto 0) :=(others => '0')
);
port(
	clk									: in  std_logic;
	reset_n           	: in  std_logic;
	GlobalTime					: in  t_timeformat;
	e_port_over					: in  std_logic;
	e_port_empty				: in  std_logic;
	e_buffer_over				: in  std_logic;
	e_buffer_empty	  			: in  std_logic;
	e_crashed_write			: in  std_logic;
	e_crashed_read			: in  std_logic;
  	send_error_id				: in std_logic_vector (PORTID_WIDTH - 1 downto 0);
	e_error_flag			: out std_logic;
	e_error_data			: out std_logic_vector (PORTDATA_WIDTH - 1 downto 0);
	e_config_error	  		: in  std_logic;
	clear_flag				: out std_logic
);

end err_capture;


architecture Behavioral of err_capture is

TYPE error_capture_state is (RESET, ERR_REG, ERR_CODE, CAP_GTB, SET_ERR_FLAG, WAIT_FOR_RMI, SEND_DATA);
-- reset: reset
-- err_reg: concatenates the errors together
-- err_code: extracts the error id
-- cap_gtb: captures the GTB
-- set_err_flag: informs the RMI about the error
-- wait_for_RMI: waits for the RMI to read the error
-- send_data: sends the error to the RMI



    SIGNAL  present_state       : error_capture_state;
    SIGNAL  next_state          : error_capture_state;

	constant port_address : std_logic_vector (PORTID_WIDTH - 1 downto 0) := std_logic_vector (to_unsigned (MY_PORT_ID, PORTID_WIDTH));

	signal error_clock   		: t_timeformat := (others => '0');
	signal count         		: unsigned(2 downto 0) := (others => '0');
	signal error_reg_old 		: std_logic_vector (ERROR_LENGTH - 1 downto 0) := (others => '0');
	signal error_reg     		: std_logic_vector (ERROR_LENGTH - 1 downto 0):= (others => '0');
	signal error_code    		: std_logic_vector (2 downto 0):= (others => '0');

    begin

    PROCESS (clk, reset_n)
    BEGIN
      IF rising_edge (clk) THEN
         IF reset_n = '0' THEN
            present_state <= RESET;
         ELSE
            present_state <= next_state;
         END IF;
      END IF;
    END PROCESS;


state_hndlr: PROCESS (present_state, error_reg, error_reg_old, send_error_id, count)
    BEGIN
        next_state <= present_state;
        CASE present_state IS
            WHEN RESET  =>
                next_state <= ERR_REG;
            WHEN ERR_REG =>
            IF error_reg /= "0000000"  THEN		-- AND  error_reg /= error_reg_old      £¿£¿£¿£¿£¿£¿ err code zai qian  suoyi no err shi  old = current
                 next_state <= ERR_CODE;
            ELSE
                 next_state <= ERR_REG;
            END IF;

            WHEN ERR_CODE =>
                 next_state <= CAP_GTB;

            WHEN CAP_GTB =>
                 next_state <= SET_ERR_FLAG;

            WHEN SET_ERR_FLAG =>
                 next_state <= WAIT_FOR_RMI;

            WHEN WAIT_FOR_RMI =>
                IF send_error_id = port_address THEN
                   next_state <= SEND_DATA;
                ELSE
                   next_state <= WAIT_FOR_RMI;
                END IF;

            WHEN SEND_DATA =>
                IF count = 3 THEN
                   next_state <= ERR_REG;
                END IF;

            WHEN OTHERS => next_state <= ERR_REG;
        END CASE;
    END PROCESS;


error_register: process(clk)
begin
if reset_n = '0' then 
	error_reg <= (others => '0'); 
elsif rising_edge(clk) then
	if present_state = ERR_REG or present_state = SEND_DATA then
	   error_reg <= e_config_error & e_buffer_over & e_buffer_empty & e_port_over & e_port_empty & e_crashed_write & e_crashed_read;
 	end if;
end if;
end process;


-- process for generation of clear_flag
proc_clr_flag: process(clk, reset_n)
begin
if reset_n = '0' then 
	clear_flag <= '0'; 
elsif rising_edge(clk) then
	if present_state = SEND_DATA and count = "000" then 
		clear_flag <='1';
	else 
		clear_flag <='0';
	end if; 
end if; 
end process; 


error_codes: process(clk)
begin
if reset_n = '0' then 
	error_code <= "000"; 
elsif rising_edge(clk) then
	if present_state = ERR_CODE then
             case (error_reg XOR error_reg_old)is
                 when "0000000"  =>  error_code <= "000";   --no_error
                 when "0000001"  =>  error_code <= "001";   --crash_read
                 when "0000010"  =>  error_code <= "010";   --crash_write
                 when "0000100" | "0010100" =>  error_code <= "011";   --port_empty
                 when "0001000" | "0101000" =>  error_code <= "100";   --port_over
                 when "0010000"  =>  error_code <= "101";   --buffer_empty
                 when "0100000"  =>  error_code <= "110";   --buffer_over
                 when "1000000"  =>  error_code <= "111";   --config_error
                 when others     =>  error_code <= "000";   --???????
              end case;
     end if;
end if;
end process;

capture_global_time: process(clk)
begin
if rising_edge(clk) then
	if present_state = CAP_GTB then
	   error_clock<= GlobalTime;
 	end if;
end if;
end process;

error_flag: process(clk)
begin
if reset_n = '0' then 
	e_error_flag <= '0'; 
elsif rising_edge(clk) then
	if present_state = SET_ERR_FLAG then
	   e_error_flag<='1';
	elsif present_state = SEND_DATA then
        e_error_flag<='0';
    end if;
end if;
end process;

send_error_data: process(clk, reset_n)
begin
if reset_n = '0' then 
	count <= "000"; 
	e_error_data <= (others => 'Z');
elsif rising_edge(clk) then
	if present_state = SEND_DATA then
       case count is
            when "000"  =>  
            	count <= b"001"; 
            	e_error_data <= RESERVED(20 downto 0) & error_code (2 downto 0) & port_address (PORTID_WIDTH - 1 downto 0);--reserved & error_reg & port_address;
            when "001"  =>  
            	count <= b"010"; 
            	e_error_data <= std_logic_vector(error_clock(31 downto 0));--error_clock (31 downto 0);
            when "010"  =>  
            	count <= b"011"; 
            	e_error_data <= std_logic_vector(error_clock(63 downto 32));--error_clock (63 downto 32);
            when "011"  =>  
            	count<=(others => '0'); 
            	e_error_data <= (others => 'Z');
            when others => 
         end case;
         error_reg_old<=error_reg;
 	end if;
end if;
end process;

end Behavioral;
