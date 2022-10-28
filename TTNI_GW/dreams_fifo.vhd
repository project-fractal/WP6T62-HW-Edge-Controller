----------------------------------------------------------------------------------------------------
-- Project		   : SAFEPOWER
-- Module          : FIFO
-- File			   : safepower_fifo.vhd
-- Author          : Hamidreza Ahmadian
-- created		   : October, 20th 2015
-- last mod. by	   : Hamidreza Ahmadian
-- last mod. on	   :
-- last mod. by	   : Yosab Bebawy
-- last mod. on	   : June, 9th 2017  (Use BRAMs instead of buffers)
-- contents		   : SAFEPOWER FIFO for event ports
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- library includes
----------------------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library SAFEPOWER;
use SAFEPOWER.TTEL.all;        		-- constants, datatypes, and component declarations of the current TTEL
use SAFEPOWER.ttel_parameter.all;	-- for TTCOMMSCHED_SIZE

library SYSTEMS;
use SYSTEMS.system_parameter.all;	-- parameters of the current NoC instance
use SYSTEMS.configman.all;         	-- for extracting configuration parameters from the files
use SYSTEMS.auxiliary.all;


entity ent_fifo is
  Generic (
    FIFO_ADDR_WIDTH   : natural := 4;
    BUFF_ADDR_WIDTH   : natural := 4; -- in words (4xbytes)
    MemoryDepth       : natural := 1024;
    BRAM_ADDR_WIDTH   : natural := 10;
    AddrWidth     : natural := 4;  -- Depth of the RAM = 2^AddrWidth
    DATA_WIDTH        : natural := 36;
    WordWidth         : natural := 32;
    MessageLength         : natural := 16;
    WrRdPntrBaseAdress : natural := 1000
  );
  Port (
    clk               : in  std_logic;
    reset_n           : in  std_logic;
    enq               : in  std_logic;
    terminate         : in  std_logic;
    din               : in  std_logic_vector (WordWidth - 1 downto 0);
    deq               : in  std_logic;
    dout              : out std_logic_vector (WordWidth - 1 downto 0);
-- nqdmsg is ncremented by the terminate signal and decremented by the bempty, once the buffer becomes empty
    nqdmsg            : out std_logic_vector (BRAM_ADDR_WIDTH-1 downto 0);
-- msglen is updated based on rBuffRdPntr and exhibits the length of the message which is going to be read, in case of dequeue 
    msglen            : out std_logic_vector (BRAM_ADDR_WIDTH-1 downto 0);
    fFull             : out std_logic;  --suoyou d fifo quan man
    fEmpty            : out std_logic;
    bFull             : out std_logic;
    bEmpty            : out std_logic
  );
end;

architecture event_sig_buffer of ent_fifo is

component ent_buffer
  Generic (
    AddrWidth     : natural := 4;  -- Depth of the RAM = 2^AddrWidth
    WordWidth     : natural := 32
  );
  Port (
    clk               : in  std_logic;
    reset_n           : in  std_logic;
    enq               : in  std_logic;
    din               : in  std_logic_vector (WordWidth - 1 downto 0);
    full              : out std_logic;
    deq               : in  std_logic;
    dout              : out std_logic_vector (WordWidth - 1 downto 0);
    msglen            : out std_logic_vector (BUFF_ADDR_WIDTH downto 0);
    empty             : out std_logic

  );
end component;


  constant QUEUE_WIDTH     : natural := 2 ** BUFF_ADDR_WIDTH; -- in words (4xbytes) --fifo duo shen
