------------------------------------------------------------------------------------------------------
-- Project		: SAFEPOWER
-- Module       : DoubleBuffer
-- File			: double_buffer.vhd
-- Author		: Hamidreza Ahmadian
-- created		: September, 17th 2015
-- last mod. by	: Hamidreza Ahmadian
-- last mod. on	:
-- last mod. by	: Yosab Bebawy
-- last mod. on	: June, 9th 2017 (Use BRAMs instead of buffers)
-- contents		: architecture of a double buffer for state ports
------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------
-- library includes
------------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;


entity double_buffer is
  generic (
		AddrWidth				: natural:= 4;
		Addr_Width             : natural := 10;
		WordWidth				: natural:= 32;
		DATA_WIDTH             : natural := 36
	);
	port (
        wr_en					: in std_logic;
        wr_ter					: in std_logic;   -- shenm ???
	wr_addr_en				: in std_logic; 
        wr_addr					: in std_logic_vector (AddrWidth - 1 downto 0); 
        wr_data					: in std_logic_vector(WordWidth-1 downto 0);
        rd_en					: in std_logic;
	rd_addr_en				: in std_logic; 
        rd_addr					: in std_logic_vector (AddrWidth - 1 downto 0); 
        rd_data		 			: out std_logic_vector(WordWidth-1 downto 0);
        msglen          		: out std_logic_vector (Addr_Width-1 downto 0);
        bFull           		: out std_logic;
        full            		: out std_logic;
        bEmpty          		: out std_logic;
        empty           		: out std_logic;
        reset_n         		: in std_logic;
        clk 					: in std_logic
	);
end double_buffer;




architecture sig_buffer of double_buffer is

  constant C_MAX_NUM_ELEMENTS : unsigned (AddrWidth downto 0) := (AddrWidth => '1', others => '0');

    type buffer_type is array(0 to (2 ** AddrWidth - 1)) of unsigned (WordWidth - 1 downto 0 ); -- TODO: is it correct to have unsigned for the buffer?

    signal  rIsUp2Date          : std_logic;
    signal  rIsUp2Date_d        : std_logic;

    signal  buffer_inst0        : buffer_type;

    signal  wrpntr0             : unsigned (AddrWidth  downto 0) := (others => '0');
    signal  rdpntr0             : unsigned (AddrWidth  downto 0) := (others => '0');
    signal  ungoing_read0       : std_logic;
    signal  ungoing_write0      : std_logic;
    signal  rFull0              : std_logic;
    signal  rEmpty0             : std_logic;
    signal  rEmpty0_d           : std_logic;
    signal  rEmptyPulse0        : std_logic;
    signal  msglen0             : unsigned (AddrWidth downto 0) := (others => '0');
    signal  rstn0               : std_logic;
    signal  wEnq0               : std_logic;
    signal  wTerminate0         : std_logic;
    signal  wDin0               : std_logic_vector (WordWidth - 1 downto 0);
    signal  rFull0_d            : std_logic;
    signal  rFullPulse0         : std_logic;
    signal  sWriteDone0         : std_logic;
    signal  wDeq0               : std_logic;
    signal  wDeqDone0           : std_logic;
    signal  wDout0              : std_logic_vector (WordWidth - 1 downto 0);

    signal  buffer_inst1        : buffer_type;

    signal  wrpntr1             : unsigned (AddrWidth  downto 0) := (others => '0');
    signal  rdpntr1             : unsigned (AddrWidth  downto 0) := (others => '0');
    signal  ungoing_read1       : std_logic;
    signal  ungoing_write1      : std_logic;
    signal  rFull1              : std_logic;
    signal  rEmpty1             : std_logic;
    signal  rEmpty1_d           : std_logic;
    signal  rEmptyPulse1        : std_logic;
    signal  msglen1             : unsigned (AddrWidth downto 0) := (others => '0');
    signal  rstn1               : std_logic;
    signal  wEnq1               : std_logic;
    signal  wTerminate1         : std_logic;
    signal  sWriteDone1         : std_logic;
    signal  wDin1               : std_logic_vector (WordWidth - 1 downto 0);
    signal  rFull1_d            : std_logic;
    signal  rFullPulse1         : std_logic;
    signal  wDeq1               : std_logic;
    signal  wDeqDone1           : std_logic;
    signal  wDout1              : std_logic_vector (WordWidth - 1 downto 0);

    signal  ungoing_read        : std_logic;
    signal  ungoing_write       : std_logic;
    signal  wDeq_connected      : std_logic;
    signal  wEnq_connected      : std_logic;
    signal  rEmpty              : std_logic;
    signal  rBEmpty             : std_logic;
    signal  rBFull              : std_logic;
    signal  wDeq                : std_logic;
    signal  wEnq                : std_logic;
    signal  toggle_done         : std_logic;
    signal  toggle_pending      : std_logic;
    signal  sWriteDone          : std_logic;
    signal  sDeqDone            : std_logic;
    signal  nqd                 : std_logic_vector (AddrWidth downto 0);
    signal  last_d              : std_logic;
    
  begin

    empty <= rEmpty;
    bEmpty <= rBEmpty;
    bFull <= rBFull;
    full <= '0';
    wDin0 <= wr_data;
    wDin1 <= wr_data;
    wEnq <= wr_en AND wEnq_connected;
    wDeq <= rd_en when rEmpty /= '1'and wDeq_connected = '1'else '0'; --  AND wDeq_connected = '1';

    ungoing_read <= ungoing_read0 OR ungoing_read1;
    ungoing_write <= ungoing_write0 OR ungoing_write1;

    sWriteDone0 <= wTerminate0; -- OR rFullPulse0;
    sWriteDone1 <= wTerminate1; -- OR rFullPulse1;
    sWriteDone <= sWriteDone0 when rIsUp2Date = '1' else sWriteDone1;  --rIsUp2Date==1 shihou  0 shi write operation 1shi read operation
    sDeqDone <= wDeqDone1 when rIsUp2Date = '1' else wDeqDone0;
    msglen(AddrWidth downto 0) <= std_logic_vector (msglen1) when rIsUp2Date = '1' else std_logic_vector (msglen0);
    --state machine for connecting the signals to the buffer instants
    --rd_data <= wDout0 when ungoing_read1 = '1' else wDout1 when ungoing_read0 = '1';
    --rd_data <= wDout1 when wDeq1 = '1'  else wDout0 when wDeq0 = '1';
    
    
    rd_data <= wDout1 when rIsUp2Date = '1'  else wDout0;
    
    
    wDeq1 <= wDeq when rIsUp2Date = '1' else '0';
    wDeq0 <= wDeq when rIsUp2Date = '0' else '0';
    
    rBFull <= rFull0  when rIsUp2Date = '1' else rFull1;
    rBEmpty <= rEmpty1  when rIsUp2Date = '1' else rEmpty0;
    rEmpty <= rEmpty1 when rIsUp2Date = '1' else rEmpty0;
     

    wEnq0 <= wEnq when rIsUp2Date = '1' else '0';
    wEnq1 <= wEnq when rIsUp2Date = '0' else '0';
    
   
    rEmpty0 <= '1' when msglen0 = 0 else '0';

    rFullPulse0 <= rFull0 and not rFull0_d;
    rFull0  <= '1' when msglen0 = C_MAX_NUM_ELEMENTS else '0';
    msglen0 <= wrpntr0 - rdpntr0;
    rFull1  <= '1' when msglen1 = C_MAX_NUM_ELEMENTS else '0';
    msglen1 <= wrpntr1 - rdpntr1;
    rFullPulse1 <= rFull1 and not rFull1_d;
    rEmpty1 <= '1' when msglen1 = 0 else '0';
    rEmptyPulse0 <= rEmpty0 and not rEmpty0_d;
    rEmptyPulse1 <= rEmpty1 and not rEmpty1_d;


    -- process for controlling the wEnq_connected
    -- it will be connected if the buffer is not full and the wr_en is not assserted
    -- TODO: should I replace last_d with sWriteDone??
    process (reset_n,clk)
    begin
      if reset_n = '0' then
        wEnq_connected <= '1';
      elsif rising_edge (clk) then
        if wr_en = '0' then
          if toggle_pending = '1' then  --biaoshi zhengzai zhuanhuan FIFO qijian 
            wEnq_connected <= '0';
          else
            wEnq_connected <= '1';
          end if;
        end if;
      end if;
    end process;


    --TODO: wdeq_connected shall be completed.
    -- process for connecting the rden to the wDeq: wDeq_connected
    -- it will be connected if the port is not empty and the rden is not assserted
    -- process (reset_n,clk) rden, sDeqDone, rBEmpty)
    -- begin
    --   if reset_n = '0' then
    --     wDeq_connected <= '0';
    --   else
    --     if wDeq_connected = '0' then
    --       if rden /= '1' AND rBEmpty /= '1' then
    --         wDeq_connected <= '1';
    --       else
    --         wDeq_connected <= '0';
    --       end if;
    --     elsif sDeqDone = '1' then
    --       wDeq_connected <= '0';
    --     else
    --       wDeq_connected <= '1';
    --     end if;
    --   end if;
    -- end process;
    
    
     --TODO: wdeq_connected shall be completed.
