
-----------------------------------------------------------------------------------------------------
-- Project		: SAFEPOWER
-- Module       : Reconfiguration and Monitoring Interface
-- File			: rmi.vhd
-- Author		: Farzad Nekouei, Hamidreza Ahmadian
-- created		: October, 12th 2015
-- last mod. by	: Rakotojaona Nambinina
-- last mod. on	: October, 10th 2021
-- contents		: The entity and the architecture of the RMI
-----------------------------------------------------------------------------------------------------

-- The RMI is accessible by the LRM via three pots: MONP, ERRP, RECP.
-- The RECP is an output port which is written into by the LRM, whereas, the MONP and ERRP are input ports and are read by the LRM.
-- IDs exclusively assigned to those ports are as follows:
-- RECP: 0
-- MONP: NR_PORTS - 1 (last port)
-- ERRP: NR_PORTS - 2 (before last port)


------------------------------------------------------------------------------------------------------
-- library includes
-----------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
--use IEEE.std_logic_arith.all;	-- for conv_integer
 
  use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use std.textio.all;

library SAFEPOWER;
use SAFEPOWER.TTEL.all;        		-- constants, datatypes, and component declarations of the current TTEL
use SAFEPOWER.memorymap.all;    	-- convert std_logic_vector to t_ttcommsched

library SYSTEMS;
use SYSTEMS.system_parameter.all;	-- parameters of the current NoC instance
use SYSTEMS.configman.all;         	-- for extracting configuration parameters from the files
 
entity rmi is
  generic (
    MY_ID                     : integer := 0;
    Resource_Management_Enable : std_logic := '0';
    NR_PORTS                  : integer
  );
  port (

    --RMI and MON_port
    monp_data                 : out std_logic_vector (31 downto 0);
    monp_enq                  : out std_logic;
    monp_term                 : out std_logic;
    monp_addr                 : out std_logic_vector (8 downto 0);

    -- LRM notifies the RMI to fetch new configuration
    new_conf                  : in  std_logic;
    recp_deq                  : out std_logic;
    recp_data                 : in  std_logic_vector (31 downto 0);

    -- RMI and ERR_port
    errp_data                 : out std_logic_vector (31 downto 0);
    errp_enq                  : out std_logic;
    errp_term                 : out std_logic;
    recp_err                  : out std_logic;


    -- err.rmi <-> err interface at port
  --send_error                : out std_logic_vector (NR_PORTS - 1 downto 0);
    send_error_id             : out t_portid;
    error_flags               : in  std_logic_vector (NR_PORTS - 1 downto 0);
    error_data                : in  std_logic_vector (31 downto 0);

    -- status.rmi <-> mon interface at port
    status_data               : in  std_logic_vector (31 downto 0);
    status_port_id            : out t_portid;                   --max port=256
    --preamble (127:120)  reserve(119:72) port_ID (71:64) command_ID (63:56) new_value(63:0)

    -- reconf.rmi <-> reconf interface at port
    reconf_data               : out std_logic_vector (15 downto 0);
  --reconf_port_sel           : out std_logic_vector (NR_PORTS - 1 downto 0);
    reconf_port_id            : out t_portid;

    pTTCommSchedAddrOut	      : out t_ttcommsched_addr;
    pTTCommSchedDataOut		    : out t_ttcommsched;
    pTTCommSchedWrEnOut		    : out std_logic;
    --------------------------------------------------
    --added by RAKOTOJAONA for the adaptation
    
    pTTCommSchedAddrOut2	      : out t_ttcommsched_addr;
    pTTCommSchedDataOut2		    : out t_ttcommsched;
    pTTCommSchedWrEnOut2	    : out std_logic;
    
    -------------------------------------------------
    ---triggered changed in adaptive RMI
    tx_adaptiveRMI : in bit;
    tx_mux : out bit ; -- select the scheduled used by the dispatcher.    
    --------------------------------------------------
    pETCommSchedAddrOut	      : out t_etcommsched_addr;
    pETCommSchedDataOut		    : out t_etcommsched;
    pETCommSchedWrEnOut		    : out std_logic;
    -- activation / deactivation of specific periods
		pPeriodEnaOut		          : out std_logic_vector(NR_PERIODS-1 downto 0);
    -- trigger signal for reconfiguration instant
    pReconfInstOut		        : out std_logic;
    -- pPortIdIn_Ebu            : in std_logic_vector (PORTID_WIDTH - 1 downto 0);
    pTimeCnt                  : in  t_timeformat;
   
    clk							      : in std_logic;	-- system clock
    reset_n					          : in std_logic	-- hardware reset
  );