--  constant FIFO_ADDR_WIDTH : integer := clogb2 (QUEUE_LENGTH - 1);
  constant QUEUE_LENGTH		: natural := 2 ** FIFO_ADDR_WIDTH;  --duoshao ge fifo
  -- constant AddrWidth : integer := clogb2 (QUEUE_WIDTH - 1);
  constant C_MAX_NQD       : unsigned (FIFO_ADDR_WIDTH downto 0) := (FIFO_ADDR_WIDTH => '1', others => '0');

  type dout_type is array (0 to (QUEUE_LENGTH - 1)) of std_logic_vector (WordWidth - 1 downto 0);
  type nqd_type   is array (0 to (QUEUE_LENGTH - 1)) of std_logic_vector (BUFF_ADDR_WIDTH downto 0);


  signal wEnq               : std_logic_vector (QUEUE_LENGTH - 1 downto 0);
  signal wDeq               : std_logic_vector (QUEUE_LENGTH - 1 downto 0);
  signal sdeq               : std_logic;
  signal senq               : std_logic;
  signal wDin               : std_logic_vector (WordWidth - 1 downto 0);
  signal wDout              : dout_type;
  signal sWriteDone         : std_logic;
  signal sReadDone          : std_logic;
  signal wTerminate         : std_logic;
  signal wDeq_connected     : std_logic;
  signal wEnq_connected     : std_logic;

  signal wFull              : std_logic_vector (QUEUE_LENGTH - 1 downto 0);
  signal rFull_ff	        : std_logic;
  signal rFull_ff2	        : std_logic;
  signal rFull_pulse        : std_logic;
  signal wEmpty             : std_logic_vector (QUEUE_LENGTH - 1 downto 0);
  signal rEmptyPulse        : std_logic;
  signal rEmpty_ff          : std_logic;
  signal rEmpty_ff2         : std_logic;


  signal rBuffWrPntr        : unsigned (FIFO_ADDR_WIDTH  downto 0) := (others => '0');
  signal rBuffRdPntr        : unsigned (FIFO_ADDR_WIDTH  downto 0) := (others => '0');
  signal rNqdBuffer         : unsigned (FIFO_ADDR_WIDTH  downto 0) := (others => '0');
  signal rMsgLen            : nqd_type;

  signal sFFull             : std_logic;
  signal sFEmpty            : std_logic;

begin
  sWriteDone <=  wTerminate; --  OR rFull_pulse;
  sReadDone <= rEmptyPulse;

  rFull_pulse	<= (not rFull_ff2) and rFull_ff;
  rFull_ff <= wFull (to_integer (rBuffWrPntr (FIFO_ADDR_WIDTH - 1 downto 0)));

  rEmpty_ff <= wEmpty (to_integer (rBuffRdPntr (FIFO_ADDR_WIDTH - 1 downto 0))) when reset_n = '1' else '1';
  rEmptyPulse	<=(not rEmpty_ff2) and rEmpty_ff;

  --  wDeq <= ((to_integer (rBuffRdPntr (FIFO_ADDR_WIDTH - 1 downto 0))) => sdeq , others => '0');
  bFull <=  rFull_pulse; --wFull(to_integer (rBuffWrPntr (FIFO_ADDR_WIDTH - 1 downto 0)));
  bEmpty <= wEmpty (to_integer (rBuffRdPntr (FIFO_ADDR_WIDTH - 1 downto 0)));
  wDin <= din;
  dout <= wDout (to_integer (rBuffRdPntr (FIFO_ADDR_WIDTH - 1 downto 0))) ;

  rNqdBuffer <= rBuffWrPntr - rBuffRdPntr;
  sFFull  <= '1' when rNqdBuffer = C_MAX_NQD else '0';
  sFEmpty <= '1' when rNqdBuffer = 0  else '0';

  fFull  <= sFFull;  
  fEmpty <= sFEmpty;
  nqdmsg(FIFO_ADDR_WIDTH downto 0) <= std_logic_vector (rNqdBuffer);


  --Generate a pulse to terminate the write operation
	process(reset_n, clk)
  begin
  if reset_n = '0'  then
    rFull_ff2 <= '0';
    rEmpty_ff2 <= '1';
    elsif rising_edge (clk) then
    rFull_ff2 <= rFull_ff;
    rEmpty_ff2 <= rEmpty_ff;
    end if;
  end process;


  -- --    process for generation of rFull_pulse
  --   process (clk)
  --   begin
  --     if reset_n = '0' then
  --       rFull_pulse <= '0';
  --     elsif rising_edge (clk) then
  --       if rFull_pulse = '0' then
  --         if wFull (to_integer (rBuffWrPntr (FIFO_ADDR_WIDTH - 1 downto 0))) = '1' then
  --           rFull_pulse <= '1';
  --         end if;
  --       else
  --         rFull_pulse <= '0';
  --       end if;
  --     end if;
  --   end process;

   -- process for controlling the wEnq_connected

  -- it will be connected if the buffer is not full and the wren is not assserted

--  process (reset_n,enq, sFFull, rFull_pulse, terminate)

--  begin

--    if reset_n = '0' then

--      wEnq_connected <= '1';

--    else