--     process for connecting the rden to the wDeq: wDeq_connected
--     it will be connected if the port is not empty and the rden is not assserted
     process (reset_n,clk, rd_en, sDeqDone, rBEmpty)
     begin
       if reset_n = '0' then
         wDeq_connected <= '0';
       elsif rising_edge (clk) then
         if wDeq_connected = '0' then
           if rd_en = '1' AND rBEmpty /= '1' then --rd_en = '1'
             wDeq_connected <= '1';
           else
             wDeq_connected <= '0';
           end if;
         elsif sDeqDone = '1' then
           wDeq_connected <= '0';
         else
           wDeq_connected <= '1';
         end if;
       end if;
     end process;   

    -- process for generation of wDeqDone0
    process (rstn0, clk)
    begin
      if rstn0 = '0' then
        wDeqDone0 <= '0';
      elsif rising_edge (clk) then
        wDeqDone0 <= rEmptyPulse0;
      end if;
    end process;


    -- process for generation of wDeqDone1
    process (rstn1, clk)
    begin
      if rstn1 = '0' then
        wDeqDone1 <= '0';
      elsif rising_edge (clk) then
        wDeqDone1 <= rEmptyPulse1;
      end if;
    end process;

    -- process for generation of ungoing_write0 -- zhengzai xie
    process (rstn0,clk)
    begin
      if rstn0 = '0' then
        ungoing_write0 <= '0';
      elsif rising_edge (clk) then
        if wEnq0 = '1' and ungoing_write0 = '0' then
          ungoing_write0 <= '1';
        elsif sWriteDone0 = '1' and ungoing_write0 = '1' then
          ungoing_write0 <= '0';
        else
          ungoing_write0 <= ungoing_write0;
        end if;
      end if;
    end process;

    -- process for generation of ungoing_write1
    process (rstn1,clk)
    begin
      if rstn1 = '0' then
        ungoing_write1 <= '0';
      elsif rising_edge (clk) then
        if wEnq1 = '1' and ungoing_write1 = '0' then
          ungoing_write1 <= '1';
        elsif sWriteDone1 = '1' and ungoing_write1 = '1' then
          ungoing_write1 <= '0';
        else
          ungoing_write1 <= ungoing_write1;
        end if;
      end if;
    end process;

    -- process for generation of ungoing_read0
    process (rstn0,clk)
    begin
      if rstn0 = '0' then
        ungoing_read0 <= '0';
      elsif rising_edge (clk) then
        if wDeq0 = '1' and ungoing_read0 = '0' then
          ungoing_read0 <= '1';
        elsif wDeqDone0 = '1' and ungoing_read0 = '1' then
          ungoing_read0 <= '0';
        else
          ungoing_read0 <= ungoing_read0;
        end if;
      end if;
    end process;

    -- process for generation of ungoing_read1
    process (rstn1,clk)
    begin
      if rstn1 = '0' then
        ungoing_read1 <= '0';
      elsif rising_edge (clk) then
        if wDeq1 = '1' and ungoing_read1 = '0' then
          ungoing_read1 <= '1';
        elsif wDeqDone1 = '1' and ungoing_read1 = '1' then
          ungoing_read1 <= '0';
        else
          ungoing_read1 <= ungoing_read1;
        end if;
      end if;
    end process;

    -- process for generation of the rEmpty
    -- this is empty only if there is no state data in both buffers.
    -- process (reset_n,clk)
    -- begin
    --   if reset_n = '0' then
    --     rEmpty <= '1';
    --   elsif rising_edge (clk) then
    --     if rEmpty = '1' and rIsUp2Date = '0' then
    --       rEmpty <= '0';
    --     else
    --       rEmpty <= '1';
    --     end if;
    --   end if;
    -- end process;


    -- process for generation of rstn0 and rstn1
    process (reset_n,clk)
    begin
      if reset_n = '0' then
        rstn0 <= '0';
        rstn1 <= '0';
      elsif rising_edge (clk) then
        if toggle_done = '1' and rIsUp2Date_d = '1'then 
          rstn1 <= '0';
        elsif toggle_done = '1' and rIsUp2Date_d = '0' then 
          rstn0 <= '0';
        else
          rstn0 <= '1';
          rstn1 <= '1';
        end if;
      end if;
    end process;

    -- process for buffer_inst1
    process (clk,rstn0)
    begin
      if rstn0 = '0' then
        wrpntr0 <= (others => '0');
        rdpntr0 <= (others => '0');
      elsif rising_edge (clk) then
        if (wEnq0 = '1' AND rFull0 = '0') then
          if wr_addr_en = '1' then 
			  buffer_inst0 (to_integer (unsigned (wr_addr))) <= unsigned(wDin0);
			  wrpntr0 (AddrWidth - 1 downto 0) <= unsigned (wr_addr); 
		  else 
			  buffer_inst0 (to_integer (wrpntr0 (AddrWidth - 1 downto 0))) <= unsigned(wDin0);
			  wrpntr0 <= wrpntr0 + 1;
		  end if; 
        end if;
        if (wDeq0 = '1' AND rEmpty0 = '0') then
			if rd_addr_en = '1' then 
	          wDout0 <= std_logic_vector (buffer_inst0 (to_integer(unsigned (rd_addr))));
	          rdpntr0 (AddrWidth - 1 downto 0) <= unsigned (rd_addr); 

	        else
	          wDout0 <= std_logic_vector (buffer_inst0 (to_integer(rdpntr0 (AddrWidth - 1 downto 0))));
		      rdpntr0 <= rdpntr0 + 1;
	        end if; 
        end if;
      end if;
    end process;


    -- process for buffer_inst1
    process (clk,rstn1)
    begin
      if rstn1 = '0' then
        wrpntr1 <= (others => '0');
        rdpntr1 <= (others => '0');
      elsif rising_edge (clk) then
        if (wEnq1 = '1' AND rFull1 = '0') then
			if wr_addr_en = '1' then 
			  buffer_inst1 (to_integer (unsigned (wr_addr))) <= unsigned(wDin1);
			else 
			  buffer_inst1 (to_integer (wrpntr1 (AddrWidth - 1 downto 0))) <= unsigned(wDin1);
			  wrpntr1 <= wrpntr1 + 1;
			end if; 
        end if;
        if (wDeq1 = '1' AND rEmpty1 = '0') then
			if rd_addr_en = '1' then 
			  wDout1 <= std_logic_vector (buffer_inst1 (to_integer(unsigned (rd_addr))));
	        else
			  wDout1 <= std_logic_vector (buffer_inst1 (to_integer(rdpntr1 (AddrWidth - 1 downto 0))));
			  rdpntr1 <= rdpntr1 + 1;
			end if; 
        end if;
      end if;
    end process;


    process (clk)
    begin
      if reset_n = '0' then
        rIsUp2Date_d <= '1';
        rFull0_d <= '0';
        rFull1_d <= '0';
        rEmpty0_d <= '0';
        rEmpty1_d <= '0';
      elsif rising_edge (clk) then
        rEmpty0_d <= rEmpty0;
        rEmpty1_d <= rEmpty1;
        rFull0_d <= rFull0;
        rFull1_d <= rFull1;
        rIsUp2Date_d <= rIsUp2Date;
      end if;
  	end process;

    -- process for generation of last_d     --zhe shi shenm ?
    -- TODO: using wlast instead of and in the condition and whether wr or wWr?
    process (clk, rstn0, wr_ter, wr_en)
    begin
      if rstn0 = '0' then
        last_d <= '0';
      elsif rising_edge (clk) then
        if last_d = '0' then
          if wr_ter = '1' and wr_en = '1' then
            last_d <= '1';
          end if;
        else
          last_d <= '0';
        end if;
      end if;
    end process;

    -- process for generation of wTerminate0     --shenm xinhao
    process (clk, rstn0)
    begin
      if rstn0 = '0' then
        wTerminate0 <= '0';
      elsif rising_edge (clk) then
        if wTerminate0 = '0' then
          if wr_ter = '1' and rIsUp2Date = '1' then --  and wr_en = '1'  then
            wTerminate0 <= '1';
          end if;
        else
          wTerminate0 <= '0';
        end if;
      end if;
    end process;

    -- process for generation of wTerminate1
    process (clk, rstn1)
    begin
      if rstn1 = '0' then
        wTerminate1 <= '0';
      elsif rising_edge (clk) then
        if wTerminate1 = '0' then
          if wr_ter = '1' and rIsUp2Date = '0' then -- and wr_en = '1' then
            wTerminate1 <= '1';
          end if;
        else
          wTerminate1 <= '0';
        end if;
      end if;
    end process;


    -- state machine for updating the toggle_pending signal
    process (reset_n, clk)
    begin
      if reset_n = '0' then
        toggle_pending <= '0';
      elsif rising_edge (clk) then
        if sWriteDone = '1' and toggle_pending = '0' then  --dangqian yijingxiewan  bingqie pending =0 daibiao haimei zhuanhuan 
          toggle_pending <= '1';
        elsif toggle_done = '1' then
          toggle_pending <= '0';
        else
          toggle_pending <= toggle_pending;
        end if;
      end if;
    end process;

    -- state machine for updating the rIsUp2Date and toggle_done signal
    process (reset_n, clk)
    begin
      if reset_n = '0' then
        toggle_done <= '1';
      elsif rising_edge (clk) then
        if toggle_pending = '1' then
          if ungoing_read = '0' AND ungoing_write = '0' then
            toggle_done <= '1'; --weidu  weixie
          else
            toggle_done <= '0';
          end if;
        else
          toggle_done <= '0';
        end if;
        if toggle_done = '1' then
          toggle_done <= '0';
        end if;
      end if;
    end process;

    process (reset_n, clk) 
    begin
      if reset_n = '0' then
        rIsUp2Date <= '1';
      elsif rising_edge (clk) then
        if toggle_done = '1' then 
          if ungoing_read = '0' AND ungoing_write = '0' then
            rIsUp2Date <= NOT rIsUp2Date;
          else
            rIsUp2Date <= rIsUp2Date;
          end if;
        else
          rIsUp2Date <= rIsUp2Date;
        end if;
      end if;
    end process;

