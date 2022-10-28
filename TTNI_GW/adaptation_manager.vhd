----------------------------------------------------------------------------------
-- Company: Embedded Systems, Universit√§t Siegen
-- Engineer: Yosab Bebawy
--
-- Create Date:  03/07/2017
-- Design Name:
-- Module Name: Adaptatipn Manager

----------------------------------------------------------------------------------------------------
-- Project		  : SAFEPOWER
-- Module         : Adaptatipn Manager
-- File			  : adaptatipn_manager.vhd
-- Author         : Yosab Bebawy
-- created		  : July, 3rd 2017
-- last mod. by	  : Yosab Bebawy
-- last mod. on	  :
-- contents		  : Adaptatipn Manager - Behavioral
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- library includes
----------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;	-- for conv_integer
use IEEE.std_logic_unsigned.all;

library SAFEPOWER;
use SAFEPOWER.TTEL.all;        		-- constants, datatypes, and component declarations of the current TTEL
use SAFEPOWER.ttel_parameter.all;	-- for TTCOMMSCHED_SIZE

library SYSTEMS;
use SYSTEMS.system_parameter.all;	-- parameters of the current NoC instance

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity adaptation_manager is
  generic(
    MY_ID                   : integer := 0
  );
  Port (
    clk					: in std_logic;	-- system clock
    reset_n             : in std_logic;    -- hardware reset
    CmpMatch		    : in std_logic;
    Event_ID            : in std_logic_vector (31 downto 0);
    ScheduledEntry      : in t_ttcommsched; --64bits
    BranchedEntry       : out t_ttcommsched;
    BranchDone          : out std_logic
  );
end adaptation_manager;

architecture Behavioral of adaptation_manager is

 type state is (RESET, IDLE, CHANGE_SCHED, WAIT_CHANGE_SCHED, TRIG_CHANGE_SCHED, NO_CHANGE_SCHED , CHANGE_SCHED_DONE);
 signal present_state      				: state;
 signal next_state                      : state;
 signal sBranchDone     : std_logic;
 signal sBranchedEntry  : t_ttcommsched;
 signal sEvent_ID       : std_logic_vector (7 downto 0);
 
begin
sEvent_ID <= Event_ID (7 downto 0) when MY_ID = 0 else
             Event_ID (15 downto 8) when MY_ID = 1 else
             Event_ID (23 downto 16) when MY_ID = 2 else
             Event_ID (31 downto 24) when MY_ID = 3;
             
BranchedEntry <= sBranchedEntry;
BranchDone <= sBranchDone;
--process (CmpMatch,reset_n, ScheduledEntry)
--begin
--    if reset_n = '0' then
--	   sBranchedEntry <= (BranchId=>(others=>'0'), NextPtr=>(others=>'0'), Instant=>(others=>'0'), PortId=>(others=>'0'));
--	   sBranchDone <= '0';
--    --elsif rising_edge(clk) then
--    elsif ScheduledEntry.BranchId /= 0 then
--       if sEvent_ID /= 0 then
--		     sBranchedEntry.NextPtr <= ScheduledEntry.NextPtr + ScheduledEntry.BranchId;
--		      sBranchedEntry.BranchId <= ScheduledEntry.BranchId;
--		      sBranchedEntry.Instant <=  ScheduledEntry.Instant;
--		      sBranchedEntry.PortId <= ScheduledEntry.PortId;
--	   else
--	       	sBranchedEntry <= ScheduledEntry;     
--	   end if;	      
--    else
--		      sBranchedEntry <= ScheduledEntry;    
		   
--		      sBranchDone <= '1';
--		--  elsif sBranchDone = '1' then
--		    --  sBranchDone <= '0';   
--		  end if;
--end process;

process (reset_n,present_state,CmpMatch, ScheduledEntry)
begin
    if reset_n = '0' then
	   sBranchedEntry <= (BranchId=>(others=>'0'), NextPtr=>(others=>'0'), Instant=>(others=>'0'), PortId=>(others=>'0'));
	   --sBranchDone <= '0';
    --elsif rising_edge(clk) then
    --elsif ScheduledEntry.BranchId /= 0 then
       elsif present_state = TRIG_CHANGE_SCHED or present_state = CHANGE_SCHED_DONE then
		     sBranchedEntry.NextPtr <= ScheduledEntry.NextPtr + ScheduledEntry.BranchId; -- ≤√¥ «branch
		      sBranchedEntry.BranchId <= ScheduledEntry.BranchId;
		      sBranchedEntry.Instant <=  ScheduledEntry.Instant;
		      sBranchedEntry.PortId <= ScheduledEntry.PortId;
		      
	   elsif present_state = IDLE then
	       	sBranchedEntry <= ScheduledEntry; 
	   else
	        sBranchedEntry <= sBranchedEntry;    	   
	   end if;	      
    --else
		      --sBranchedEntry <= ScheduledEntry;    
		   
		     -- sBranchDone <= '1';
		--  elsif sBranchDone = '1' then
		    --  sBranchDone <= '0';   
		  --end if;
end process;			  
	process (reset_n, present_state, CmpMatch, ScheduledEntry)
    begin
        if reset_n = '0' then
            next_state <= RESET;
        else
            case present_state is
                when RESET => 
                    next_state <= IDLE;
                when IDLE =>
                    if CmpMatch = '1' then
                        next_state <= CHANGE_SCHED;
                    else
                        next_state <= IDLE;    
                    end if;    
                when CHANGE_SCHED =>
                    next_state <= WAIT_CHANGE_SCHED;
                when WAIT_CHANGE_SCHED =>
                    if ScheduledEntry.BranchId /= 0 then
                        if sEvent_ID /= 0 then
                            next_state <= TRIG_CHANGE_SCHED;
                        else
                            next_state <= IDLE;    
                        end if;    
                    else
                        next_state <= IDLE;      
                    end if;
                when TRIG_CHANGE_SCHED =>
                         next_state <= CHANGE_SCHED_DONE;   
                when CHANGE_SCHED_DONE =>
                    next_state <= IDLE;
                when others =>
                    next_state <= RESET;                                     
            end case;
        end if;        
    end process;	     
	
	process (clk)    --Sequential 
       begin 
          if rising_edge (clk) then 
             if reset_n = '0' then 
                present_state <= RESET; 
             else 
                present_state <= next_state; 
             end if; 
          end if; 
       end process;
     sBranchDone <= '1' when  present_state = CHANGE_SCHED or present_state = WAIT_CHANGE_SCHED or present_state = TRIG_CHANGE_SCHED else '0';  
--    process (clk)    --Sequential 
--    begin 
--       if rising_edge (clk) then 
--            if reset_n = '0' then 
--                sBranchDone <= '0'; 
--            elsif  present_state /= IDLE then 
--                sBranchDone <= '1';
--            else
--                sBranchDone <= '0';    
--            end if; 
--        end if; 
--    end process;	  


end Behavioral;