--        if wEnq_connected = '1' then

--       if sFFull = '1' OR (sWriteDone = '1' AND enq = '1') then

----            if sFFull = '1' OR rFull_pulse = '1' then

--                wEnq_connected <= '0';

--            else

                wEnq_connected <= '1';

--            end if;

--        else

--            if enq = '0' and terminate = '1' then

--                wEnq_connected <= '1';

--            else

--                wEnq_connected <= '0';

 

--            end if;

--        end if;

--    end if;

--  end process;

 

  senq <= enq when terminate = '0' else '0';   --by chen

 

 

--  -- process for controlling the wDeq_connected

--  -- it will be connected if the buffer is not full and the wren is not assserted

--  process (reset_n, deq, sFEmpty, sReadDone)

--  begin

--    if reset_n = '0' then

--      wDeq_connected <= '1';

--    else

--      if wDeq_connected = '0' then

--        if sFEmpty /= '1' AND deq /= '1' then

          wDeq_connected <= '1';

--        else

--          wDeq_connected <= '0';

--        end if;

--      elsif sReadDone = '1' then

--        wDeq_connected <= '0';

--      else

--         wDeq_connected <= '1';

--      end if;

--    end if;

--  end process;

 

  sdeq <= deq when wDeq_connected = '1' else '0';

  -- process for generation of wTerminate
  -- TODO: should we use enq or wEnq?
  process (clk, terminate, enq)
  begin
    if reset_n = '0' then
      wTerminate <= '0';
    elsif rising_edge (clk) then
      if wTerminate = '0' then     --cansheng yige maichong
        if terminate = '1' then -- AND enq = '1' then
          wTerminate <= '1';
        end if;
      else
        wTerminate <= '0';
      end if;
    end if;
  end process;

-- process for generation of ungoing_write
--    process (reset_n,senq,sWriteDone)
--    begin
--        if reset_n = '0' then
--            ungoing_write <= '0';
--        else
--            if ungoing_write = '0' then
--                if senq = '1' then
--                    ungoing_write <= '1';
--                end if;
--            else
--                if sWriteDone = '1' then
--                    ungoing_write <= '0';
--                end if;
--            end if;
--        end if;
--    end process;


----    process for generation of rEmptyPulse
--  process (clk)
--  begin
--    if reset_n = '0' then
--      rEmptyPulse <= '0';
--    elsif rising_edge (clk) then
--      if rEmptyPulse = '0' then
--        if wEmpty (to_integer (rBuffRdPntr (FIFO_ADDR_WIDTH - 1 downto 0))) = '1' then
--          rEmptyPulse <= '1';
--        end if;
--      else
--        rEmptyPulse <= '0';
--      end if;
--    end if;
--  end process;


  -- process for increasing the rBuffWrPntr and rBuffWrPntr
  process (clk)
  begin
    if reset_n = '0' then
      rBuffWrPntr <= (others => '0');
    elsif rising_edge (clk) then
      if sWriteDone = '1' then
        rBuffWrPntr <= rBuffWrPntr + 1;
      end if;
    end if;
  end process;

  -- process for increasing the rBuffWrPntr and rBuffRdPntr
  process (clk)
  begin
    if reset_n = '0' then
      rBuffRdPntr <= (others => '0');
    elsif rising_edge (clk) then
      if sReadDone = '1' then
        rBuffRdPntr <= rBuffRdPntr + 1;
      end if;
    end if;
  end process;



  gen_fifo:
  for index in 0 to QUEUE_LENGTH - 1
  generate
    fifox : ent_buffer
    generic map (
    AddrWidth => BUFF_ADDR_WIDTH,
    WordWidth => WordWidth
    )
    port map (
      clk => clk,
      reset_n => reset_n,
      enq => wEnq(index),
      din => wDin,
      full => wFull (index),
      deq => wDeq (index),
      dout => wDout (index),
      msglen => rMsgLen (index),
      empty => wEmpty (index)
    );
  end generate;