end sig_buffer;


architecture bram_port of double_buffer is


    component BRAM_Ports is
       generic
       (
             --WordWidth         : natural := 32;
             DATA_WIDTH        : natural := 36;
             Addr_Width        : natural := 10
         );
        port
        (
           clk        : in  std_logic;
           reset    : in  std_logic;
           
           wren        : in  std_logic;
           WRADDR   : in  std_logic_vector (Addr_Width-1 downto 0); 
           DI       : in  std_logic_vector (DATA_WIDTH-1 downto 0);    
             
           rden        : in  std_logic;
           RDADDR   : in  std_logic_vector (Addr_Width-1 downto 0);
           DO       : out std_logic_vector (DATA_WIDTH-1 downto 0)
    );
    end component;
    
  constant C_MAX_NUM_ELEMENTS : unsigned (AddrWidth downto 0) := (AddrWidth => '1', others => '0');

    --type buffer_type is array(0 to (2 ** AddrWidth - 1)) of unsigned (WordWidth - 1 downto 0 ); -- TODO: is it correct to have unsigned for the buffer?

    signal  rIsUp2Date          : std_logic;
    signal  rIsUp2Date_d        : std_logic;

    --signal  buffer_inst0        : buffer_type;

    signal  wrpntr0             : unsigned (AddrWidth  downto 0) := (others => '0');
    signal  rdpntr0             : unsigned (AddrWidth  downto 0) := (others => '0');
    
    signal  wr_pointer0             : unsigned (Addr_Width-1  downto 0) := (others => '0');
    signal  rd_pointer0             : unsigned (Addr_Width-1  downto 0) := (others => '0');
    
    signal  ungoing_read0       : std_logic;
    signal  ungoing_write0      : std_logic;
    signal  rFull0              : std_logic;
    signal  rEmpty0             : std_logic;
    signal  rEmpty0_d           : std_logic;
    signal  rEmptyPulse0        : std_logic;
    signal  msglen0             : unsigned (Addr_Width-1 downto 0) := (others => '0');
    signal  rstn0               : std_logic;
    signal  wEnq0               : std_logic;
    signal  wTerminate0         : std_logic;
    signal  wDin0               : std_logic_vector (WordWidth - 1 downto 0);
    signal  rFull0_d            : std_logic;
    signal  rFullPulse0         : std_logic;
    signal  sWriteDone0         : std_logic;
    signal  wDeq0               : std_logic;
    signal  wDeqDone0           : std_logic;
    signal  wDout0              : std_logic_vector (WordWidth - 1 downto 0);

    --signal  buffer_inst1        : buffer_type;

    signal  wrpntr1             : unsigned (AddrWidth  downto 0) := (others => '0');
    signal  rdpntr1             : unsigned (AddrWidth  downto 0) := (others => '0');
    
    signal  wr_pointer1             : unsigned (Addr_Width-1  downto 0) := (others => '0');
    signal  rd_pointer1             : unsigned (Addr_Width-1  downto 0) := (others => '0');
    
    signal  ungoing_read1       : std_logic;
    signal  ungoing_write1      : std_logic;
    signal  rFull1              : std_logic;
    signal  rEmpty1             : std_logic;
    signal  rEmpty1_d           : std_logic;
    signal  rEmptyPulse1        : std_logic;
    signal  msglen1             : unsigned (Addr_Width-1 downto 0) := (others => '0');
    signal  rstn1               : std_logic;
    signal  wEnq1               : std_logic;
    signal  wTerminate1         : std_logic;
    signal  sWriteDone1         : std_logic;
    signal  wDin1               : std_logic_vector (WordWidth - 1 downto 0);
    signal  rFull1_d            : std_logic;
    signal  rFullPulse1         : std_logic;
    signal  wDeq1               : std_logic;
    signal  wDeqDone1           : std_logic;
    signal  wDout1              : std_logic_vector (WordWidth - 1 downto 0);

    signal  ungoing_read        : std_logic;
    signal  ungoing_write       : std_logic;
    signal  wDeq_connected      : std_logic;
    signal  wEnq_connected      : std_logic;
    signal  rEmpty              : std_logic;
    signal  rBEmpty             : std_logic;
    signal  rBFull              : std_logic;
    signal  wDeq                : std_logic;
    signal  wEnq                : std_logic;
    signal  toggle_done         : std_logic;
    signal  toggle_pending      : std_logic;
    signal  sWriteDone          : std_logic;
    signal  sDeqDone            : std_logic;
    signal  nqd                 : std_logic_vector (AddrWidth downto 0);
    signal  last_d              : std_logic;
    
    signal dataIN0              : std_logic_vector (DATA_WIDTH - 1 downto 0);
    signal dataOUT0             : std_logic_vector (DATA_WIDTH - 1 downto 0);
    signal dataIN1              : std_logic_vector (DATA_WIDTH - 1 downto 0);
    signal dataOUT1             : std_logic_vector (DATA_WIDTH - 1 downto 0);
    
    signal write_ADD0             :std_logic_vector (Addr_Width-1 downto 0) := (others => '0');
    signal write_ADD1             :std_logic_vector(Addr_Width-1 downto 0);
    signal swrite_ADD             :std_logic_vector (4 downto 0);
    signal read_ADD0             :std_logic_vector (Addr_Width-1 downto 0);
    signal read_ADD1             :std_logic_vector (Addr_Width-1 downto 0);
    signal sread_ADD             :std_logic_vector (4 downto 0);
    signal wadd                  : std_logic_vector (4 downto 0);
    signal DOutNoChange          : std_logic;
    

  begin
  
    --wadd <= wr_addr;
    empty <= rEmpty;
    bEmpty <= rBEmpty;
    bFull <= rBFull;
    full <= '0';
    wDin0 <= wr_data;
    wDin1 <= wr_data;
    wEnq <= wr_en AND wEnq_connected;
        
    wDeq <= rd_en when rEmpty /= '1' AND wDeq_connected = '1' else '0'; --  AND wDeq_connected;

    ungoing_read <= ungoing_read0 OR ungoing_read1;
    ungoing_write <= ungoing_write0 OR ungoing_write1;

    sWriteDone0 <= wTerminate0; -- OR rFullPulse0;
    sWriteDone1 <= wTerminate1; -- OR rFullPulse1;
    sWriteDone <= sWriteDone0 when rIsUp2Date = '1' else sWriteDone1;
    sDeqDone <= wDeqDone1 when rIsUp2Date = '1' else wDeqDone0;
    msglen <= std_logic_vector (msglen1) when rIsUp2Date = '1' else std_logic_vector (msglen0);
    --state machine for connecting the signals to the buffer instants
    rd_data <= wDout1 when rIsUp2Date = '1'  else wDout0;
    wDeq1 <= wDeq when rIsUp2Date = '1' else '0';
    wDeq0 <= wDeq when rIsUp2Date = '0' else '0';
    rBFull <= rFull0  when rIsUp2Date = '1' else rFull1;
    rBEmpty <= rEmpty1  when rIsUp2Date = '1' else rEmpty0;
    rEmpty <= rEmpty1 when rIsUp2Date = '1' else rEmpty0;

    wEnq0 <= wEnq when rIsUp2Date = '1' else '0';
    wEnq1 <= wEnq when rIsUp2Date = '0' else '0';

    rEmpty0 <= '1' when msglen0 = 0 else '0';

    rFullPulse0 <= rFull0 and not rFull0_d;
    rFull0  <= '1' when msglen0 = C_MAX_NUM_ELEMENTS else '0';
    
    msglen0 <= wr_pointer0 - rd_pointer0;
    rFull1  <= '1' when msglen1 = C_MAX_NUM_ELEMENTS else '0';
    msglen1 <= wr_pointer1 - rd_pointer1;
    rFullPulse1 <= rFull1 and not rFull1_d;
    rEmpty1 <= '1' when msglen1 = 0 else '0';
    rEmptyPulse0 <= rEmpty0 and not rEmpty0_d;
    rEmptyPulse1 <= rEmpty1 and not rEmpty1_d;


    -- process for controlling the wEnq_connected
    -- it will be connected if the buffer is not full and the wr_en is not assserted
    -- TODO: should I replace last_d with sWriteDone??
    process (reset_n,clk)
    begin
      if reset_n = '0' then
        wEnq_connected <= '1';
      elsif rising_edge (clk) then
        if wr_en = '0' then
          if toggle_pending = '1' then  -- 
            wEnq_connected <= '0';
          else
            wEnq_connected <= '1';
          end if;
        end if;
      end if;
    end process;
    
    -- process for controlling the DOutNoChange
    -- it will control the rd_data in order not to change between two successive wDeq signals
    process (clk,wDeq)
    begin
        if reset_n = '0' then
            DOutNoChange <= '0';
        elsif rising_edge (clk) then
            if wDeq = '1' then
                DOutNoChange <= '1';
            else
                DOutNoChange <= '0';     
            end if;    
        end if;
    end process;


    --TODO: wdeq_connected shall be completed.
