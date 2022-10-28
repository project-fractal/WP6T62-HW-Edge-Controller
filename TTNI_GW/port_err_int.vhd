----------------------------------------------------------------------------------
-- Company:
-- Engineer: Farzad Nekouei
-- Modified and debugged by: Hamidreza Ahmadian
-- Create Date:    11:13:47 01/23/2016
-- Design Name:
-- Module Name:    Error_Controlle - Behavioral
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
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.Vcomponents.all;

library SYSTEMS;
use SYSTEMS.system_parameter.all;	-- parameters of the current NoC instance

library SAFEPOWER;
use SAFEPOWER.ttel.all;	-- t_timeformat, t_portid


entity port_err is
generic (
	MY_PORT_ID         	: integer := 0
	);
port(
	clk							: in std_logic;
	reset_n						: in std_logic;
	GlobalTime 					: in t_timeformat;
	pFull						: in std_logic;
	pEmpty						: in std_logic;
	bFull	 					: in std_logic;
	bEmpty 						: in std_logic;
	ungoing_wr 					: in std_logic;
	ungoing_rd					: in std_logic;
	enq 						: in std_logic;
	deq 						: in std_logic;
	conf_error     				: in std_logic;
	send_error_id				: in t_portid;
	error_flag 					: out std_logic;
	error_data 					: out std_logic_vector (PORTDATA_WIDTH - 1 downto 0)
);

end port_err;

architecture Behavioral of port_err is

signal wm_clk 	: std_logic;

component err_capture
generic (
	MY_PORT_ID         	: integer := 0;
	ERROR_LENGTH		: integer := 7;
	RESERVED	      	: std_logic_vector (20 downto 0) :=(others => '0')
);
port(
	clk						: in  std_logic;
	reset_n           		: in  std_logic;
	GlobalTime				: in  t_timeformat;
	e_port_over				: in  std_logic;
	e_port_empty			: in  std_logic;
	e_buffer_over			: in  std_logic;
	e_buffer_empty	  		: in  std_logic;
	e_crashed_write			: in  std_logic;
	e_crashed_read			: in  std_logic;
	send_error_id			: in std_logic_vector (PORTID_WIDTH - 1 downto 0);
	e_error_flag			: out std_logic;
	e_error_data			: out std_logic_vector (PORTDATA_WIDTH - 1 downto 0);
	e_config_error	  		: in  std_logic;
	clear_flag				: out std_logic
);
END component;

component prescaler
generic(
  n               				: integer := 250;
  count1_length   				: integer := 7
);
port(
  clk							: in  std_logic;
  rstn							: in  std_logic;
  freq							: out std_logic            -- clk > 2freq  hz
);
end component;


component buffer_overflow
	PORT(
	  clk										: in  std_logic;
		reset_n								: in  std_logic;
		clear_flag             : in std_logic;
		buff_full 						: in  std_logic;
		enq										: in  std_logic;
		buffer_over 					: out std_logic
	);
	END component;

	component buffer_empty
	PORT(
		clk										: in  std_logic;
		reset_n								: in  std_logic;
		clear_flag             : in std_logic;
		b_empty 							: in  std_logic;
		deq										: in  std_logic;
		buffer_empty 					: out std_logic
	);
	END component;

	component port_overflow
	PORT(
    clk										: in  std_logic;
		reset_n								: in  std_logic;
		clear_flag             : in std_logic;
		port_full 						: in  std_logic;
		enq										: in  std_logic;
		port_over  						: out std_logic
	);
	END component;

	component port_empty
	PORT(
	  clk										: in  std_logic;
		reset_n								: in  std_logic;
		clear_flag             : in std_logic;
		p_empty 							: in  std_logic;
		deq										: in  std_logic;
		port_empty 						: out std_logic
	);
	END component;

	component crashed_write
	PORT(
  	clk										: in  std_logic;
		reset_n								: in  std_logic;
		clear_flag             : in std_logic;
		m_clk 								: in  std_logic;
		ungoing_w							: in  std_logic;
		crashed_wr 				: out std_logic
	);
	END component;

	component crashed_read
	PORT(
		clk										: in  std_logic;
		m_clk 								: in  std_logic;
		reset_n								: in  std_logic;
		clear_flag             : in std_logic;
		ungoing_r							: in  std_logic;
		crashed_rd 					: out std_logic
	);
	END component;

	component config_error
  port(
    clk                 	:in  std_logic;
    reset_n             	:in  std_logic;
		clear_flag             : in std_logic;
    config_error_in     	:in  std_logic;
    config_error_out    	:out std_logic
  );
	end component;


signal buffer_over1       : std_logic;
signal buffer_empty1      : std_logic;
signal port_over1         : std_logic;
signal port_empty1        : std_logic;
signal crashed_write1     : std_logic;
signal crashed_read1      : std_logic;
signal config_error1      :  std_logic;
signal err_reset          : std_logic;
signal clr_flag         : std_logic;
begin

----------------------------------------------------------------------------------------------------------------
                                               --port map--
----------------------------------------------------------------------------------------------------------------

err_capt_inst: err_capture
generic map (
MY_PORT_ID => MY_PORT_ID,
ERROR_LENGTH => 7
)
port map(
	clk=>clk,
	GlobalTime=>GlobalTime,
	reset_n => reset_n,
	e_port_over=>port_over1,
	e_port_empty=>port_empty1,
	e_buffer_over=>buffer_over1,
	e_buffer_empty=>buffer_empty1,
	e_crashed_write=>crashed_write1,
	e_crashed_read=>crashed_read1,
	e_config_error=>config_error1,
  send_error_id=>send_error_id,
	e_error_flag=> error_flag,
	e_error_data=> error_data,
	clear_flag => clr_flag
);

E1_buff_of_inst: buffer_overflow
port map(
	clk=>clk,
	reset_n=>reset_n,
	clear_flag => clr_flag,
	buff_full=>bFull,
	enq=>enq,
	buffer_over=>buffer_over1
);

E2_buff_empty_inst: buffer_empty
port map(
	clk=>clk,
	reset_n=>reset_n,
	clear_flag => clr_flag,
	b_empty=>bEmpty,
	deq=>deq,
	buffer_empty=>buffer_empty1
);
E3_port_of_inst: port_overflow
port map(
	clk=>clk,
	reset_n=>reset_n,
	clear_flag => clr_flag,
	port_full=>pFull,
	enq=>enq,
	port_over=>port_over1
);

E4_port_empty_inst: port_empty
port map(
	clk=>clk,
	reset_n=>reset_n,
	clear_flag => clr_flag,
	p_empty=>pEmpty,
	deq=>deq,
	port_empty=>port_empty1
);

E5_crashed_wr_inst:crashed_write
	port map(
		clk=>clk,
		m_clk=>wm_clk,
		reset_n=>reset_n,
		clear_flag => clr_flag,
		ungoing_w=>ungoing_wr,
		crashed_wr => crashed_write1
);

E6_crashed_read_inst: crashed_read
	port map(
		clk=>clk,
		m_clk=>wm_clk,
		reset_n=>reset_n,
		clear_flag => clr_flag,
		ungoing_r=>ungoing_rd,
		crashed_rd => crashed_read1
);

E7_config_err_inst: config_error
	port map(
		clk => clk,
    reset_n => reset_n,
		clear_flag => clr_flag,
		config_error_in => conf_error,
		config_error_out => config_error1
);

mclk_gen: prescaler
port map (
	clk => clk,
	rstn => reset_n,
	freq => wm_clk
);

end Behavioral;