--  process (reset_n, senq, rBuffWrPntr)
--  begin
--    if reset_n = '0' then
--      wEnq <= (others => '0');
--    else
--      wEnq (to_integer (rBuffWrPntr (FIFO_ADDR_WIDTH - 1 downto 0))) <= senq;
----      wEnq (QUEUE_LENGTH - 1 downto to_integer (rBuffWrPntr (FIFO_ADDR_WIDTH - 1 downto 0)) + 1) <= (others => '0');
----      wEnq (to_integer (rBuffWrPntr (FIFO_ADDR_WIDTH - 1 downto 0)) - 1 downto 0) <= (others => '0');
--    end if;
--  end process;

  process (reset_n, senq, rBuffWrPntr)
  variable temp_cntr : integer := 0;
  begin
    if reset_n = '0' then
      wEnq <= (others => '0');
    else
      for temp_cntr in 0 to QUEUE_LENGTH - 1 loop
        if temp_cntr = to_integer (rBuffWrPntr (FIFO_ADDR_WIDTH - 1 downto 0)) then
          wEnq (temp_cntr) <= senq;
        else
          wEnq (temp_cntr) <= '0';
        end if;
      end loop;
    end if;
  end process;

--  process (reset_n, sdeq, rBuffRdPntr)
--  begin
--    if reset_n = '0' then
--      wDeq <= (others => '0');
--    else
--      wDeq (to_integer (rBuffRdPntr (FIFO_ADDR_WIDTH - 1 downto 0))) <= sdeq;
--    end if;
--  end process;

  process (reset_n, sdeq, rBuffRdPntr)
  variable temp_cntr : integer := 0;
  begin
    if reset_n = '0' then
      wDeq <= (others => '0');
    else
      for temp_cntr in 0 to QUEUE_LENGTH - 1 loop
        if temp_cntr = to_integer (rBuffRdPntr (FIFO_ADDR_WIDTH - 1 downto 0)) then
          wDeq (temp_cntr) <= sdeq;
        else
          wDeq (temp_cntr) <= '0';
        end if;
      end loop;
    end if;
  end process;


  -- process for latching msglen
-- because of sensitivity list was commented
--  process (reset_n, sFEmpty, rBuffRdPntr)
--  begin
--    if reset_n = '0' or sFEmpty = '1' then
--      msglen <= (others => '0');
--    else
--      msglen <= rMsgLen (to_integer (rBuffRdPntr (FIFO_ADDR_WIDTH - 1 downto 0)));
--    end if;
--  end process;

  process (reset_n, clk)
  begin
    if reset_n = '0' or sFEmpty = '1' then
      msglen <= (others => '0');
    elsif rising_edge (clk) then 
      msglen (BUFF_ADDR_WIDTH downto 0) <= rMsgLen (to_integer (rBuffRdPntr (FIFO_ADDR_WIDTH - 1 downto 0)));
    end if;
  end process;


end event_sig_buffer;

architecture event_bram_port of ent_fifo is


    constant NrMsgWords    :        integer     := ld(MessageLength);
    constant cNrMsgWords    : unsigned  (NrMsgWords downto 0) := (NrMsgWords => '1', others => '0');
    constant Memory_ADD_Width		: integer		:= ld(MemoryDepth);
    constant C_MAX_NUM_ELEMENTS : unsigned (AddrWidth downto 0) := (AddrWidth => '1', others => '0');
    --constant cWrRdPntrBaseAdress   : unsigned (Memory_ADD_Width -1 downto 0) := to_unsigned (WrRdPntrBaseAdress,10);
    
    
    constant cWrRdPntrlength            : unsigned (Memory_ADD_Width -1 downto 0) := to_unsigned (MemoryDepth/MessageLength,10);--几个message
    constant cWrRdPntrHighAdress        : unsigned (Memory_ADD_Width -1 downto 0) := to_unsigned (MemoryDepth-1,10);
    constant cWrRdPntrBaseAdress        : unsigned (Memory_ADD_Width -1 downto 0) := cWrRdPntrHighAdress - cWrRdPntrlength;
    constant cWrRdDatapntrHighAdress    : unsigned (Memory_ADD_Width -1 downto 0) := cWrRdPntrBaseAdress - 1;
    
component BRAM_Ports is
   generic
   (
	 	--WordWidth         : natural := 32;
	 	DATA_WIDTH        : natural := 36;
	 	Addr_Width        : natural := 10
	 );
	port
	(
	   clk		: in  std_logic;
	   reset    : in  std_logic;
	   
       wren		: in  std_logic;
       WRADDR   : in  std_logic_vector (Addr_Width-1 downto 0); 
       DI       : in  std_logic_vector (DATA_WIDTH-1 downto 0);    
         
       rden		: in  std_logic;
       RDADDR   : in  std_logic_vector (Addr_Width-1 downto 0);
       DO       : out std_logic_vector (DATA_WIDTH-1 downto 0)
);