--     process for connecting the rden to the wDeq: wDeq_connected
--     it will be connected if the port is not empty and the rden is not assserted
     process (reset_n,clk, rd_en, sDeqDone, rBEmpty)
     begin
       if reset_n = '0' then
         wDeq_connected <= '0';
       elsif rising_edge (clk) then
         if wDeq_connected = '0' then
           if rd_en /= '1' AND rBEmpty /= '1' then
             wDeq_connected <= '1';
           else
             wDeq_connected <= '0';
           end if;
         elsif sDeqDone = '1' then
           wDeq_connected <= '0';
         else
           wDeq_connected <= '1';
         end if;
       end if;
     end process;

    -- process for generation of wDeqDone0
    process (rstn0, clk)
    begin
      if rstn0 = '0' then
        wDeqDone0 <= '0';
      elsif rising_edge (clk) then
        wDeqDone0 <= rEmptyPulse0;
      end if;
    end process;


    -- process for generation of wDeqDone1
    process (rstn1, clk)
    begin
      if rstn1 = '0' then
        wDeqDone1 <= '0';
      elsif rising_edge (clk) then
        wDeqDone1 <= rEmptyPulse1;
      end if;
    end process;

    -- process for generation of ungoing_write0
    process (rstn0,clk)
    begin
      if rstn0 = '0' then
        ungoing_write0 <= '0';
      elsif rising_edge (clk) then
        if wEnq0 = '1' and ungoing_write0 = '0' then
          ungoing_write0 <= '1';
        elsif sWriteDone0 = '1' and ungoing_write0 = '1' then
          ungoing_write0 <= '0';
        else
          ungoing_write0 <= ungoing_write0;
        end if;
      end if;
    end process;

    -- process for generation of ungoing_write1
    process (rstn1,clk)
    begin
      if rstn1 = '0' then
        ungoing_write1 <= '0';
      elsif rising_edge (clk) then
        if wEnq1 = '1' and ungoing_write1 = '0' then
          ungoing_write1 <= '1';
        elsif sWriteDone1 = '1' and ungoing_write1 = '1' then
          ungoing_write1 <= '0';
        else
          ungoing_write1 <= ungoing_write1;
        end if;
      end if;
    end process;

    -- process for generation of ungoing_read0
    process (rstn0,clk)
    begin
      if rstn0 = '0' then
        ungoing_read0 <= '0';
      elsif rising_edge (clk) then
        if wDeq0 = '1' and ungoing_read0 = '0' then
          ungoing_read0 <= '1';
        elsif wDeqDone0 = '1' and ungoing_read0 = '1' then
          ungoing_read0 <= '0';
        else
          ungoing_read0 <= ungoing_read0;
        end if;
      end if;
    end process;

    -- process for generation of ungoing_read1
    process (rstn1,clk)
    begin
      if rstn1 = '0' then
        ungoing_read1 <= '0';
      elsif rising_edge (clk) then
        if wDeq1 = '1' and ungoing_read1 = '0' then
          ungoing_read1 <= '1';
        elsif wDeqDone1 = '1' and ungoing_read1 = '1' then
          ungoing_read1 <= '0';
        else
          ungoing_read1 <= ungoing_read1;
        end if;
      end if;
    end process;

    -- process for generation of the rEmpty
    -- this is empty only if there is no state data in both buffers.
    -- process (reset_n,clk)
    -- begin
    --   if reset_n = '0' then
    --     rEmpty <= '1';
    --   elsif rising_edge (clk) then
    --     if rEmpty = '1' and rIsUp2Date = '0' then
    --       rEmpty <= '0';
    --     else
    --       rEmpty <= '1';
    --     end if;
    --   end if;
    -- end process;


    -- process for generation of rstn0 and rstn1
    process (reset_n,clk)
    begin
      if reset_n = '0' then
        rstn0 <= '0';
        rstn1 <= '0';
      elsif rising_edge (clk) then
        if toggle_done = '1' and rIsUp2Date_d = '1' then
          rstn1 <= '0';
        elsif toggle_done = '1' and rIsUp2Date_d = '0' then
          rstn0 <= '0';
        else
          rstn0 <= '1';
          rstn1 <= '1';
        end if;
      end if;
    end process;

    -- process for buffer_inst1
    process (clk,rstn0)
    begin
      if rstn0 = '0' then
        wr_pointer0 <= (others => '0');
        rd_pointer0 <= (others => '0');
      elsif rising_edge (clk) then
        if (wEnq0 = '1' AND rFull0 = '0') then
          if wr_addr_en = '1' then 
			 -- buffer_inst0 (to_integer (unsigned (wr_addr))) <= unsigned(wDin0);
			 wr_pointer0 (AddrWidth - 1 downto 0) <= unsigned (wr_addr); 
		  else 
			 -- buffer_inst0 (to_integer (wrpntr0 (AddrWidth - 1 downto 0))) <= unsigned(wDin0);
			  wr_pointer0 <= wr_pointer0 + 1;
