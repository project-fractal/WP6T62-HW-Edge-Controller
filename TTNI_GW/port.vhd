---------------------------------------------------------------------------------------------------
-- Project		: SAFEPOWER
-- Module       : Port
-- File			: portman.vhd
-- Author		: Hamidreza Ahmadian
-- created		: August, 13th 2015
-- last mod. by	: Hamidreza Ahmadian
-- last mod. on	: August, 13th 2015
-- contents		: top level entity of the port
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
-- library includes
---------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;	-- for conv_integer
use IEEE.std_logic_unsigned.all;


library SAFEPOWER;
use SAFEPOWER.TTEL.all;        		-- constants, datatypes, and component declarations of the current TTEL

library SYSTEMS;
use SYSTEMS.auxiliary.all;         	-- helper functions and helper procedures
use SYSTEMS.system_parameter.all;	-- parameters of the current NoC instance


entity ent_port is
  Generic (
    MY_CONFIG             : rt_pcfg;
    state_bram_enable     : std_logic := '1';
    event_bram_enable     : std_logic := '1';
    BRAM_ADDR_WIDTH   : natural := 10;
    PORT_ID               : integer := 0;
    WordWidth             : natural := 32;
    RWordWidth            : natural := 8
    );
  Port (
    clk             : in std_logic;
    reset_n         : in std_logic;
    pTimeCnt        : in t_timeformat;
    msglen            : out std_logic_vector (BRAM_ADDR_WIDTH-1 downto 0);
    --  core side ports:
    enq             : in std_logic;
    terminate       : in std_logic;
    wr_addr_en		: in std_logic; 
    wr_addr			: in std_logic_vector (clogb2 (MY_CONFIG.CONF_BUF_SIZ - 1) - 1 downto 0); 
    qin             : in std_logic_vector (WordWidth - 1 downto 0);
    full            : out std_logic;
    bFull           : out std_logic;
    newMsg          : out std_logic;

    --  ebu side ports
    deq             : in std_logic;
    rd_addr_en		: in std_logic; 
    rd_addr			: in std_logic_vector (clogb2 (MY_CONFIG.CONF_BUF_SIZ - 1) - 1 downto 0); 
    qout            : out std_logic_vector (WordWidth - 1 downto 0);
    empty           : out std_logic;
    bEmpty          : out std_logic;

    -- err.rmi <-> port ports
  --send_error      : in std_logic;
    send_error_id   : in t_portid;
    error_flag      : out std_logic;
    error_data      : out std_logic_vector (31 downto 0);

    -- status.rmi <-> port ports
    status_data     : out  std_logic_vector (31 downto 0);
    status_port_id  : in t_portid;
    rd_s            : in std_logic;

    -- reconf.rmi <-> port ports
    reconf_data     : in std_logic_vector (15 downto 0);
    --reconf_port_sel : in std_logic;
    reconf_port_id  : in STD_LOGIC_VECTOR (7 downto 0);

    myType          : out t_porttype;
    -- myId            : out t_portid;
    destination     : out t_phyname
  );
end ent_port;