end component;

--component ent_buffer
--  Generic (
--    AddrWidth     : natural := 4;  -- Depth of the RAM = 2^AddrWidth
--    WordWidth     : natural := 32
--  );
--  Port (
--    clk               : in  std_logic;
--    reset_n           : in  std_logic;
--    enq               : in  std_logic;
--    din               : in  std_logic_vector (WordWidth - 1 downto 0);
--    full              : out std_logic;
--    deq               : in  std_logic;
--    dout              : out std_logic_vector (WordWidth - 1 downto 0);
--    msglen            : out std_logic_vector (BUFF_ADDR_WIDTH downto 0);
--    empty             : out std_logic

--  );
--end component;


  constant QUEUE_WIDTH     : natural := 2 ** BUFF_ADDR_WIDTH; -- in words (4xbytes)
--  constant FIFO_ADDR_WIDTH : integer := clogb2 (QUEUE_LENGTH - 1);
  constant QUEUE_LENGTH		: natural := 2 ** FIFO_ADDR_WIDTH;  
  -- constant AddrWidth : integer := clogb2 (QUEUE_WIDTH - 1);
 -- constant C_MAX_NQD       : unsigned (FIFO_ADDR_WIDTH downto 0) := (FIFO_ADDR_WIDTH => '1', others => '0');
  constant C_MAX_NQD       : unsigned (Memory_ADD_Width -1 downto 0) := "1111100111";      --????
  

  --type dout_type is array (0 to (QUEUE_LENGTH - 1)) of std_logic_vector (WordWidth - 1 downto 0);
  --type nqd_type   is array (0 to (QUEUE_LENGTH - 1)) of std_logic_vector (BUFF_ADDR_WIDTH downto 0);


  signal wEnq               : std_logic_vector (QUEUE_LENGTH - 1 downto 0);
  signal wDeq               : std_logic_vector (QUEUE_LENGTH - 1 downto 0);
  signal sdeq               : std_logic;
  signal senq               : std_logic;
  signal wDin               : std_logic_vector (WordWidth - 1 downto 0);
  --signal wDout              : dout_type;
  signal sWriteDone         : std_logic;
  signal sReadDone          : std_logic;
  signal wTerminate         : std_logic;
  signal wDeq_connected     : std_logic;
  signal wEnq_connected     : std_logic;

  signal wFull              : std_logic_vector (QUEUE_LENGTH - 1 downto 0);
  signal rFull_ff	        : std_logic;
  signal rFull_ff2	        : std_logic;
  signal rFull_pulse        : std_logic;
  signal wEmpty             : std_logic_vector (QUEUE_LENGTH - 1 downto 0);
  signal rEmptyPulse        : std_logic;
  signal rEmpty_ff          : std_logic;
  signal rEmpty_ff2         : std_logic;


  --signal rBuffWrPntr        : unsigned (FIFO_ADDR_WIDTH  downto 0) := (others => '0');
  --signal rBuffRdPntr        : unsigned (FIFO_ADDR_WIDTH  downto 0) := (others => '0');
  signal rNqdBuffer         : unsigned (Memory_ADD_Width - 1 downto 0) := (others => '0');
  --signal rMsgLen            : nqd_type;

  signal sFFull             : std_logic;
  signal sFEmpty            : std_logic;
  
  signal dataIN             : std_logic_vector (DATA_WIDTH - 1 downto 0);
  signal dataOUT            : std_logic_vector (DATA_WIDTH - 1 downto 0) := (others => '0');
  signal wrpntr             : unsigned (AddrWidth  downto 0) := (others => '0');
  signal rdpntr             : unsigned (AddrWidth  downto 0) := (others => '0');
  signal MemDataRdPntr      : unsigned (Memory_ADD_Width - 1 downto 0):= (others => '0');
  signal MemDataWrPntr      : unsigned (Memory_ADD_Width - 1 downto 0):= (others => '0');
  signal nqd                : unsigned (AddrWidth downto 0) := (others => '0');
  signal full_loc           : std_logic;
  signal empty_loc          : std_logic;
  signal msglength          :  std_logic_vector (Memory_ADD_Width - 1 downto 0);
  
  signal Wr_ADD             : std_logic_vector (Memory_ADD_Width - 1 downto 0);
  signal Rd_ADD             : std_logic_vector (Memory_ADD_Width - 1 downto 0);
  
  signal sEnqwrpntr         : std_logic;
  signal sEnqwrpntr_ff2     : std_logic;
  signal sEnqwrpntr_puls    : std_logic;
  signal sDeqRdpntr         : std_logic;
  signal sDeqRdpntr_ff2     : std_logic;
  signal sDeqRdpntr_puls    : std_logic;
  signal sDeqRdpntr_puls_2  : std_logic;
  signal Wr_ADD_Pntr        : std_logic_vector (DATA_WIDTH - 1 downto 0);
  signal Rd_ADD_Pntr        : std_logic_vector (DATA_WIDTH - 1 downto 0);
  signal sAddWrPntr         : unsigned (Memory_ADD_Width - 1  downto 0) := cWrRdPntrBaseAdress;
  signal sAddRdPntr         : unsigned (Memory_ADD_Width - 1  downto 0) := cWrRdPntrBaseAdress;
  signal RdfirstPntr        : std_logic_vector (Memory_ADD_Width - 1 downto 0);
  signal RdlastPntr         : std_logic_vector (Memory_ADD_Width - 1 downto 0):= (others => '0');
  signal DeqFlag            : std_logic;
  signal ndeqMsgwords       : unsigned (NrMsgWords downto 0) := (others => '0');--????????