end rmi;

architecture behavioural of rmi is
constant tts              : at_pcfg := ttel_pcfg (PROJECT_PATH & INITDIR, "ttcommsched1.cfg", MY_ID);
constant tts2             : at_pcfg := ttel_pcfg (PROJECT_PATH & INITDIR, "ttcommsched2.cfg", MY_ID);

--by darshak signal which contains  tt_sched_data from tts
signal tt_sched_data          : std_logic_vector (128 - 1 downto 0);
signal tt_sched_data2          : std_logic_vector (128 - 1 downto 0);
--state machine for Adaptive RMI -- by RAKOTOJAONA Nambinina

constant Initial : std_logic_vector (3 downto 0) := "0001";
constant WaitEvent : std_logic_vector (3 downto 0) := "0010";
constant WriteScheduleMem1 : std_logic_vector (3 downto 0) := "0100";
constant WriteScheduleMem2 : std_logic_vector (3 downto 0) := "1000";

signal state : std_logic_vector (3 downto 0) := "0001";

component prescaler
generic(
  	n               : integer := 600;
  	count1_length   : integer := 15
  );
  port(
  	clk 			: in  std_logic;
  	rstn			: in  std_logic;
  	freq			: out std_logic            -- clk > 2freq  hz
  );
end component;

  component port_status_interface
generic(
  count1_length   : integer :=8;
  PORTDATA_WIDTH  : integer := 32;
  NR_PORTS        : integer
  );

port(
    clk               : in  std_logic;
    rstn			  : in std_logic;
    freq              : in  std_logic;                      -- clk > 2freq  hz
    pTimeCnt          : in  t_timeformat;
    port_data         : in std_logic_vector (PORTDATA_WIDTH - 1 downto 0);
    port_add          : out t_portid;  --Max Port=255
    monp_data         : out std_logic_vector (31 downto 0);
    monp_addr         : out std_logic_vector (8 downto 0);
    monp_enq          : out std_logic;
    monp_term         : out std_logic
	);
	END component;

  component rmi_err_int
  generic(
  	count1_length           : integer :=10;
    NR_PORTS                : integer
  );
  port(
  	clk							: in  std_logic;
    rstn			  			: in std_logic;
    error_data			        : in  std_logic_vector (31 downto 0);
  --send_error			        : out std_logic_vector (NR_PORTS - 1 downto 0);
    send_error_id               : out t_portid;
  	error_flags 			    : in  std_logic_vector (NR_PORTS - 1 downto 0);
  	errp_enq				    : out std_logic;
  	errp_term    		        : out std_logic;
  	errp_data				    : out std_logic_vector (31 downto 0)
  );
end component;

component rmi_rec_int
generic (
    NR_PORTS                  : integer
);

port(
  clk 							: in std_logic;
  rstn							: in std_logic;
  new_conf 						: in std_logic;
  --preamble (127:120)  reserve(119:80) port_ID (79:72) command_ID (71:64) new_value(63:0)
  recp_data      				: in  std_logic_vector (PORTDATA_WIDTH - 1 downto 0);
  recp_deq 					    : out std_logic;
  reconf_data      	        	: out std_logic_vector (15 downto 0);
  --reconf_port_sel		        : out std_logic_vector (NR_PORTS - 1 downto 0);
  reconf_port_id  				: out t_portid;
  err_out						: out std_logic
);
END component;