--			  if (to_integer(unsigned(wr_pointer0)) = 16) then
--			  wr_pointer0 <= (others => '0');
--			  end if;
		  end if; 
        end if;
        if (wDeq0 = '1' AND rEmpty0 = '0') then
			if rd_addr_en = '1' then 
	         -- wDout0 <= std_logic_vector (buffer_inst0 (to_integer(unsigned (rd_addr))));
	          rd_pointer0 (AddrWidth - 1 downto 0) <= unsigned (rd_addr); 

	        else
	         -- wDout0 <= std_logic_vector (buffer_inst0 (to_integer(rdpntr0 (AddrWidth - 1 downto 0))));
		      rd_pointer0 <= rd_pointer0 + 1;
	        end if; 
        end if;
      end if;
    end process;


    -- process for buffer_inst1
    process (clk,rstn1)
    begin
      if rstn1 = '0' then
        wr_pointer1 <= (others => '0');
        rd_pointer1 <= (others => '0');
      elsif rising_edge (clk) then
        if (wEnq1 = '1' AND rFull1 = '0') then
			if wr_addr_en = '1' then 
			 -- buffer_inst1 (to_integer (unsigned (wr_addr))) <= unsigned(wDin1);
			 wr_pointer1 (AddrWidth - 1 downto 0) <= unsigned (wr_addr);
			else 
			 -- buffer_inst1 (to_integer (wrpntr1 (AddrWidth - 1 downto 0))) <= unsigned(wDin1);
			  wr_pointer1 <= wr_pointer1 + 1;
--			  if (to_integer(unsigned(wr_pointer0)) = 16) then
--              wr_pointer0 <= (others => '0');
--              end if;
			end if; 
        end if;
        if (wDeq1 = '1' AND rEmpty1 = '0') then
			if rd_addr_en = '1' then 
			 -- wDout1 <= std_logic_vector (buffer_inst1 (to_integer(unsigned (rd_addr))));
			 rd_pointer1 (AddrWidth - 1 downto 0) <= unsigned (rd_addr);
	        else
			 -- wDout1 <= std_logic_vector (buffer_inst1 (to_integer(rdpntr1 (AddrWidth - 1 downto 0))));
			  rd_pointer1 <= rd_pointer1 + 1;
			end if; 
        end if;
      end if;
    end process;


    process (clk)
    begin
      if reset_n = '0' then
        rIsUp2Date_d <= '1';
        rFull0_d <= '0';
        rFull1_d <= '0';
        rEmpty0_d <= '0';
        rEmpty1_d <= '0';
      elsif rising_edge (clk) then
        rEmpty0_d <= rEmpty0;
        rEmpty1_d <= rEmpty1;
        rFull0_d <= rFull0;
        rFull1_d <= rFull1;
        rIsUp2Date_d <= rIsUp2Date;
      end if;
  	end process;

    -- process for generation of last_d
    -- TODO: using wlast instead of and in the condition and whether wr or wWr?
    process (clk, rstn0, wr_ter, wr_en)
    begin
      if rstn0 = '0' then
        last_d <= '0';
      elsif rising_edge (clk) then
        if last_d = '0' then
          if wr_ter = '1' and wr_en = '1' then
            last_d <= '1';
          end if;
        else
          last_d <= '0';
        end if;
      end if;
    end process;

    -- process for generation of wTerminate0
    process (clk, rstn0)
    begin
      if rstn0 = '0' then
        wTerminate0 <= '0';
      elsif rising_edge (clk) then
        if wTerminate0 = '0' then
          if wr_ter = '1' and rIsUp2Date = '1' then --  and wr_en = '1'  then
            wTerminate0 <= '1';
          end if;
        else
          wTerminate0 <= '0';
        end if;
      end if;
    end process;

    -- process for generation of wTerminate1
    process (clk, rstn1)
    begin
      if rstn1 = '0' then
        wTerminate1 <= '0';
      elsif rising_edge (clk) then
        if wTerminate1 = '0' then
          if wr_ter = '1' and rIsUp2Date = '0' then -- and wr_en = '1' then
            wTerminate1 <= '1';
          end if;
        else
          wTerminate1 <= '0';
        end if;
      end if;
    end process;


    -- state machine for updating the toggle_pending signal
    process (reset_n, clk)
    begin
      if reset_n = '0' then
        toggle_pending <= '0';
      elsif rising_edge (clk) then
        if sWriteDone = '1' and toggle_pending = '0' then
          toggle_pending <= '1';
        elsif toggle_done = '1' then
          toggle_pending <= '0';
        else
          toggle_pending <= toggle_pending;
        end if;
      end if;
    end process;

    -- state machine for updating the rIsUp2Date and toggle_done signal
    process (reset_n, clk)
    begin
      if reset_n = '0' then
        toggle_done <= '1';
      elsif rising_edge (clk) then
        if toggle_pending = '1' then
          if ungoing_read = '0' AND ungoing_write = '0' then
            toggle_done <= '1';
          else
            toggle_done <= '0';
          end if;
        else
          toggle_done <= '0';
        end if;
        if toggle_done = '1' then
          toggle_done <= '0';
        end if;
      end if;
    end process;


    process (reset_n, clk)
    begin
      if reset_n = '0' then
        rIsUp2Date <= '1';
      elsif rising_edge (clk) then
        if toggle_done = '1' then
          if ungoing_read = '0' AND ungoing_write = '0' then
            rIsUp2Date <= NOT rIsUp2Date;
          else
            rIsUp2Date <= rIsUp2Date;
          end if;
        else
          rIsUp2Date <= rIsUp2Date;
        end if;
      end if;
    end process;
    
    State_BRAM0: BRAM_Ports 
    port map
    (
        clk   => clk,
        reset  => reset_n,
               
        wren    => wEnq0,
        WRADDR  => write_ADD0, 
        DI      => dataIN0,    
                 
        rden     => wDeq0,
        RDADDR   => read_ADD0,
        DO       => dataOUT0
    );
    
    
    dataIN0 <= b"0000" & wDin0;
    wDout0 <= dataOUT0 (31 downto 0);
    
     State_BRAM1: BRAM_Ports 
     port map
     (
        clk   => clk,
        reset  => reset_n,
                  
        wren   => wEnq1,
        WRADDR  => write_ADD1,
        DI       => dataIN1,   
                    
        rden      => wDeq1,
        RDADDR   => read_ADD1,
        DO       => dataOUT1
     );
     
    dataIN1 <= b"0000" & wDin1;
    wDout1 <= dataOUT1 (31 downto 0);
    
    write_ADD0  <= std_logic_vector(unsigned(wr_pointer0));
    write_ADD1 <= std_logic_vector(unsigned(wr_pointer1));  
    read_ADD0 <= std_logic_vector(unsigned(rd_pointer0));
    read_ADD1 <= std_logic_vector(unsigned(rd_pointer1));
    