begin
  sWriteDone <=  wTerminate; --  OR rFull_pulse;
  sReadDone <= rEmptyPulse;
  
  sEnqwrpntr_puls <= wTerminate;
  sDeqRdpntr_puls <= ((not sDeqRdpntr_ff2) and sDeqRdpntr) ;--or sDeqRdpntr_puls_2;--读请求脉冲
  
  rFull_pulse	<= (not rFull_ff2) and rFull_ff;
  rFull_ff <= full_loc;

  rEmpty_ff <= empty_loc when reset_n = '1' else '1';
  rEmptyPulse	<= (not rEmpty_ff2) and rEmpty_ff;

  --  wDeq <= ((to_integer (rBuffRdPntr (FIFO_ADDR_WIDTH - 1 downto 0))) => sdeq , others => '0');
  bFull <=  rFull_pulse; --wFull(to_integer (rBuffWrPntr (FIFO_ADDR_WIDTH - 1 downto 0)));--当前FIFO
  --bEmpty <= sFEmpty;--empty_loc;
  
  process (clk)
  begin
    if reset_n = '0'  then
        ndeqMsgwords <= (others => '0'); ---操作单独一个fifo 16个深度
    elsif rising_edge (clk) then
        if deq = '1' and ndeqMsgwords /= cNrMsgWords then
            ndeqMsgwords <= ndeqMsgwords + 1;
            bEmpty <= sFEmpty;
        elsif  ndeqMsgwords = cNrMsgWords then
            bEmpty <= '1';
            ndeqMsgwords <= (others => '0');
        elsif  ndeqMsgwords = 0 then
            bEmpty <= '0';     
        end if;
    end if;   
  end process;
  
  wDin <= din;
  --dout <= wDout (to_integer (rBuffRdPntr (FIFO_ADDR_WIDTH - 1 downto 0))) ;

 -- rNqdBuffer <= rBuffWrPntr - rBuffRdPntr;
  --rNqdBuffer <= wrpntr - rdpntr;
  rNqdBuffer <= MemDataWrPntr - MemDataRdPntr;
  sFFull  <= '1' when rNqdBuffer = C_MAX_NQD else '0';
  sFEmpty <= '1' when rNqdBuffer = 0  else '0';

  fFull  <= sFFull;
  fEmpty <= sFEmpty;
  --nqdmsg <= std_logic_vector (rNqdBuffer(AddrWidth  downto 0));
  nqdmsg <= std_logic_vector(unsigned(sAddWrPntr - sAddRdPntr));
  
  rdpntr <= MemDataRdPntr(AddrWidth  downto 0);
  wrpntr <= MemDataWrPntr(AddrWidth  downto 0);-- youwenti??????????????????????????????????????????
      
      