signal freq1 : std_logic :='0';

begin

clock_prescaler_inst : prescaler
  GENERIC MAP (
  	n => 5000,
  	count1_length => 14)
  PORT MAP(
    clk => clk,
    rstn => reset_n,
    freq => freq1
  );
  
RMS_Enable: if Resource_Management_Enable = '1'
generate
  rmi_mon : port_status_interface
  generic map (
  NR_PORTS => NR_PORTS
  )
  PORT MAP(
    clk=>clk,
    rstn => reset_n,
    freq=>freq1,                     -- clk > 2freq  hz
    pTimeCnt=>pTimeCnt,
    port_data => status_data,
    port_add=>status_port_id,        --Max Port=255
    monp_data=>monp_data,
    monp_addr=>monp_addr,
    monp_enq=>monp_enq,
    monp_term=>monp_term
  );

  rmi_err : rmi_err_int
  generic map (
    NR_PORTS => NR_PORTS
    )
  PORT MAP(
    clk=>clk,
    rstn => reset_n,
    error_data=>error_data,
    error_flags=>error_flags,
    errp_enq=>errp_enq,
    errp_term=>errp_term,
  --send_error=>send_error,
    send_error_id=>send_error_id,
    errp_data=>errp_data
  );

  rmi_rec : rmi_rec_int
  generic map (
  NR_PORTS => NR_PORTS
  )
  PORT MAP(
    clk=>clk,
    rstn => reset_n,
    new_conf=>new_conf,
    recp_data=>recp_data,
    reconf_data=>reconf_data,
  --reconf_port_sel=>reconf_port_sel,
    reconf_port_id=>reconf_port_id,
    recp_deq=>recp_deq,
    err_out => recp_err
  );
end generate;  