architecture safepower of ent_port is

  -- Data area for event ports
  component ent_fifo
  Generic (
    FIFO_ADDR_WIDTH   : natural := 4;
    BUFF_ADDR_WIDTH   : natural := 4; -- in words (4xbytes)
    BRAM_ADDR_WIDTH   : natural := 10;
    WordWidth         : natural := 32
  );
  Port (
    clk               : in  std_logic;
    reset_n           : in  std_logic;
    enq               : in  std_logic;
    terminate         : in  std_logic;
    din               : in  std_logic_vector (WordWidth - 1 downto 0);
    deq               : in  std_logic;
    dout              : out std_logic_vector (WordWidth - 1 downto 0);
    nqdmsg            : out std_logic_vector (BRAM_ADDR_WIDTH-1 downto 0);
    msglen            : out std_logic_vector (BRAM_ADDR_WIDTH-1 downto 0);
    fFull             : out std_logic;
    fEmpty            : out std_logic;
    bFull             : out std_logic;
    bEmpty            : out std_logic
  );
  end component;

  -- Data area for state ports
  component double_buffer
  generic (
		AddrWidth				: natural:= 4;
		WordWidth				: natural:= 32
	);
	port (
        wr_en					: in std_logic;
		wr_ter					: in std_logic;
		wr_addr_en				: in std_logic; 
		wr_addr					: in std_logic_vector (AddrWidth - 1 downto 0); 
		wr_data					: in std_logic_vector(WordWidth-1 downto 0);
		rd_en					: in std_logic;
		rd_addr_en				: in std_logic; 
		rd_addr					: in std_logic_vector (AddrWidth - 1 downto 0); 
		rd_data		 			: out std_logic_vector(WordWidth-1 downto 0);
		msglen          		: out std_logic_vector (AddrWidth downto 0);
		bFull           		: out std_logic;
		full            		: out std_logic;
		bEmpty          		: out std_logic;
		empty           		: out std_logic;
		reset_n         		: in std_logic;
		clk 					: in std_logic
	);
  end component;


  component port_status
    generic (
    	PORT_ID                : integer := 0;
		PORTDATA_WIDTH				 : integer := 32;    	
    	BUFF_ADDR_WIDTH        : integer := 10;
    	FIFO_ADDR_WIDTH      	 : integer := 8
    );
    port(
    	port_full		: in  std_logic;
    	port_empty		:in  std_logic;
    	buffer_full		:in  std_logic;
	buffer_empty		:in  std_logic;
    	nqd_port 		:in  std_logic_vector (FIFO_ADDR_WIDTH downto 0);
    	nqd_buffer 		:in  std_logic_vector (BUFF_ADDR_WIDTH downto 0);
    	port_add 		:in  t_portid;
    	port_data 		:out std_logic_vector (PORTDATA_WIDTH - 1 downto 0)
    );
  end component;

  component port_reconf
    generic (
        PORT_ID                : integer := 0;
    	MINT_initialization    : t_timeformat := x"000000000000000F";
    	DEST_initialization    : t_phyname := x"0000000F";
    	port_EN_initialization : std_logic :='1'
    );
    port(
    	clk                    : in  std_logic;
    	reset_n                : in std_logic;
      --reconf_port_sel            : in  std_logic;
    	reconf_port_id :      in t_portid;
      --preamble (127:120)  reserve(119:80) port_ID (79:72) command_ID (71:64) new_value(63:0)
    	config_data            : in  std_logic_vector (15 downto 0);
    	MINT_config_value      : out std_logic_vector (63 downto 0):= MINT_initialization; --(others => '0');
    	DEST_config_value      : out std_logic_vector (31 downto 0):= DEST_initialization;--(others => '0');
    	port_EN_value          : out std_logic:= port_EN_initialization;
    	err_out                : out std_logic
    );
  end component;

  component port_err
    generic (
    	My_PORT_ID         : integer := 0
    );

      port(
              clk                                     : in std_logic;
              reset_n                         : in std_logic;
              GlobalTime                      : in t_timeformat;
              pFull                           : in std_logic;
              pEmpty                          : in std_logic;
              bFull                           : in std_logic;
              bEmpty                          : in std_logic;
              ungoing_wr                      : in std_logic;
              ungoing_rd                      : in std_logic;
              enq                             : in std_logic;
              deq                             : in std_logic;
              conf_error              : in std_logic;
              send_error_id           : in t_portid;
              error_flag                      : out std_logic;
              error_data                      : out std_logic_vector (PORTDATA_WIDTH - 1 downto 0)
  );
end component;


  component mintchecker
    port
    (
      bFullIn           : in std_logic;
      pEmptyIn          : in std_logic;
      -- portDeq         : in std_logic;
      pTimeCnt          : in t_timeformat;
      bFullOut          : out std_logic;
      mint_value        : in t_timeformat;
      reset_n           : in std_logic;
      clk               : in std_logic
    );
  end component;


  constant PORT_TYPE            : t_porttype := MY_CONFIG.CONF_TYPE;
  constant PORT_SEMANTICS       : std_logic := MY_CONFIG.CONF_SEM;     -- State=0, Event=1
  constant BUFFER_SIZE          : integer := MY_CONFIG.CONF_BUF_SIZ;
  constant QUEUE_LENGTH         : integer := MY_CONFIG.CONF_QUE_LEN;
  constant INIT_DESTINATION     : t_phyname := MY_CONFIG.CONF_DEST; -- x"00060000";
  constant INIT_MINT_VALUE      : t_timeformat := MY_CONFIG.CONF_MINT;
  constant INIT_ENABLE          : std_logic := MY_CONFIG.CONF_EN;
  constant BUFF_ADDR_WIDTH      : integer := clogb2 (BUFFER_SIZE - 1);
  constant FIFO_ADDR_WIDTH 		: integer := clogb2 (QUEUE_LENGTH - 1);


  --------------------------------------------------------------------------------------------------
  -- signal declarations
  --------------------------------------------------------------------------------------------------

  signal wEmpty               : std_logic := '0';
  signal wbEmpty              : std_logic := '0';
  signal wMINT_config_value   : t_timeformat;
  signal wDEST_config_value   : t_phyname;
  signal wport_EN_value       : std_logic;
  signal sig_qout             : std_logic_vector (WordWidth - 1 downto 0);
  signal sig_qout_bram             : std_logic_vector (WordWidth - 1 downto 0);
  signal sig_nqd_qout         : std_logic_vector (WordWidth - 1 downto 0);

  signal wbFull               : std_logic;
  signal wFull                : std_logic;
  signal wNewMsg              : std_logic;
  signal sig_enq              : std_logic;
  signal sig_terminate        : std_logic;
  signal sig_deq              : std_logic;

  signal reconf_err           : std_logic;


  signal sig_nqdmsg           : std_logic_vector (BRAM_ADDR_WIDTH-1 downto 0);
  signal sig_msglen           : std_logic_vector (BRAM_ADDR_WIDTH-1 downto 0);