----Generate a pulse to terminate the write operation
--     process(reset_n, clk)
--     begin
--        if reset_n = '0'  then
--            sEnqwrpntr <= '0';
--            sEnqwrpntr_ff2 <= '0';
--          elsif rising_edge (clk) then
--          sEnqwrpntr <= senq;
--          sEnqwrpntr_ff2  <= sEnqwrpntr;
--          end if;
--     end process;
     
     
     --Generate a pulse to terminate the write operation
          process(reset_n, clk)
          begin
             if reset_n = '0'  then
                 sDeqRdpntr <= '0';
                 sDeqRdpntr_ff2 <= '0';
               elsif rising_edge (clk) then
               sDeqRdpntr <= sdeq;
               sDeqRdpntr_ff2  <= sDeqRdpntr;
               end if;
          end process;

  --Generate a pulse to terminate the write operation
	process(reset_n, clk)
  begin
  if reset_n = '0'  then
    rFull_ff2 <= '0';
    rEmpty_ff2 <= '1';
    elsif rising_edge (clk) then
    rFull_ff2 <= rFull_ff;    --FIFO full
    rEmpty_ff2 <= rEmpty_ff;
    end if;
  end process;
  
  process (clk)
    begin
      IF rising_edge (clk) then
        if (reset_n = '0') then
          --wrpntr <= (others => '0');
          --rdpntr <= (others => '0');
          MemDataWrPntr <= (others => '0');
          MemDataRdPntr <= (others => '0');
        elsif (enq = '1' and sEnqwrpntr_puls = '0') then
         -- buffer_inst (to_integer (wrpntr (AddrWidth - 1 downto 0))) <= unsigned(din);
          MemDataWrPntr <= MemDataWrPntr+1;
          if MemDataWrPntr = cWrRdDatapntrHighAdress then
            MemDataWrPntr <= (others => '0');  
          end if;
--          if (to_integer(unsigned(wrpntr)) = C_MAX_NUM_ELEMENTS) then
--            wrpntr <= (others => '0'); 
--          end if;
        end if;
        IF (sDeqRdpntr_puls = '1' and DeqFlag = '0') then      --DepFlag bishi zhengzai du
         -- dout <= std_logic_vector (buffer_inst (to_integer(rdpntr (AddrWidth - 1 downto 0))));
          --RdlastPntrNext <= RdlastPntr;      
          if (MemDataRdPntr <=  unsigned(std_logic_vector(RdlastPntr))) then
            MemDataRdPntr <= MemDataRdPntr + 1;
            if MemDataRdPntr = cWrRdDatapntrHighAdress then
              MemDataRdPntr <= (others => '0');  
            end if;
          end if;
--           if (to_integer(unsigned(rdpntr)) = C_MAX_NUM_ELEMENTS) then
--             rdpntr <= (others => '0'); 
--           end if;
        end if;
      end if;
    end process;

    full_loc  <= '1' when to_integer(unsigned(wrpntr)) = C_MAX_NUM_ELEMENTS else '0';
    empty_loc <= '1' when to_integer(unsigned(rdpntr)) = 0 else '0';
    nqd <= wrpntr - rdpntr;
    msglength <= std_logic_vector (rNqdBuffer);

  -- --    process for generation of rFull_pulse
  --   process (clk)
  --   begin
  --     if reset_n = '0' then
  --       rFull_pulse <= '0';
  --     elsif rising_edge (clk) then
  --       if rFull_pulse = '0' then
  --         if wFull (to_integer (rBuffWrPntr (FIFO_ADDR_WIDTH - 1 downto 0))) = '1' then
  --           rFull_pulse <= '1';
  --         end if;
  --       else
  --         rFull_pulse <= '0';
  --       end if;
  --     end if;
  --   end process;

  -- process for controlling the wEnq_connected
  -- it will be connected if the buffer is not full and the wren is not assserted
--  process (reset_n,enq, sFFull, rFull_pulse, terminate)
--  begin
--    if reset_n = '0' then
      wEnq_connected <= '1';
--    else
--        if wEnq_connected = '1' then
--      -- if sFFull = '1' OR (sWriteDone = '1' AND enq = '1') then
--            if sFFull = '1' OR rFull_pulse = '1' then
--                wEnq_connected <= '0';
--            else
--                wEnq_connected <= '1';
--            end if;
--        else
--            if enq = '0' and terminate = '1' then
--                wEnq_connected <= '1';
--            else
--                wEnq_connected <= '0';