process (clk , reset_n ,tx_adaptiveRMI)
variable ramUsed : std_logic ;
variable cntr :  std_logic_vector (8- 1 downto 0);
variable cntr_data :  std_logic_vector (8- 1 downto 0);
begin
    if (reset_n = '0' ) then
                 tx_mux <= '0';
                 pTTCommSchedAddrOut <= (others => '0');
                 pTTCommSchedDataOut.BranchId <= (others => '0');
                 pTTCommSchedDataOut.NextPtr <= (others => '0');
                 pTTCommSchedDataOut.Instant <= (others => '0');
                 pTTCommSchedDataOut.PortId <= (others => '0');
                 pTTCommSchedWrEnOut <= '0';
                 pReconfInstOut <= '0';                    
                 pPeriodEnaOut <= (0 => '1', others => '0');
                 cntr :=(others=>'0');
                 cntr_data :=(others => '0');
                 tt_sched_data <=tts(0);
                 ramUsed := '0';
                 ------------------------------------------------------------------------------------------
                 pTTCommSchedAddrOut2 <= (others => '0');
                 pTTCommSchedDataOut2.BranchId <= (others => '0');
                 pTTCommSchedDataOut2.NextPtr <= (others => '0');
                 pTTCommSchedDataOut2.Instant <= (others => '0');
                 pTTCommSchedDataOut2.PortId <= (others => '0');
                 pTTCommSchedWrEnOut2 <= '0';
 
                 tt_sched_data2 <=tts2(0);
                 state <= Initial ;
                 
       else 
        if (rising_edge (clk)) then
                case state is
                    when Initial =>
                        -- OFL
                             cntr := cntr +1 ;
                             cntr_data := cntr_data+"1";
                             pTTCommSchedAddrOut <= cntr(7 downto 0)-'1';
                             pTTCommSchedDataOut.BranchId <=tt_sched_data (3 downto 0);                          
                             pTTCommSchedDataOut.PortId <= tt_sched_data (11 downto 4);                        
                             pTTCommSchedDataOut.Instant <= tt_sched_data (23 downto 12);                   
                             pTTCommSchedDataOut.NextPtr <= tt_sched_data (31 downto 24);
                           
                             tt_sched_data <=tts(to_integer(unsigned(cntr_data)));
                             pTTCommSchedWrEnOut <= '1';
                            
                            
                        -- NSL
                            if (cntr< 5) then
                                state <= Initial;
                            else 
                                state <= WaitEvent;
                                cntr := (others => '0');
                                cntr_data :=(others => '0');
                            end if ;
                            
                     when WaitEvent =>
                         --OFL
                         pTTCommSchedAddrOut <= (others => '0');
                         pTTCommSchedDataOut.BranchId <= (others => '0');
                         pTTCommSchedDataOut.NextPtr <= (others => '0');
                         pTTCommSchedDataOut.Instant <= (others => '0');
                         pTTCommSchedDataOut.PortId <= (others => '0');
                         pTTCommSchedWrEnOut <= '0';
                         tt_sched_data <=tts(0);
                         ------------------------------------------------------------------------------------------
                         pTTCommSchedAddrOut2 <= (others => '0');
                         pTTCommSchedDataOut2.BranchId <= (others => '0');
                         pTTCommSchedDataOut2.NextPtr <= (others => '0');
                         pTTCommSchedDataOut2.Instant <= (others => '0');
                         pTTCommSchedDataOut2.PortId <= (others => '0');
                         pTTCommSchedWrEnOut2 <= '0';

                         tt_sched_data2 <=tts2(0);                         
                
                         --NSL
                            if (tx_adaptiveRMI = '1' and ramUsed = '1') then
                                state <= WriteScheduleMem1;
                                ramUsed := '0';
                            elsif (tx_adaptiveRMI = '1' and ramUsed = '0') then
                                state <= WriteScheduleMem2 ;
                                 ramUsed := '1';
                            else
                                state <= WaitEvent;
                            end if ;
                            
                      when WriteScheduleMem1 =>
                          -- OFL
                             cntr := cntr +1 ;
                             cntr_data := cntr_data+"1";
                             
                             if (cntr =4) then
                                tx_mux <= '0';
                             end if ;
                             pTTCommSchedAddrOut <= cntr(7 downto 0) - '1';
                             pTTCommSchedDataOut.BranchId <=tt_sched_data (3 downto 0);                          
                             pTTCommSchedDataOut.PortId <= tt_sched_data (11 downto 4);                        
                             pTTCommSchedDataOut.Instant <= tt_sched_data (23 downto 12);                   
                             pTTCommSchedDataOut.NextPtr <= tt_sched_data (31 downto 24);
                           
                             tt_sched_data <=tts(to_integer(unsigned(cntr_data)));
                             pTTCommSchedWrEnOut <= '1';
                          -- NSL
                             if (cntr <5) then
                                state <= WriteScheduleMem1;
                             else
                                state <= WaitEvent;
                                cntr := (others => '0');
                                cntr_data :=(others => '0');
                             end if ;
                             
                      when WriteScheduleMem2 =>
                          -- OFL
                             cntr := cntr +1 ;
                             cntr_data := cntr_data+"1";
                             if (cntr =4) then
                                tx_mux <= '1';
                             end if ;
                             pTTCommSchedAddrOut2 <= cntr(7 downto 0)- '1';
                             pTTCommSchedDataOut2.BranchId <=tt_sched_data2 (3 downto 0);                          
                             pTTCommSchedDataOut2.PortId <= tt_sched_data2 (11 downto 4);                        
                             pTTCommSchedDataOut2.Instant <= tt_sched_data2 (23 downto 12);                   
                             pTTCommSchedDataOut2.NextPtr <= tt_sched_data2 (31 downto 24);
                           
                             tt_sched_data2 <=tts2(to_integer(unsigned(cntr_data)));
                             pTTCommSchedWrEnOut2 <= '1';
                          -- NSL
                             if (cntr <5) then
                                state <= WriteScheduleMem2;
                             else
                                state <= WaitEvent;
                                cntr := (others => '0');
                                cntr_data :=(others => '0');
                             end if ;
                            
                      when others =>
                        -- do nothing.
                 end case ;
        
        end if ;
    end if ;
    