end bram_port;


--------------------------------------------------------------------------------------------------------
---- Project		: SAFEPOWER
---- Module       : DoubleBuffer
---- File			: double_buffer.vhd
---- Author		: Hamidreza Ahmadian
---- created		: September, 17th 2015
---- last mod. by	: Hamidreza Ahmadian
---- last mod. by	: Yosab Bebawy
---- last mod. on	: June, 2nd 2017
---- contents		: architecture of a double buffer for state ports
--------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------
---- library includes
--------------------------------------------------------------------------------------------------------

--library IEEE;
--use IEEE.std_logic_1164.all;
--use IEEE.NUMERIC_STD.ALL;


--entity double_buffer is
--  generic (
--		AddrWidth				: natural:= 4;
--		Addr_Width             : natural := 10;
--		WordWidth				: natural:= 32;
--	    DATA_WIDTH             : natural := 36
--	);
--	port (
--        wr_en					: in std_logic;
--        wr_ter					: in std_logic;
--	wr_addr_en				: in std_logic; 
--        wr_addr					: in std_logic_vector (AddrWidth- 1 downto 0); 
--        wr_data					: in std_logic_vector(WordWidth-1 downto 0);
--        rd_en					: in std_logic;
--	rd_addr_en				: in std_logic; 
--        rd_addr					: in std_logic_vector (AddrWidth - 1 downto 0); 
--        rd_data		 			: out std_logic_vector(WordWidth-1 downto 0);
--        msglen          		: out std_logic_vector (AddrWidth downto 0);
--        bFull           		: out std_logic;
--        full            		: out std_logic;
--        bEmpty          		: out std_logic;
--        empty           		: out std_logic;
--        reset_n         		: in std_logic;
--        clk 					: in std_logic
--	);
--end double_buffer;

--architecture safepower of double_buffer is


--    component BRAM_Ports is
--       generic
--       (
--             --WordWidth         : natural := 32;
--             DATA_WIDTH        : natural := 36;
--             Addr_Width        : natural := 10
--         );
--        port
--        (
--           clk        : in  std_logic;
--           reset    : in  std_logic;
           
--           wren        : in  std_logic;
--           WRADDR   : in  std_logic_vector (Addr_Width-1 downto 0); 
--           DI       : in  std_logic_vector (DATA_WIDTH-1 downto 0);    
             
--           rden        : in  std_logic;
--           RDADDR   : in  std_logic_vector (Addr_Width-1 downto 0);
--           DO       : out std_logic_vector (DATA_WIDTH-1 downto 0)
--    );
--    end component;
    
--  constant C_MAX_NUM_ELEMENTS : unsigned (AddrWidth downto 0) := (AddrWidth => '1', others => '0');

--    --type buffer_type is array(0 to (2 ** AddrWidth - 1)) of unsigned (WordWidth - 1 downto 0 ); -- TODO: is it correct to have unsigned for the buffer?

--    signal  rIsUp2Date          : std_logic;
--    signal  rIsUp2Date_d        : std_logic;

--    --signal  buffer_inst0        : buffer_type;

--    signal  wrpntr0             : unsigned (AddrWidth  downto 0) := (others => '0');
--    signal  rdpntr0             : unsigned (AddrWidth  downto 0) := (others => '0');
    
--    signal  wr_pointer0             : unsigned (Addr_Width-1  downto 0) := (others => '0');
--    signal  rd_pointer0             : unsigned (Addr_Width-1  downto 0) := (others => '0');
    
--    signal  ungoing_read0       : std_logic;
--    signal  ungoing_write0      : std_logic;
--    signal  rFull0              : std_logic;
--    signal  rEmpty0             : std_logic;
--    signal  rEmpty0_d           : std_logic;
--    signal  rEmptyPulse0        : std_logic;
--    signal  msglen0             : unsigned (AddrWidth downto 0) := (others => '0');
--    signal  rstn0               : std_logic;
--    signal  wEnq0               : std_logic;
--    signal  wTerminate0         : std_logic;
--    signal  wDin0               : std_logic_vector (WordWidth - 1 downto 0);
--    signal  rFull0_d            : std_logic;
--    signal  rFullPulse0         : std_logic;
--    signal  sWriteDone0         : std_logic;
--    signal  wDeq0               : std_logic;
--    signal  wDeqDone0           : std_logic;
--    signal  wDout0              : std_logic_vector (WordWidth - 1 downto 0);

--    --signal  buffer_inst1        : buffer_type;

--    signal  wrpntr1             : unsigned (AddrWidth  downto 0) := (others => '0');
--    signal  rdpntr1             : unsigned (AddrWidth  downto 0) := (others => '0');
    
--    signal  wr_pointer1             : unsigned (Addr_Width-1  downto 0) := (others => '0');
--    signal  rd_pointer1             : unsigned (Addr_Width-1  downto 0) := (others => '0');
    
--    signal  ungoing_read1       : std_logic;
--    signal  ungoing_write1      : std_logic;
--    signal  rFull1              : std_logic;
--    signal  rEmpty1             : std_logic;
--    signal  rEmpty1_d           : std_logic;
--    signal  rEmptyPulse1        : std_logic;
--    signal  msglen1             : unsigned (AddrWidth downto 0) := (others => '0');
--    signal  rstn1               : std_logic;
--    signal  wEnq1               : std_logic;
--    signal  wTerminate1         : std_logic;
--    signal  sWriteDone1         : std_logic;
--    signal  wDin1               : std_logic_vector (WordWidth - 1 downto 0);
--    signal  rFull1_d            : std_logic;
--    signal  rFullPulse1         : std_logic;
--    signal  wDeq1               : std_logic;
--    signal  wDeqDone1           : std_logic;
--    signal  wDout1              : std_logic_vector (WordWidth - 1 downto 0);

--    signal  ungoing_read        : std_logic;
--    signal  ungoing_write       : std_logic;
--    signal  wDeq_connected      : std_logic;
--    signal  wEnq_connected      : std_logic;
--    signal  rEmpty              : std_logic;
--    signal  rBEmpty             : std_logic;
--    signal  rBFull              : std_logic;
--    signal  wDeq                : std_logic;
--    signal  wEnq                : std_logic;
--    signal  toggle_done         : std_logic;
--    signal  toggle_pending      : std_logic;
--    signal  sWriteDone          : std_logic;
--    signal  sDeqDone            : std_logic;
--    signal  nqd                 : std_logic_vector (AddrWidth downto 0);
--    signal  last_d              : std_logic;
    
--    signal dataIN0              : std_logic_vector (DATA_WIDTH - 1 downto 0);
--    signal dataOUT0             : std_logic_vector (DATA_WIDTH - 1 downto 0) := (others => '0');
--    signal dataIN1              : std_logic_vector (DATA_WIDTH - 1 downto 0);
--    signal dataOUT1             : std_logic_vector (DATA_WIDTH - 1 downto 0) := (others => '0');
    
--    signal write_ADD0             :std_logic_vector (Addr_Width-1 downto 0) := (others => '0');
--    signal write_ADD1             :std_logic_vector(Addr_Width-1 downto 0);
--    signal swrite_ADD             :std_logic_vector (4 downto 0);
--    signal read_ADD0             :std_logic_vector (Addr_Width-1 downto 0);
--    signal read_ADD1             :std_logic_vector (Addr_Width-1 downto 0);
--    signal sread_ADD             :std_logic_vector (4 downto 0);
--    signal wadd                  : std_logic_vector (4 downto 0);
--    signal DOutNoChange          : std_logic;
    

--  begin
  
--    --wadd <= wr_addr;
--    empty <= rEmpty;
--    bEmpty <= rBEmpty;
--    bFull <= rBFull;
--    full <= '0';
--    wDin0 <= wr_data;
--    wDin1 <= wr_data;
--    wEnq <= wr_en AND wEnq_connected;
--    wDeq <= rd_en when rEmpty /= '1' AND wDeq_connected = '1' else '0'; --  AND wDeq_connected;