--            end if;
--        end if;
--    end if;
--  end process;

  senq <= sEnqwrpntr_puls when sEnqwrpntr_puls = '1' else enq when wEnq_connected = '1' else '0';



      wDeq_connected <= '1';


  sdeq <= sDeqRdpntr_puls when sDeqRdpntr_puls = '1' else deq when wDeq_connected = '1' else '0';


  -- process for generation of wTerminate
  -- TODO: should we use enq or wEnq?
  process (clk, terminate, enq)
  begin
    if reset_n = '0' then
      wTerminate <= '0';
    elsif rising_edge (clk) then
      if wTerminate = '0' then
        if terminate = '1' then -- AND enq = '1' then
          wTerminate <= '1';
        end if;
      else
        wTerminate <= '0';
      end if;
    end if;
  end process;

  
  
   -- process for increasing the sAddWrPntr
   process (clk)
   begin
     if reset_n = '0' then
       sAddWrPntr <= cWrRdPntrBaseAdress;
     elsif rising_edge (clk) then
       if wTerminate = '1' then
          if sAddWrPntr = cWrRdPntrHighAdress then
            sAddWrPntr <= cWrRdPntrBaseAdress; 
        else
            sAddWrPntr <= sAddWrPntr + 1;     
        end if;       
       end if;
     end if;
   end process;
   
   -- process for increasing the sAddRdPntr
      process (clk)
      begin
        if reset_n = '0' then
          sAddRdPntr <= cWrRdPntrBaseAdress;
          sDeqRdpntr_puls_2 <= '0';
        elsif rising_edge (clk) then
          if sDeqRdpntr_puls = '1' and DeqFlag = '0' and MemDataRdPntr = unsigned(std_logic_vector(RdlastPntr)) then                               
            --RdfirstPntr <= Rd_ADD_Pntr(Memory_ADD_Width - 1 downto 0);           
            if sAddRdPntr = cWrRdPntrHighAdress then
                sAddRdPntr <= cWrRdPntrBaseAdress; 
            else
                sAddRdPntr <= sAddRdPntr + 1;     
            end if;
          end if;
        end if;
      end process;
      

  process (reset_n, clk)
  begin
    if reset_n = '0'then
      msglen <= (others => '0');
    elsif rising_edge (clk) then 
      msglen <= msglength;--rMsgLen (to_integer (rBuffRdPntr (FIFO_ADDR_WIDTH - 1 downto 0)));
    end if;
  end process;
  
   Event_BRAM : BRAM_Ports 
      port map
      (
         clk  => clk,
         reset  => reset_n,
         
         wren    => senq,
         WRADDR  => Wr_ADD, 
         DI      => dataIN,    
           
         rden     => sdeq,
         RDADDR    => Rd_ADD,
         DO      => dataOUT
  );
  

 
 
 process (clk)
 begin
    if reset_n = '0'then
        DeqFlag <= '0';
    elsif rising_edge (clk) then
        if  sDeqRdpntr_puls = '1' and DeqFlag = '0' then
            DeqFlag <= '1';
        elsif  DeqFlag = '1' then
            DeqFlag <= '0';      
        end if;  
    end if;  
 end process;
   
 Wr_ADD_Pntr <= x"000000" & "00" & Wr_ADD;
 --RdlastPntr <= Rd_ADD_Pntr(Memory_ADD_Width - 1 downto 0);
 RdlastPntr <= dataOUT (Memory_ADD_Width - 1 downto 0) when sDeqRdpntr_puls = '1'; --youwenti
 Wr_ADD <= std_logic_vector (unsigned(sAddWrPntr)) when sEnqwrpntr_puls = '1' else std_logic_vector (unsigned(MemDataWrPntr)) ; 
 --Rd_ADD <= std_logic_vector (unsigned(rBuffRdPntr)) & std_logic_vector (unsigned(rdpntr));
 Rd_ADD <= std_logic_vector (unsigned(MemDataRdPntr)) when sDeqRdpntr_puls = '1' and DeqFlag = '0'else std_logic_vector (unsigned(sAddRdPntr)); ---youwenti
 dataIN <= x"000000" & "00" & std_logic_vector (unsigned(MemDataWrPntr)) when sEnqwrpntr_puls = '1' else "0000" & wDin;
 dout <= dataOUT (31 downto 0) when sDeqRdpntr_puls = '0' and DeqFlag = '0';

end event_bram_port;