end process;
end behavioural;

--    if (reset_n = '0' ) then
----            tx_mux <= '0';
----            pTTCommSchedAddrOut <= (others => '0');
----            pTTCommSchedDataOut.BranchId <= (others => '0');
----            pTTCommSchedDataOut.NextPtr <= (others => '0');
----            pTTCommSchedDataOut.Instant <= (others => '0');
----            pTTCommSchedDataOut.PortId <= (others => '0');
----            pTTCommSchedWrEnOut <= '0';
----            pReconfInstOut <= '0';                    
----            pPeriodEnaOut <= (0 => '1', others => '0');
----            cntr <=(others=>'0');
----            cntr_data <=(0=>'1',others=>'0');
----            tt_sched_data <=tts(0);
            
----            ------------------------------------------------------------------------------------------
----            pTTCommSchedAddrOut2 <= (others => '0');
----            pTTCommSchedDataOut2.BranchId <= (others => '0');
----            pTTCommSchedDataOut2.NextPtr <= (others => '0');
----            pTTCommSchedDataOut2.Instant <= (others => '0');
----            pTTCommSchedDataOut2.PortId <= (others => '0');
----            pTTCommSchedWrEnOut2 <= '0';

----            cntr2 <=(others=>'0');
----            cntr_data2 <=(0=>'1',others=>'0');
----            tt_sched_data2 <=tts2(0);
----            state <= IDLE ;
--      else
--        if (rising_edge (clk)) then 
--            case state is 
--                when IDLE  =>
--                -- NSL 
--                     state <= R_WSA;
--                -- OFL
                
--                     pTTCommSchedAddrOut <= (others => '0');
--                     pTTCommSchedDataOut.BranchId <= (others => '0');
--                     pTTCommSchedDataOut.NextPtr <= (others => '0');
--                     pTTCommSchedDataOut.Instant <= (others => '0');
--                     pTTCommSchedDataOut.PortId <= (others => '0');
--                     pTTCommSchedWrEnOut <= '0';
--                     pReconfInstOut <= '0';                    
--                     pPeriodEnaOut <= (0 => '1', others => '0');
--                     cntr <=(others=>'0');
--                     cntr_data <=(0=>'1',others=>'0');
--                     tt_sched_data <=tts(0);
                     
--                     ------------------------------------------------------------------------------------------
--                     pTTCommSchedAddrOut2 <= (others => '0');
--                     pTTCommSchedDataOut2.BranchId <= (others => '0');
--                     pTTCommSchedDataOut2.NextPtr <= (others => '0');
--                     pTTCommSchedDataOut2.Instant <= (others => '0');
--                     pTTCommSchedDataOut2.PortId <= (others => '0');
--                     pTTCommSchedWrEnOut2 <= '0';

--                     cntr2 <=(others=>'0');
--                     cntr_data2 <=(0=>'1',others=>'0');
--                     tt_sched_data2 <=tts2(0);
                
--                when R_WSA =>
--                -- NSL
                
                   
--                    if (cntr < "0100") then
--                        state  <= R_WSA;
                        
--                    else 
--                        state <= WAIT1;
                       
--                    end if ;
--                --OFL    
                
--                  if (cntr = "0011") then
--                       tx_mux <= '0';
--                  end if ;
--                  cntr <= cntr +'1';
--                  pTTCommSchedAddrOut <= cntr(7 downto 0);
--                  pTTCommSchedDataOut.BranchId <=tt_sched_data (3 downto 0);                          
--                  pTTCommSchedDataOut.PortId <= tt_sched_data (11 downto 4);                        
--                  pTTCommSchedDataOut.Instant <= tt_sched_data (23 downto 12);                   
--                  pTTCommSchedDataOut.NextPtr <= tt_sched_data (31 downto 24);
                  