--    ungoing_read <= ungoing_read0 OR ungoing_read1;
--    ungoing_write <= ungoing_write0 OR ungoing_write1;

--    sWriteDone0 <= wTerminate0; -- OR rFullPulse0;
--    sWriteDone1 <= wTerminate1; -- OR rFullPulse1;
--    sWriteDone <= sWriteDone0 when rIsUp2Date = '1' else sWriteDone1;
--    sDeqDone <= wDeqDone1 when rIsUp2Date = '1' else wDeqDone0;
--    msglen <= std_logic_vector (msglen1) when rIsUp2Date = '1' else std_logic_vector (msglen0);
--    --state machine for connecting the signals to the buffer instants
--    rd_data <= wDout1 when rIsUp2Date = '1'  else wDout0;
--    wDeq1 <= wDeq when rIsUp2Date = '1' else '0';
--    wDeq0 <= wDeq when rIsUp2Date = '0' else '0';
--    rBFull <= rFull0  when rIsUp2Date = '1' else rFull1;
--    rBEmpty <= rEmpty1  when rIsUp2Date = '1' else rEmpty0;
--    rEmpty <= rEmpty1 when rIsUp2Date = '1' else rEmpty0;

--    wEnq0 <= wEnq when rIsUp2Date = '1' else '0';
--    wEnq1 <= wEnq when rIsUp2Date = '0' else '0';

--    rEmpty0 <= '1' when msglen0 = 0 else '0';

--    rFullPulse0 <= rFull0 and not rFull0_d;
--    rFull0  <= '1' when msglen0 = C_MAX_NUM_ELEMENTS else '0';
    
--    msglen0 <= wr_pointer0(AddrWidth downto 0)- rd_pointer0(AddrWidth downto 0);
--    rFull1  <= '1' when msglen1 = C_MAX_NUM_ELEMENTS else '0';
--    msglen1 <= wr_pointer1 (AddrWidth downto 0) - rd_pointer1(AddrWidth downto 0);
--    rFullPulse1 <= rFull1 and not rFull1_d;
--    rEmpty1 <= '1' when msglen1 = 0 else '0';
--    rEmptyPulse0 <= rEmpty0 and not rEmpty0_d;
--    rEmptyPulse1 <= rEmpty1 and not rEmpty1_d;


--    -- process for controlling the wEnq_connected
--    -- it will be connected if the buffer is not full and the wr_en is not assserted
--    -- TODO: should I replace last_d with sWriteDone??
--    process (reset_n,clk)
--    begin
--      if reset_n = '0' then
--        wEnq_connected <= '1';
--      elsif rising_edge (clk) then
--        if wr_en = '0' then
--          if toggle_pending = '1' then
--            wEnq_connected <= '0';
--          else
--            wEnq_connected <= '1';
--          end if;
--        end if;
--      end if;
--    end process;
    
--    -- process for controlling the DOutNoChange
--    -- it will control the rd_data in order not to change between two successive wDeq signals
--    process (clk,wDeq)
--    begin
--        if reset_n = '0' then
--            DOutNoChange <= '0';
--        elsif rising_edge (clk) then
--            if wDeq = '1' then
--                DOutNoChange <= '1';
--            else
--                DOutNoChange <= '0';     
--            end if;    
--        end if;
--    end process;


--    --TODO: wdeq_connected shall be completed.
----     process for connecting the rden to the wDeq: wDeq_connected
----     it will be connected if the port is not empty and the rden is not assserted
--     process (reset_n,clk, rd_en, sDeqDone, rBEmpty)
--     begin
--       if reset_n = '0' then
--         wDeq_connected <= '0';
--       elsif rising_edge (clk) then
--         if wDeq_connected = '0' then
--           if rd_en /= '1' AND rBEmpty /= '1' then
--             wDeq_connected <= '1';
--           else
--             wDeq_connected <= '0';
--           end if;
--         elsif sDeqDone = '1' then
--           wDeq_connected <= '0';
--         else
--           wDeq_connected <= '1';
--         end if;
--       end if;
--     end process;

--    -- process for generation of wDeqDone0
--    process (rstn0, clk)
--    begin
--      if rstn0 = '0' then
--        wDeqDone0 <= '0';
--      elsif rising_edge (clk) then
--        wDeqDone0 <= rEmptyPulse0;
--      end if;
--    end process;


--    -- process for generation of wDeqDone1
--    process (rstn1, clk)
--    begin
--      if rstn1 = '0' then
--        wDeqDone1 <= '0';
--      elsif rising_edge (clk) then
--        wDeqDone1 <= rEmptyPulse1;
--      end if;
--    end process;

--    -- process for generation of ungoing_write0
--    process (rstn0,clk)
--    begin
--      if rstn0 = '0' then
--        ungoing_write0 <= '0';
--      elsif rising_edge (clk) then
--        if wEnq0 = '1' and ungoing_write0 = '0' then
--          ungoing_write0 <= '1';
--        elsif sWriteDone0 = '1' and ungoing_write0 = '1' then
--          ungoing_write0 <= '0';
--        else
--          ungoing_write0 <= ungoing_write0;
--        end if;
--      end if;
--    end process;

--    -- process for generation of ungoing_write1
--    process (rstn1,clk)
--    begin
--      if rstn1 = '0' then
--        ungoing_write1 <= '0';
--      elsif rising_edge (clk) then
--        if wEnq1 = '1' and ungoing_write1 = '0' then
--          ungoing_write1 <= '1';
--        elsif sWriteDone1 = '1' and ungoing_write1 = '1' then
--          ungoing_write1 <= '0';
--        else
--          ungoing_write1 <= ungoing_write1;
--        end if;
--      end if;
--    end process;

--    -- process for generation of ungoing_read0
--    process (rstn0,clk)
--    begin
--      if rstn0 = '0' then
--        ungoing_read0 <= '0';
--      elsif rising_edge (clk) then
--        if wDeq0 = '1' and ungoing_read0 = '0' then
--          ungoing_read0 <= '1';
--        elsif wDeqDone0 = '1' and ungoing_read0 = '1' then
--          ungoing_read0 <= '0';
--        else
--          ungoing_read0 <= ungoing_read0;
--        end if;
--      end if;
--    end process;

--    -- process for generation of ungoing_read1
--    process (rstn1,clk)
--    begin
--      if rstn1 = '0' then
--        ungoing_read1 <= '0';
--      elsif rising_edge (clk) then
--        if wDeq1 = '1' and ungoing_read1 = '0' then
--          ungoing_read1 <= '1';
--        elsif wDeqDone1 = '1' and ungoing_read1 = '1' then
--          ungoing_read1 <= '0';
--        else
--          ungoing_read1 <= ungoing_read1;
--        end if;
--      end if;
--    end process;

--    -- process for generation of the rEmpty
--    -- this is empty only if there is no state data in both buffers.
--    -- process (reset_n,clk)
--    -- begin
--    --   if reset_n = '0' then
--    --     rEmpty <= '1';
--    --   elsif rising_edge (clk) then
--    --     if rEmpty = '1' and rIsUp2Date = '0' then
--    --       rEmpty <= '0';
--    --     else
--    --       rEmpty <= '1';
--    --     end if;
--    --   end if;
--    -- end process;


--    -- process for generation of rstn0 and rstn1
--    process (reset_n,clk)
--    begin
--      if reset_n = '0' then
--        rstn0 <= '0';
--        rstn1 <= '0';
--      elsif rising_edge (clk) then
--        if toggle_done = '1' and rIsUp2Date_d = '1' then
--          rstn1 <= '0';
--        elsif toggle_done = '1' and rIsUp2Date_d = '0' then
--          rstn0 <= '0';
--        else
--          rstn0 <= '1';
--          rstn1 <= '1';
--        end if;
--      end if;
--    end process;