signal w_terminate:std_logic;
    
  

  begin
  myType <= PORT_TYPE;
  bFull <= wbFull;
  full <= wFull;
  empty <= wEmpty;
  bempty <= wbEmpty;
  --qout <= sig_nqd_qout when rd_s = '1' else sig_qout;
--  process (clk, sig_msglen, sig_nqdmsg, wFull, wEmpty, wbFull, wbEmpty)
--  begin
--  if reset_n = '0' then
--    sig_nqd_qout <= (others => '0');
--  elsif PORT_SEMANTICS = '1' then
    sig_nqd_qout <= wFull & wEmpty & wbFull & wbEmpty & "00" & sig_nqdmsg & "000000" & sig_msglen;
--  else
--    sig_nqd_qout <= wFull & wEmpty & wbFull & wbEmpty & "00" & "0000000000" & "000000" & sig_msglen;     
--  end if; 
--  end process;

  sig_terminate <= terminate when enq = '1' else '0';
--chen
  sig_enq <= enq when w_terminate = '0' AND wport_EN_value = '1' else '0';
  sig_deq <= deq when wport_EN_value = '1' else '0';
  --chen
  process (reset_n, clk ) -- S_AXI_AWVALID, sWrAddrPortId1
			begin
				if reset_n = '0' then
					w_terminate <= '0';
				elsif rising_edge (clk) then
					
					w_terminate<=terminate;
				end if;
			end process;
--
  destination_gen_BE: if PORT_TYPE = BE
  generate
      process (clk, reset_n)
  begin
    if reset_n = '0' then
      destination <= (others => '0');
    elsif rising_edge (clk) then
      if terminate = '1' then
        destination <= qin;
      end if;
    end if;
  end process;
  end generate;


  destination_gen_NOT_BE: if PORT_TYPE /= BE
  generate
    destination <=INIT_DESTINATION;-- wDEST_config_value;
  end generate;