--                  tt_sched_data <=tts(to_integer(unsigned(cntr_data)));
--                  pTTCommSchedWrEnOut <= '1';
--                  cntr_data <= cntr_data+"1";

                  
                        
--               when WAIT1 =>
--               -- NSL
              
--                   if (tx_adaptiveRMI = '1') then
--                        state <= R_WSB;
--                   else 
--                        state <= WAIT1;
--                   end if ;
--                -- OFL
--                     cntr <= (others =>  '0');
--                     pTTCommSchedAddrOut <= (others => '0');
--                     pTTCommSchedDataOut.BranchId <= (others => '0');
--                     pTTCommSchedDataOut.NextPtr <= (others => '0');
--                     pTTCommSchedDataOut.Instant <= (others => '0');
--                     pTTCommSchedDataOut.PortId <= (others => '0');
--                     pTTCommSchedWrEnOut <= '0';
--                     pReconfInstOut <= '0';                    
--                     pPeriodEnaOut <= (0 => '1', others => '0');
--                     cntr_data <=(0=>'1',others=>'0');
--                     tt_sched_data <=tts(0);
                     
--                     ------------------------------------------------------------------------------------------

               
--                when R_WSB =>
--                -- NSL
--                    if (cntr2 < "0100") then
--                        state  <= R_WSB;
                        
--                    else 
--                        state <= WAIT2;
--                        cntr2 <= (others => '0');
--                    end if ;
--                --OFL
--                      if (cntr2 = "0011") then
--                             tx_mux <= '1';
--                      end if ;   
--                      cntr2 <= cntr2 +'1';
--                      pTTCommSchedAddrOut2 <= cntr2(7 downto 0);
--                      pTTCommSchedDataOut2.BranchId <=tt_sched_data2 (3 downto 0);                          
--                      pTTCommSchedDataOut2.PortId <= tt_sched_data2 (11 downto 4);                        
--                      pTTCommSchedDataOut2.Instant <= tt_sched_data2 (23 downto 12);                   
--                      pTTCommSchedDataOut2.NextPtr <= tt_sched_data2 (31 downto 24);
                      
--                      tt_sched_data2 <=tts2(to_integer(unsigned(cntr_data2)));
--                      pTTCommSchedWrEnOut2 <= '1';
--                      cntr_data2 <= cntr_data2+"1";
--                      ----------------------------------------------------------------
                         
--               when WAIT2 =>
--               -- NSL
--                   if (tx_adaptiveRMI = '1') then
--                        state <= R_WSA;
--                   else 
--                        state <= WAIT2;
--                   end if ;
--                -- OFL
--                    pTTCommSchedAddrOut2 <= (others => '0');
--                    pTTCommSchedDataOut2.BranchId <= (others => '0');
--                    pTTCommSchedDataOut2.NextPtr <= (others => '0');
--                    pTTCommSchedDataOut2.Instant <= (others => '0');
--                    pTTCommSchedDataOut2.PortId <= (others => '0');
--                    pTTCommSchedWrEnOut2 <= '0';
--                    cntr_data2 <=(0=>'1',others=>'0');
--                    tt_sched_data2 <=tts2(0);
--              when others =>
--                -- do nothing 
             
--             end case ;
            
            
            
            
--      end if ;
--    end if ;

--end process ;

--process (clk , reset_n , tx_adaptiveRMI )
--begin

--if (reset_n ='0') then
--        tx_mux <= '0';
--else
--if falling_edge (clk) then
--    case state is 
--        when  IDLE =>
--            --OFL 
--             tx_mux <= '0';
--         when R_WSA =>
--            -- OFL 
--              tx_mux <= '0';
              
--         when R_WSB =>
--            -- OFL
--              tx_mux <= '1';
--         when others =>
--            -- do nothing

--    end case ;
--end if ;

--end if ;
--end process ;