--    -- process for buffer_inst1
--    process (clk,rstn0)
--    begin
--      if rstn0 = '0' then
--        wr_pointer0 <= (others => '0');
--        rd_pointer0 <= (others => '0');
--      elsif rising_edge (clk) then
--        if (wEnq0 = '1' AND rFull0 = '0') then
--          if wr_addr_en = '1' then 
--			 -- buffer_inst0 (to_integer (unsigned (wr_addr))) <= unsigned(wDin0);
--			 wr_pointer0 (AddrWidth - 1 downto 0) <= unsigned (wr_addr); 
--		  else 
--			 -- buffer_inst0 (to_integer (wrpntr0 (AddrWidth - 1 downto 0))) <= unsigned(wDin0);
--			  wr_pointer0 <= wr_pointer0 + 1;
----			  if (to_integer(unsigned(wr_pointer0)) = 16) then
----			  wr_pointer0 <= (others => '0');
----			  end if;
--		  end if; 
--        end if;
--        if (wDeq0 = '1' AND rEmpty0 = '0') then
--			if rd_addr_en = '1' then 
--	         -- wDout0 <= std_logic_vector (buffer_inst0 (to_integer(unsigned (rd_addr))));
--	          rd_pointer0 (AddrWidth - 1 downto 0) <= unsigned (rd_addr); 

--	        else
--	         -- wDout0 <= std_logic_vector (buffer_inst0 (to_integer(rdpntr0 (AddrWidth - 1 downto 0))));
--		      rd_pointer0 <= rd_pointer0 + 1;
--	        end if; 
--        end if;
--      end if;
--    end process;


--    -- process for buffer_inst1
--    process (clk,rstn1)
--    begin
--      if rstn1 = '0' then
--        wr_pointer1 <= (others => '0');
--        rd_pointer1 <= (others => '0');
--      elsif rising_edge (clk) then
--        if (wEnq1 = '1' AND rFull1 = '0') then
--			if wr_addr_en = '1' then 
--			 -- buffer_inst1 (to_integer (unsigned (wr_addr))) <= unsigned(wDin1);
--			 wr_pointer1 (AddrWidth - 1 downto 0) <= unsigned (wr_addr);
--			else 
--			 -- buffer_inst1 (to_integer (wrpntr1 (AddrWidth - 1 downto 0))) <= unsigned(wDin1);
--			  wr_pointer1 <= wr_pointer1 + 1;
----			  if (to_integer(unsigned(wr_pointer0)) = 16) then
----              wr_pointer0 <= (others => '0');
----              end if;
--			end if; 
--        end if;
--        if (wDeq1 = '1' AND rEmpty1 = '0') then
--			if rd_addr_en = '1' then 
--			 -- wDout1 <= std_logic_vector (buffer_inst1 (to_integer(unsigned (rd_addr))));
--			 rd_pointer1 (AddrWidth - 1 downto 0) <= unsigned (rd_addr);
--	        else
--			 -- wDout1 <= std_logic_vector (buffer_inst1 (to_integer(rdpntr1 (AddrWidth - 1 downto 0))));
--			  rd_pointer1 <= rd_pointer1 + 1;
--			end if; 
--        end if;
--      end if;
--    end process;


--    process (clk)
--    begin
--      if reset_n = '0' then
--        rIsUp2Date_d <= '1';
--        rFull0_d <= '0';
--        rFull1_d <= '0';
--        rEmpty0_d <= '0';
--        rEmpty1_d <= '0';
--      elsif rising_edge (clk) then
--        rEmpty0_d <= rEmpty0;
--        rEmpty1_d <= rEmpty1;
--        rFull0_d <= rFull0;
--        rFull1_d <= rFull1;
--        rIsUp2Date_d <= rIsUp2Date;
--      end if;
--  	end process;

--    -- process for generation of last_d
--    -- TODO: using wlast instead of and in the condition and whether wr or wWr?
--    process (clk, rstn0, wr_ter, wr_en)
--    begin
--      if rstn0 = '0' then
--        last_d <= '0';
--      elsif rising_edge (clk) then
--        if last_d = '0' then
--          if wr_ter = '1' and wr_en = '1' then
--            last_d <= '1';
--          end if;
--        else
--          last_d <= '0';
--        end if;
--      end if;
--    end process;

--    -- process for generation of wTerminate0
--    process (clk, rstn0)
--    begin
--      if rstn0 = '0' then
--        wTerminate0 <= '0';
--      elsif rising_edge (clk) then
--        if wTerminate0 = '0' then
--          if wr_ter = '1' and rIsUp2Date = '1' then --  and wr_en = '1'  then
--            wTerminate0 <= '1';
--          end if;
--        else
--          wTerminate0 <= '0';
--        end if;
--      end if;
--    end process;

--    -- process for generation of wTerminate1
--    process (clk, rstn1)
--    begin
--      if rstn1 = '0' then
--        wTerminate1 <= '0';
--      elsif rising_edge (clk) then
--        if wTerminate1 = '0' then
--          if wr_ter = '1' and rIsUp2Date = '0' then -- and wr_en = '1' then
--            wTerminate1 <= '1';
--          end if;
--        else
--          wTerminate1 <= '0';
--        end if;
--      end if;
--    end process;


--    -- state machine for updating the toggle_pending signal
--    process (reset_n, clk)
--    begin
--      if reset_n = '0' then
--        toggle_pending <= '0';
--      elsif rising_edge (clk) then
--        if sWriteDone = '1' and toggle_pending = '0' then
--          toggle_pending <= '1';
--        elsif toggle_done = '1' then
--          toggle_pending <= '0';
--        else
--          toggle_pending <= toggle_pending;
--        end if;
--      end if;
--    end process;

--    -- state machine for updating the rIsUp2Date and toggle_done signal
--    process (reset_n, clk)
--    begin
--      if reset_n = '0' then
--        toggle_done <= '1';
--      elsif rising_edge (clk) then
--        if toggle_pending = '1' then
--          if ungoing_read = '0' AND ungoing_write = '0' then
--            toggle_done <= '1';
--          else
--            toggle_done <= '0';
--          end if;
--        else
--          toggle_done <= '0';
--        end if;
--        if toggle_done = '1' then
--          toggle_done <= '0';
--        end if;
--      end if;
--    end process;


--    process (reset_n, clk)
--    begin
--      if reset_n = '0' then
--        rIsUp2Date <= '1';
--      elsif rising_edge (clk) then
--        if toggle_done = '1' then
--          if ungoing_read = '0' AND ungoing_write = '0' then
--            rIsUp2Date <= NOT rIsUp2Date;
--          else
--            rIsUp2Date <= rIsUp2Date;
--          end if;
--        else
--          rIsUp2Date <= rIsUp2Date;
--        end if;
--      end if;
--    end process;
    
--    State_BRAM0: BRAM_Ports 
--    port map
--    (
--        clk   => clk,
--        reset  => reset_n,
               
--        wren    => wEnq0,
--        WRADDR  => write_ADD0, 
--        DI      => dataIN0,    
                 
--        rden     => wDeq0,
--        RDADDR   => read_ADD0,
--        DO       => dataOUT0
--    );
    
    
--    dataIN0 <= b"0000" & wDin0;
--    wDout0 <= dataOUT0 (31 downto 0);
    
--     State_BRAM1: BRAM_Ports 
--     port map
--     (
--        clk   => clk,
--        reset  => reset_n,
                  
--        wren   => wEnq1,
--        WRADDR  => write_ADD1,
--        DI       => dataIN1,   
                    
--        rden      => wDeq1,
--        RDADDR   => read_ADD1,
--        DO       => dataOUT1
--     );
     
--    dataIN1 <= b"0000" & wDin1;
--    wDout1 <= dataOUT1 (31 downto 0);
    
--    write_ADD0  <= std_logic_vector(unsigned(wr_pointer0));
--    write_ADD1 <= std_logic_vector(unsigned(wr_pointer1));  
--    read_ADD0 <= std_logic_vector(unsigned(rd_pointer0));
--    read_ADD1 <= std_logic_vector(unsigned(rd_pointer1));
    
--end safepower;