--  process (clk, reset_n, rd_s, sig_deq, sig_qout)
--  begin
--    if reset_n = '0' then
--      qout <= sig_qout;
--    elsif rd_s = '1' then
--      qout <= sig_nqd_qout;
--    else
--      qout <= sig_qout;
--    end if;
--  end process;
  process (reset_n, rd_s, sig_deq, sig_qout)
  begin
    if reset_n = '0' then
      qout <= sig_qout;
    elsif rd_s = '1' then
      qout <= sig_nqd_qout;
    elsif sig_deq = '1' then
      qout <= sig_qout;
    end if;
  end process;

  
  event_port_buff_gen: if PORT_SEMANTICS = '1' and event_bram_enable = '0'-- "Event"
  generate
    buffer_area : entity work.ent_fifo(event_sig_buffer)
    generic map (
    FIFO_ADDR_WIDTH => FIFO_ADDR_WIDTH,
    BUFF_ADDR_WIDTH => BUFF_ADDR_WIDTH,
    -- QUEUE_WIDTH  => BUFFER_SIZE,
    WordWidth => WordWidth
    )
    port map (
      enq  => sig_enq,
      terminate => sig_terminate,
      deq  => sig_deq,
      din  => qin,
      dout  => sig_qout,
      nqdmsg  => sig_nqdmsg,
      msglen => sig_msglen,
      fFull  => wFull,
      fEmpty  => wEmpty,
      bFull => wbFull,
      bEmpty => wbEmpty,
      reset_n => reset_n,
      clk  => clk
      );
  end generate;
  
  event_port_bram_gen: if PORT_SEMANTICS = '1' and event_bram_enable = '1'-- "Event"
  generate
    Bram_area : entity work.ent_fifo(event_bram_port)
    generic map (
    FIFO_ADDR_WIDTH => FIFO_ADDR_WIDTH,
    BUFF_ADDR_WIDTH => BUFF_ADDR_WIDTH,
    -- QUEUE_WIDTH  => BUFFER_SIZE,
    WordWidth => WordWidth
    )
    port map (
      enq  => sig_enq,
      terminate => sig_terminate,
      deq  => sig_deq,
      din  => qin,
      dout  => sig_qout,
      nqdmsg  => sig_nqdmsg,
      msglen => sig_msglen,
      fFull  => wFull,
      fEmpty  => wEmpty,
      bFull => wbFull,
      bEmpty => wbEmpty,
      reset_n => reset_n,
      clk  => clk
      );
  end generate;  


  
  
  state_port_Buff_gen: if PORT_SEMANTICS = '0' and state_bram_enable = '0'-- "State"
  generate
    sig_nqdmsg <= (others => '0') when wEmpty = '1' else (0 => '1', others => '0'); 
    buffer_area : entity work.double_buffer(sig_buffer)
    generic map (
    AddrWidth => BUFF_ADDR_WIDTH,
    WordWidth => WordWidth
    )
    port map (
      wr_en  => sig_enq,
      wr_ter => sig_terminate,
      wr_addr_en => wr_addr_en,  
      wr_addr => wr_addr, 
      rd_en  => sig_deq,
      rd_addr_en => rd_addr_en,
      rd_addr => rd_addr, 
      msglen => sig_msglen,
      wr_data  => qin,
      rd_data  => sig_qout,
      full  => wFull,
      empty  => wEmpty,
      bFull  => wbFull,
      bEmpty  => wbEmpty,
      reset_n => reset_n,
      clk  => clk
      );
    end generate;
       
  state_port_bram_gen: if PORT_SEMANTICS = '0' and state_bram_enable = '1'-- "State"
      generate
        sig_nqdmsg <= (others => '0') when wEmpty = '1' else (0 => '1', others => '0'); 
        Bram_area: entity work.double_buffer(bram_port)
        generic map (
        AddrWidth => BUFF_ADDR_WIDTH,
        WordWidth => WordWidth
        )
        port map (
          wr_en  => sig_enq,
          wr_ter => sig_terminate,
          wr_addr_en => wr_addr_en,  
          wr_addr => wr_addr, 
          rd_en  => sig_deq,
          rd_addr_en => rd_addr_en,
          rd_addr => rd_addr, 
          msglen => sig_msglen,
          wr_data  => qin,
          rd_data  => sig_qout,
          full  => wFull,
          empty  => wEmpty,
          bFull  => wbFull,
          bEmpty  => wbEmpty,
          reset_n => reset_n,
          clk  => clk
          );           
  end generate;

  -- instantiation of the MINT checker for RC ports
  mintchecker_gen: if (PORT_TYPE = RC1 OR PORT_TYPE = RC2)
  generate
    mintchecker_inst: mintchecker
    port map (
      bFullIn => sig_terminate,
      pEmptyIn => wEmpty,
      -- portDeq => deq,
      pTimeCnt => pTimeCnt,
      mint_value => wMINT_config_value,
      bFullOut => newMsg,
      reset_n => reset_n,
      clk => clk
    );
  end generate;

  bfull_gen: if  (PORT_TYPE /= RC1 AND PORT_TYPE /= RC2)
  generate
    newMsg <= sig_terminate;
  end generate;

  port_status_inst: port_status
    generic map (
      PORT_ID => PORT_ID,
      BUFF_ADDR_WIDTH => BRAM_ADDR_WIDTH-1,
      FIFO_ADDR_WIDTH => BRAM_ADDR_WIDTH-1
    )
    port map (
    -- input from the port signals
      port_full => wFull,
      port_empty => wEmpty,
      buffer_full => wbFull,
      buffer_empty => wbEmpty,
      nqd_port => sig_nqdmsg,
      nqd_buffer => sig_msglen,
    -- interface to the RMI
      port_add => status_port_id,
      port_data => status_data
    );

  port_reconf_inst: port_reconf
  generic map (
    PORT_ID => PORT_ID,
  	MINT_initialization    => INIT_MINT_VALUE,
  	DEST_initialization    => INIT_DESTINATION,
  	port_EN_initialization => INIT_ENABLE
  )
  port map (
    clk => clk,
    reset_n => reset_n,

    -- to the port modules
    MINT_config_value => wMINT_config_value,
    DEST_config_value => wDEST_config_value,
    port_EN_value => wport_EN_value,
    -- from the RMI
  	--reconf_port_sel => reconf_port_sel,
  	reconf_port_id=>reconf_port_id,
  	config_data => reconf_data,
  	err_out => reconf_err
  );


  port_error_inst: port_err
  generic map (
    MY_PORT_ID => PORT_ID
  )
 
    port map (
    clk => clk,
    reset_n => reset_n,
    GlobalTime => pTimeCnt,
    enq => sig_enq,
    deq => sig_deq,
    bEmpty => wbEmpty,
    pEmpty => wEmpty,
    bFull => wbFull,
    pFull => wFull,
    ungoing_wr => '0', --TODO:
    ungoing_rd => '0', --TODO:
  --send_error_id => send_error_id,
    send_error_id => send_error_id,
    error_flag => error_flag,
    conf_error => reconf_err,
    error_data => error_data
  );
  --chen
msglen<=sig_msglen;

end safepower;