--      ttcommsched_init: process (clk)
--      begin
--        if rising_edge (clk) then
--          if reset_n = '0' then
--            pTTCommSchedAddrOut <= (others => '0');
--            pTTCommSchedDataOut.BranchId <= (others => '0');
--            pTTCommSchedDataOut.NextPtr <= (others => '0');
--            pTTCommSchedDataOut.Instant <= (others => '0');
--            pTTCommSchedDataOut.PortId <= (others => '0');
--            pTTCommSchedWrEnOut <= '0';
--            pReconfInstOut <= '0';                    
--            pPeriodEnaOut <= (0 => '1', others => '0');
--            cntr <=(others=>'0');
--            cntr_data <=(0=>'1',others=>'0');
--            tt_sched_data <=tts(0);
            
--            ------------------------------------------------------------------------------------------
--            pTTCommSchedAddrOut2 <= (others => '0');
--            pTTCommSchedDataOut2.BranchId <= (others => '0');
--            pTTCommSchedDataOut2.NextPtr <= (others => '0');
--            pTTCommSchedDataOut2.Instant <= (others => '0');
--            pTTCommSchedDataOut2.PortId <= (others => '0');
--            pTTCommSchedWrEnOut2 <= '0';

--            cntr2 <=(others=>'0');
--            cntr_data2 <=(0=>'1',others=>'0');
--            tt_sched_data2 <=tts2(0);
--            --------------------------------------------------------------------------------------------
--          else 
--           if cntr <"1010" then           
--            pTTCommSchedAddrOut <= cntr(7 downto 0);
--            pTTCommSchedDataOut.BranchId <=tt_sched_data (3 downto 0);                          
--            pTTCommSchedDataOut.PortId <= tt_sched_data (11 downto 4);                        
--            pTTCommSchedDataOut.Instant <= tt_sched_data (23 downto 12);                   
--            pTTCommSchedDataOut.NextPtr <= tt_sched_data (31 downto 24);
            
--            tt_sched_data <=tts(to_integer(unsigned(cntr_data)));
--            pTTCommSchedWrEnOut <= '1';
--            cntr <= cntr+"1";
--            cntr_data <= cntr_data+"1";
--            ----------------------------------------------------------------------------------------------
--            pTTCommSchedAddrOut2 <= cntr2(7 downto 0);
--            pTTCommSchedDataOut2.BranchId <=tt_sched_data2 (3 downto 0);                          
--            pTTCommSchedDataOut2.PortId <= tt_sched_data2 (11 downto 4);                        
--            pTTCommSchedDataOut2.Instant <= tt_sched_data2 (23 downto 12);                   
--            pTTCommSchedDataOut2.NextPtr <= tt_sched_data2 (31 downto 24);
            
--            tt_sched_data2 <=tts2(to_integer(unsigned(cntr_data2)));
--            pTTCommSchedWrEnOut2 <= '1';
--            cntr2 <= cntr2+"1";
--            cntr_data2 <= cntr_data2+"1";
--            -----------------------------------------------------------------------------------------------
--           else
--             pTTCommSchedAddrOut <= (others => '0');
--             pTTCommSchedDataOut.BranchId <= (others => '0');
--             pTTCommSchedDataOut.NextPtr <= (others => '0');
--             pTTCommSchedDataOut.Instant <= (others => '0');
--             pTTCommSchedDataOut.PortId <= (others => '0');             
--             pTTCommSchedWrEnOut <= '0';
--             -----------------------------------------------------------------------------------------------
--             pTTCommSchedAddrOut2 <= (others => '0');
--             pTTCommSchedDataOut2.BranchId <= (others => '0');
--             pTTCommSchedDataOut2.NextPtr <= (others => '0');
--             pTTCommSchedDataOut2.Instant <= (others => '0');
--             pTTCommSchedDataOut2.PortId <= (others => '0');             
--             pTTCommSchedWrEnOut2 <= '0';
--             -----------------------------------------------------------------------------------------------
             
--           end if;
--          end if;
--        end if;
--      end process;
  
   


