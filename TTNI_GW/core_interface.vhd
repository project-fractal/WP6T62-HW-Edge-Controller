  ----------------------------------------------------------------------------------
  -- Company: Embedded Systems, Universität Siegen
  -- Engineer: Hamidreza Ahmadian
  --
  -- Create Date: 06/01/2015 04:04:40 PM
  -- Design Name:
  -- Module Name:

  ----------------------------------------------------------------------------------------------------
  -- Project		    : SAFEPOWER
  -- Module         : Core interface
  -- File			      : core_interface.vhd
  -- Author         : Hamidreza Ahmadian
  -- created		    : October, 20th 2015
  -- last mod. by	  : Hamidreza Ahmadian
  -- last mod. on	  :
  -- contents		    : Core Interface - Behavioral
  ----------------------------------------------------------------------------------------------------

  ----------------------------------------------------------------------------------------------------
  -- library includes
  ----------------------------------------------------------------------------------------------------

  library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

  library SAFEPOWER;
  use SAFEPOWER.ttel_parameter.all;	-- parameters of the current NoC instance
  use SAFEPOWER.TTEL.all;        		-- constants, datatypes, and component declarations of the current TTEL
  use SAFEPOWER.memorymap.all;         	-- for map_pcfg 

  library SYSTEMS;
  use SYSTEMS.configman.all;         	-- for extracting configuration parameters from the files
  use SYSTEMS.system_parameter.all;	-- parameters of the current NoC instance
  use SYSTEMS.auxiliary.all;         	-- for extracting configuration parameters from the files

  entity core_interface is
    Generic (
      MY_ID                    : integer := 0;
      Resource_Management_Enable : std_logic := '0';
      SLAVE_TTEL               : std_logic := '0';
      state_bram_enable        : std_logic := '1';
      event_bram_enable        : std_logic := '1';
      NR_PORTS                 : integer := 3;
      RAddrWidth               : natural := 4;
      RWordWidth               : natural := 8;
      WordWidth                : natural := 32
    );
    Port (
       msglen            : out std_logic_vector (10-1 downto 0);
      -- AXI_S (core write) <-> OUT ports
      OUT_WR_EN                : in std_logic;
      OUT_WR_ID                : in t_portid;
      OUT_WR_IDVALID	         : in std_logic;
      OUT_WR_DATA              : in std_logic_vector (WordWidth - 1 downto 0);
      OUT_WR_BFULL             : out std_logic;
      OUT_WR_PFULL             : out std_logic;
      OUT_WR_TERM              : in std_logic;

      -- AXI_S (core read)  <-> In ports
      IN_RD_EN                 : in std_logic;
      IN_RD_ID                 : in t_portid;
      IN_RD_IDVALID    	       : in std_logic;
      IN_RD_DATA               : out std_logic_vector (WordWidth - 1 downto 0);
      IN_RD_BEMPTY             : out std_logic;
      IN_RD_PEMPTY             : out std_logic;
      IN_RD_STATUS  	       : in std_logic;

      -- AXI_M (NoC read)   <-> OUT ports
      OUT_RD_EN                : in std_logic;
      OUT_RD_DATA              : out std_logic_vector (WordWidth - 1 downto 0);
      OUT_RD_BEMPTY            : out std_logic;
      OUT_RD_PEMPTY            : out std_logic;
      OUT_RD_TRIG              : out std_logic;
      OUT_RD_DEST			         : out std_logic_vector (PHYNAME_WIDTH - 1 downto 0);
      --abc			         : out std_logic_vector (128 - 1 downto 0);

      -- AXI_S (NoC write)  <-> In ports
      IN_WR_DATA               : in std_logic_vector (WordWidth - 1 downto 0);
      IN_WR_ID                 : in t_portid;
      IN_WR_IDVALID            : in std_logic;
      IN_WR_EN                 : in std_logic;
      IN_WR_BFULL              : out std_logic;
      IN_WR_PFULL              : out std_logic;
      IN_WR_TERM               : in std_logic;

      -- EBU side:
      pTTDeqIn                 : in std_logic;
      pTTPortId                : in t_portid;
      pETDeqIn                 : in std_logic;
      pETOpId                  : in std_logic_vector (OPID_WIDTH - 1 downto 0);

      pAxiTxDone                : in std_logic;
      pIntToCore                : out std_logic;
      pBypassLetIt              : out std_logic;

      --RMI and MON_port
      monp_data                 : in std_logic_vector (WordWidth - 1 downto 0);
      monp_addr			: in std_logic_vector (8 downto 0); -- last address is 0x111, hence 9 bits
      monp_enq                  : in std_logic;
      monp_term                 : in std_logic;

      -- RMI and ERR_port
      errp_data                 : in std_logic_vector (WordWidth - 1 downto 0);
      errp_enq                  : in std_logic;
      errp_term                 : in std_logic;

      --RMI and CONF_port
      new_conf                  : out  std_logic;
      recp_data                 : out  std_logic_vector (WordWidth - 1 downto 0);
      recp_deq                  : in std_logic;

      -- status.rmi <-> ports
      status_data               : out  std_logic_vector (31 downto 0);
      status_port_id            : in t_portid;

      -- err.rmi <-> ports
--     send_error                : in std_logic_vector (NR_PORTS - 1 downto 0);
        send_error_id           : in t_portid;
      error_flags               : out  std_logic_vector (NR_PORTS - 1 downto 0);
      error_data                : out  std_logic_vector (31 downto 0);

      -- reconf.rmi <-> ports
--      reconf_port_sel           : in std_logic_vector (NR_PORTS - 1 downto 0);
      reconf_data               : in std_logic_vector (15 downto 0);
    reconf_port_id  : in t_portid;

      pTimeCnt                  : in t_timeformat;
      reset_n                   : in std_logic;
      clk                       : in std_logic
    );
  end core_interface;

  architecture Behavioral of core_interface is

--	constant NR_PORTS						    : integer		:= CONF_NR_PORTS (MY_ID);
	constant NR_OUT_PORTS						: integer		:= CONF_NR_OUT_PORTS (MY_ID);
	constant NR_IN_PORTS						: integer		:= NR_PORTS - NR_OUT_PORTS;
	constant CONF_PCFG              : at_pcfg := ttel_pcfg (PROJECT_PATH & INITDIR, "port.cfg", MY_ID);--port
    










  component ent_port
    Generic (
      PORT_ID         : integer := 0;
      state_bram_enable     : std_logic := '1';
      event_bram_enable     : std_logic := '1';
      MY_CONFIG       : rt_pcfg;
      WordWidth       : natural := 32;
      BRAM_ADDR_WIDTH   : natural := 10;
      RWordWidth      : natural := 8
    );
    Port (
      clk             : in std_logic;
      reset_n         : in std_logic;
      pTimeCnt        : in t_timeformat;
      enq             : in std_logic;
      terminate       : in std_logic;
      wr_addr_en      : in std_logic;
      
       msglen            : out std_logic_vector (BRAM_ADDR_WIDTH-1 downto 0);

--      wr_addr		  : in std_logic_vector (9 - 1 downto 0);
      wr_addr		 : in std_logic_vector (clogb2 (MY_CONFIG.CONF_BUF_SIZ - 1) - 1 downto 0);
      qin             : in std_logic_vector (WordWidth - 1 downto 0);
      full            : out std_logic;
      newMsg          : out std_logic;
      bFull           : out std_logic;
      deq             : in std_logic;
      rd_addr_en	  : in std_logic;
      rd_addr		  : in std_logic_vector (clogb2 (MY_CONFIG.CONF_BUF_SIZ - 1) - 1 downto 0);
      qout            : out std_logic_vector (WordWidth - 1 downto 0);
      empty           : out std_logic;
      bEmpty          : out std_logic;
      -- err.rmi <-> port ports
--      send_error      : in std_logic;
      send_error_id   : in t_portid;
      error_id        : out std_logic;
      error_data      : out std_logic_vector (31 downto 0);

      -- status.rmi <-> port ports
      status_data     : out  std_logic_vector (31 downto 0);
      status_port_id  : in t_portid;
      rd_s            : in std_logic;

      -- reconf.rmi <-> port ports
      reconf_data       : in std_logic_vector (15 downto 0);
      reconf_port_id    : in t_portid;
--      reconf_port_sel : in std_logic;
      myType          : out t_porttype;
      -- myId            : out t_portid;
      destination   : out t_phyname
    );
  end component;

  component outportdequnit
   generic
    (
      NR_OUT_PORTS      : integer
    );
    port
    (
      pTTDeqEbu             : in std_logic;
      pTTPortIdEbu          : in t_portid;
      pETDeqEbu             : in std_logic;
      pETOpIdEbu            : in t_opid;
      pAxiTxDone            : in std_logic;
      pOUTPortEmpty         : in std_logic_vector (NR_OUT_PORTS - 1 downto 0);
      pOUTBufferFull        : in std_logic_vector (NR_OUT_PORTS - 1 downto 0);
      pPortType             : in vt_porttype (NR_OUT_PORTS - 1 downto 0);
      -- pPortDeqEn            : out std_logic_vector (NR_OUT_PORTS - 1 downto 0);
      pTrigAxiOut           : out std_logic;
      pOUTPortId            : out t_portid;
      pBypassLetIt            : out std_logic;
      -- pError              : out t_errorid;
      clk                   : in std_logic;
      reset_n               : in std_logic
    );
  end component;

  component int_gen
    generic (
      NR_OUT_PORTS              : integer;
      NR_IN_PORTS               : integer
    );
    port (
      interrupt2core            : out std_logic;
      portIdCore                : out t_portid;
      newMsg                    : in std_logic_vector (NR_IN_PORTS - 1 downto 0);
      clk                       : in std_logic;
      reset_n                   : in std_logic
    );
  end component;


    type data_line_type is array (integer range <>) of std_logic_vector (WordWidth - 1 downto 0); -- todo: can be seperated for input and output ports.
    type addr_line_type is array (integer range <>) of std_logic_vector (MAX_BUFSIZ_WIDTH - 1 downto 0);
    type data16_line_type is array (integer range <>) of std_logic_vector (15 downto 0); -- todo: can be seperated for input and output ports.

    type mc_addr_line_type is array (integer range <>) of t_phyname;
    -- type ptype_artype   is array (integer range <>) of t_porttype;
    type control_line_type is array (integer range <>) of std_logic;
    type pcs_data_line_type is array (0 to NR_PORTS - 1) of std_logic_vector (RWordWidth - 1 downto 0);
    type pc_addr_line_type is array (0 to NR_PORTS - 1) of std_logic_vector (RAddrWidth - 1 downto 0);
    type ps_addr_line_type is array (0 to NR_PORTS - 1) of std_logic_vector (RAddrWidth - 1 downto 0);
    -- type control_line_type2 is array (integer range <>) of std_logic;
    type at_output is array (0 to 15) of std_logic_vector (7 downto 0);
    type at_output_bit is array (0 to 100) of std_logic;
    --chen
    type msglen_set is array (integer range <>) of std_logic_vector (10 - 1 downto 0);

    signal wOUTPortDestAddr : mc_addr_line_type (NR_OUT_PORTS - 1 downto 0);
    signal wOUTPortType     : vt_porttype (NR_OUT_PORTS - 1 downto 0);
    signal wmsglen  :msglen_set(NR_OUT_PORTS - 1 downto 0);
    signal wOUTPortEnq      : control_line_type (NR_OUT_PORTS - 1 downto 0);
    signal wOUTPortQIn      : std_logic_vector (WordWidth - 1 downto 0);
    signal wINPortEnq       : control_line_type (NR_PORTS - 1 downto NR_OUT_PORTS);
    signal wINPortQIn       : std_logic_vector (WordWidth - 1 downto 0);

    signal wOUTPortDeq      : control_line_type (NR_OUT_PORTS - 1 downto 0);
    signal wOUTPortQOut     : data_line_type (NR_OUT_PORTS - 1 downto 0);
    signal wINPortDeq       : control_line_type (NR_PORTS - 1 downto NR_OUT_PORTS);
    signal wINPortQOut      : data_line_type (NR_PORTS - 1 downto NR_OUT_PORTS);


    signal wOUTBuffFull     : control_line_type (NR_OUT_PORTS - 1 downto 0);
    signal wOUTPortFull     : control_line_type (NR_OUT_PORTS - 1 downto 0);
    signal wOUTBuffEmpty    : control_line_type (NR_OUT_PORTS - 1 downto 0);
    signal wOUTPortEmpty    : control_line_type (NR_OUT_PORTS - 1 downto 0);
   -- signal wOUTPortEmpty1    : control_line_type (NR_OUT_PORTS - 1 downto 0):= (others => '0');
    signal wINBuffEmpty     : control_line_type (NR_PORTS - 1 downto NR_OUT_PORTS);
    signal wINPortEmpty     : control_line_type (NR_PORTS - 1 downto NR_OUT_PORTS);
    signal wINBuffFull      : control_line_type (NR_PORTS - 1 downto NR_OUT_PORTS);
    signal wINPortFull      : control_line_type (NR_PORTS - 1 downto NR_OUT_PORTS);
    signal wINPortStatRd    : control_line_type (NR_PORTS - 1 downto NR_OUT_PORTS);
    signal wOUTPortStatRd   : control_line_type (NR_OUT_PORTS - 1 downto 0);
    
    signal wPortRdEn        : control_line_type (NR_PORTS - 1 downto 0);
--    signal wPportRdAddr     : pc_addr_line_type;
    signal wPportRdData     : pcs_data_line_type;

-- for address based port access
	signal wWrAddrEn		: control_line_type (NR_PORTS - 1 downto 0);
	signal wRdAddrEn		: control_line_type (NR_PORTS - 1 downto 0);
    signal wPortRdAddr      : addr_line_type (NR_PORTS - 1 downto 0);
    signal wPortWrAddr      : addr_line_type (NR_PORTS - 1 downto 0);


    signal rWrOutPortIdCore      : integer:= 0;
    signal rRdOutPortIdNoC       : integer:= 0;
    signal rWrInPortIdNoC        : integer:= NR_OUT_PORTS;
    signal rRdInPortIdCore       : integer:= NR_OUT_PORTS;

    signal wOUTPortId       : t_portid;
    signal wTrigAxiOut      : std_logic;

    -- wire signals between the ports and the RMI
    -- -- error signals
--    signal wSendError       : control_line_type (NR_PORTS - 1 downto 0);
    signal wErrorFlag       : control_line_type (NR_PORTS - 1 downto 0);
    -- signal error_data       : data_line_type (NR_PORTS - 1 downto 0);
    -- -- status signals
    -- -- reconf. signals
    signal wReconfPortSel      : control_line_type (NR_PORTS - 1 downto 0);
    -- signal wConfigData      : std_logic_vector (31 downto 0); -- data16_line_type (NR_PORTS - 1 downto 0);

    signal wTimeCnt         : t_timeformat;
    signal wNewMsg          : std_logic_vector (NR_PORTS - 1 downto 0);
   
    signal port_config_data_reg : std_logic_vector (128 - 1 downto 0);
  begin

    error_flags <= std_logic_vector (wErrorFlag);

----by Darshak  this  process fetches data from the port configuration memory 
process(pTTDeqIn)
begin
if (falling_edge(pTTDeqIn)) then
port_config_data_reg <=CONF_PCFG(to_integer(unsigned(pTTPortId)));
end if;
end process;




RMS_Disable: if Resource_Management_Enable = '0'
generate
      out_ports: for port_id in 0 to NR_OUT_PORTS - 1
      generate
        output_port_inst: entity work.ent_port(safepower)
        generic map (
          MY_CONFIG => map_pcfg (CONF_PCFG (port_id)),
          state_bram_enable => state_bram_enable,
          event_bram_enable => event_bram_enable,
          PORT_ID => port_id
        )
        port map (
          clk => clk,
          reset_n => reset_n,
          pTimeCnt => wTimeCnt,
          enq => wOUTPortEnq (port_id),
           msglen=>wmsglen(port_id),
          wr_addr_en => '0',
          wr_addr => (others => '0'),
          rd_addr_en => '0',
          rd_addr => (others => '0'),
          terminate => OUT_WR_TERM,
          qin => wOUTPortQIn,
          full => wOUTPortFull (port_id),
          bFull => wOUTBuffFull (port_id),
          newMsg => wNewMsg (port_id),
          deq => wOUTPortDeq (port_id),
          rd_s => wOUTPortStatRd (port_id),
          qout => wOUTPortQOut (port_id),
          empty => wOUTPortEmpty (port_id),
          bEmpty => wOUTBuffEmpty (port_id),
        send_error_id => send_error_id,
          error_flag => wErrorFlag (port_id),
          error_data => error_data,
          status_data => status_data,
          status_port_id => status_port_id,
          reconf_data => reconf_data,
          reconf_port_id => reconf_port_id,
          myType => wOUTPortType (port_id),
          -- myId => wOUTPortId (port_id),
          destination => wOUTPortDestAddr (port_id)
        );
        --enqvv (port_id) <= std_logic_vector (to_unsigned (port_id + 1, 20));
      end generate;

      -- generate loop to generate input ports
      in_ports: for port_id in NR_OUT_PORTS to NR_PORTS - 1
      generate
        input_port_inst: entity work.ent_port(safepower)
        generic map (
          MY_CONFIG => map_pcfg (CONF_PCFG (port_id)),
          state_bram_enable => state_bram_enable,
          event_bram_enable => event_bram_enable,
          PORT_ID => port_id
        )
        port map (
          clk => clk,
          reset_n => reset_n,
          pTimeCnt => wTimeCnt,
          -- enq => wPortEnq (port_id),
          enq => wINPortEnq (port_id),
          wr_addr_en => '0',
          wr_addr => (others => '0'),
          rd_addr_en => '0',
          rd_addr => (others => '0'),
          terminate => IN_WR_TERM,
          qin => wINPortQIn,
          deq => wINPortDeq (port_id),
          rd_s => wINPortStatRd (port_id),
          qout => wINPortQout (port_id),
          newMsg => wNewMsg (port_id),
          bFull => wINBuffFull (port_id),
          full => wINPortFull (port_id),
          bEmpty => wINBuffEmpty(port_id),
          empty => wINPortEmpty(port_id),
        send_error_id => send_error_id,
          error_flag => wErrorFlag (port_id),
          error_data => error_data,
          status_data => status_data,
          status_port_id => status_port_id,
          reconf_data => reconf_data,
          reconf_port_id => reconf_port_id
        );
      end generate;
end generate;



RMS_Enable: if Resource_Management_Enable = '1'
generate
    -- generate loop to generate output ports for a master TTEL
    master_ttel_ports: if SLAVE_TTEL = '0'
    generate
    wNewMsg (0) <= '0'; 		-- as the RECP is placed in Port#0 and newMsg for RECP means new reconfiguration
      -- instantiation of the RECP
      recp_master: entity work.ent_port(safepower)
      generic map (
        MY_CONFIG => map_pcfg (CONF_PCFG (0)),
        state_bram_enable => state_bram_enable,
        event_bram_enable => event_bram_enable,
        PORT_ID => 0
      )
      port map (
        clk => clk,
        reset_n => reset_n,
        pTimeCnt => wTimeCnt,
        enq => wOUTPortEnq (0),
        wr_addr_en => '0',
        wr_addr => (others => '0'),
        rd_addr_en => '0',
        rd_addr => (others => '0'),
        terminate => OUT_WR_TERM,
        qin => wOUTPortQIn,
        full => wOUTPortFull (0),
        bFull => wOUTBuffFull (0),
        rd_s => wOUTPortStatRd (0),   -- TODO: shall we remove rd_s??
        newMsg => new_conf,
        deq => recp_deq,
        qout => recp_data,
        empty => wOUTPortEmpty (0),
        bEmpty => wOUTBuffEmpty (0),
        send_error_id => send_error_id,
        error_flag => wErrorFlag (0),
        error_data => error_data,
        status_data => status_data,
        status_port_id => status_port_id,
        reconf_data => reconf_data,
        reconf_port_id => reconf_port_id,
        myType => wOUTPortType (0),
        -- myId => wOUTPortId (0),
        destination => wOUTPortDestAddr (0)
      );

      out_ports_m: for port_id in 1 to NR_OUT_PORTS - 1
      generate
        output_port_master_inst: entity work.ent_port(safepower)
        generic map (
          MY_CONFIG => map_pcfg (CONF_PCFG (port_id)),
          state_bram_enable => state_bram_enable,
          event_bram_enable => event_bram_enable,
          PORT_ID => port_id
        )
        port map (
          clk => clk,
          reset_n => reset_n,
          pTimeCnt => wTimeCnt,
          enq => wOUTPortEnq (port_id),
          wr_addr_en => '0',
          wr_addr => (others => '0'),
          rd_addr_en => '0',
          rd_addr => (others => '0'),
          terminate => OUT_WR_TERM,
          qin => wOUTPortQIn,
          full => wOUTPortFull (port_id),
          bFull => wOUTBuffFull (port_id),
          newMsg => wNewMsg (port_id),
          deq => wOUTPortDeq (port_id),
          rd_s => wOUTPortStatRd (port_id),
          qout => wOUTPortQOut (port_id),
          empty => wOUTPortEmpty (port_id),
          bEmpty => wOUTBuffEmpty (port_id),
        send_error_id => send_error_id,
          error_flag => wErrorFlag (port_id),
          error_data => error_data,
          status_data => status_data,
          status_port_id => status_port_id,
          reconf_data => reconf_data,
          reconf_port_id => reconf_port_id,
          myType => wOUTPortType (port_id),
          -- myId => wOUTPortId (port_id),
          destination => wOUTPortDestAddr (port_id)
        );
        --enqvv (port_id) <= std_logic_vector (to_unsigned (port_id + 1, 20));
      end generate;

      -- generate loop to generate input ports
      in_ports_m: for port_id in NR_OUT_PORTS to NR_PORTS - 3
      generate
        input_port_master_inst: entity work.ent_port(safepower)
        generic map (
          MY_CONFIG => map_pcfg (CONF_PCFG (port_id)),
          state_bram_enable => state_bram_enable,
          event_bram_enable => event_bram_enable,
          PORT_ID => port_id
        )
        port map (
          clk => clk,
          reset_n => reset_n,
          pTimeCnt => wTimeCnt,
          -- enq => wPortEnq (port_id),
          enq => wINPortEnq (port_id),
          wr_addr_en => '0',
          wr_addr => (others => '0'),
          rd_addr_en => '0',
          rd_addr => (others => '0'),
          terminate => IN_WR_TERM,
          qin => wINPortQIn,
          deq => wINPortDeq (port_id),
          rd_s => wINPortStatRd (port_id),
          qout => wINPortQout (port_id),
          newMsg => wNewMsg (port_id),
          bFull => wINBuffFull (port_id),
          full => wINPortFull (port_id),
          bEmpty => wINBuffEmpty(port_id),
          empty => wINPortEmpty(port_id),
        send_error_id => send_error_id,
          error_flag => wErrorFlag (port_id),
          error_data => error_data,
          status_data => status_data,
          status_port_id => status_port_id,
          reconf_data => reconf_data,
          reconf_port_id => reconf_port_id
        );
      end generate;

      -- instantiation of the ERRP
      errp_master: entity work.ent_port(safepower)
      generic map (
        MY_CONFIG => map_pcfg (CONF_PCFG (NR_PORTS - 2)),
        state_bram_enable => state_bram_enable,
        event_bram_enable => event_bram_enable,
        PORT_ID => NR_PORTS - 2
      )
      port map (
        clk => clk,
        reset_n => reset_n,
        pTimeCnt => wTimeCnt,
        qin => errp_data,
        enq => errp_enq,
        wr_addr_en => '0',
        wr_addr => (others => '0'),
        rd_addr_en => '0',
        rd_addr => (others => '0'),
        terminate => errp_term,
        deq => wINPortDeq (NR_PORTS - 2),
        rd_s => wINPortStatRd (NR_PORTS - 2),
        qout => wINPortQout (NR_PORTS - 2),
        newMsg => wNewMsg (NR_PORTS - 2),
        bFull => wINBuffFull (NR_PORTS - 2),
        full => wINPortFull (NR_PORTS - 2),
        bEmpty => wINBuffEmpty(NR_PORTS - 2),
        empty => wINPortEmpty(NR_PORTS - 2),
        send_error_id => send_error_id,
        error_flag => wErrorFlag (NR_PORTS - 2),
        error_data => error_data,
        status_data => status_data,
        status_port_id => status_port_id,
        reconf_data => reconf_data,
        reconf_port_id => reconf_port_id

      );

      -- instantiation of the MONP
      monp_master: entity work.ent_port(safepower)
      generic map (
        MY_CONFIG => map_pcfg (CONF_PCFG (NR_PORTS - 1)),
        state_bram_enable => state_bram_enable,
        event_bram_enable => event_bram_enable,
        PORT_ID => NR_PORTS - 1
      )
      port map (
        clk => clk,
        reset_n => reset_n,
        pTimeCnt => wTimeCnt,
        wr_addr_en => '1',
        wr_addr => monp_addr,
        rd_addr_en => '0',		-- todo: AXI_S should be able to read address based
        rd_addr => (others => '0'),
        qin => monp_data,
        enq => monp_enq,
        terminate => monp_term,
        deq => wINPortDeq (NR_PORTS - 1),
        rd_s => wINPortStatRd (NR_PORTS - 1),
        qout => wINPortQout (NR_PORTS - 1),
        newMsg => wNewMsg (NR_PORTS - 1),
        bFull => wINBuffFull (NR_PORTS - 1),
        full => wINPortFull (NR_PORTS - 1),
        bEmpty => wINBuffEmpty(NR_PORTS - 1),
        empty => wINPortEmpty(NR_PORTS - 1),
        send_error_id => send_error_id,
        error_flag => wErrorFlag (NR_PORTS - 1),
        error_data => error_data,
        status_data => status_data,
        status_port_id => status_port_id,
        reconf_data => reconf_data,
        reconf_port_id => reconf_port_id
      );
    end generate;


    -- generate loop to generate output ports for a slave TTEL
    slave_ttel_ports: if SLAVE_TTEL = '1'
    generate
      -- instantiation of the MONP
      monp_slave: entity work.ent_port(safepower)
      generic map (
        MY_CONFIG => map_pcfg (CONF_PCFG (0)),
        state_bram_enable => state_bram_enable,
        event_bram_enable => event_bram_enable,
        PORT_ID => 0
      )
      port map (
        clk => clk,
        reset_n => reset_n,
        pTimeCnt => wTimeCnt,
        qin => monp_data,
        enq => monp_enq,
        wr_addr_en => '1',
        wr_addr => monp_addr,
        rd_addr_en => '0',
        rd_addr => (others => '0'),
        terminate => monp_term,
        deq => wOUTPortDeq (0),
        rd_s => wOUTPortStatRd (0),
        qout => wOUTPortQout (0),
        newMsg => wNewMsg (0),
        bFull => wOUTBuffFull (0),
        full => wOUTPortFull (0),
        bEmpty => wOUTBuffEmpty(0),
        empty => wOUTPortEmpty(0),
        send_error_id => send_error_id,
        error_flag => wErrorFlag (0),
        error_data => error_data,
        status_data => status_data,
        status_port_id => status_port_id,
        reconf_data => reconf_data,
        reconf_port_id => reconf_port_id,
        myType => wOUTPortType (0),
        -- myId => wOUTPortId (port_id),
        destination => wOUTPortDestAddr (0)

      );
      -- instantiation of the ERRP
      errp_slave: entity work.ent_port(safepower)
      generic map (
        MY_CONFIG => map_pcfg (CONF_PCFG (1)),
        state_bram_enable => state_bram_enable,
        event_bram_enable => event_bram_enable,
        PORT_ID => 1
      )
      port map (
        clk => clk,
        reset_n => reset_n,
        pTimeCnt => wTimeCnt,
        qin => errp_data,
        enq => errp_enq,
        terminate => errp_term,
        wr_addr_en => '0',
        wr_addr => (others => '0'),
        rd_addr_en => '0',
        rd_addr => (others => '0'),
        deq => wOUTPortDeq (1),
        rd_s => wOUTPortStatRd (1),
        qout => wOUTPortQout (1),
        newMsg => wNewMsg (1),
        bFull => wOUTBuffFull (1),
        full => wOUTPortFull (1),
        bEmpty => wOUTBuffEmpty(1),
        empty => wOUTPortEmpty(1),
        send_error_id => send_error_id,
        error_flag => wErrorFlag (1),
        error_data => error_data,
        status_data => status_data,
        status_port_id => status_port_id,
        reconf_data => reconf_data,
        reconf_port_id => reconf_port_id,
        myType => wOUTPortType (1),
        -- myId => wOUTPortId (port_id),
        destination => wOUTPortDestAddr (1)
      );

      out_ports_s: for port_id in 2 to NR_OUT_PORTS - 1
      generate
        output_port_slave_inst: entity work.ent_port(safepower)
        generic map (
          MY_CONFIG => map_pcfg (CONF_PCFG (port_id)),
          state_bram_enable => state_bram_enable,
          event_bram_enable => event_bram_enable,
          PORT_ID => port_id
        )
        port map (
          clk => clk,
          reset_n => reset_n,
          pTimeCnt => wTimeCnt,
          enq => wOUTPortEnq (port_id),
          terminate => OUT_WR_TERM,
          wr_addr_en => '0',
          wr_addr => (others => '0'),
          rd_addr_en => '0',
          rd_addr => (others => '0'),
          qin => wOUTPortQIn,
          full => wOUTPortFull (port_id),
          bFull => wOUTBuffFull (port_id),
          newMsg => wNewMsg (port_id),
          deq => wOUTPortDeq (port_id),
          rd_s => wOUTPortStatRd (port_id),
          qout => wOUTPortQOut (port_id),
          empty => wOUTPortEmpty (port_id),
          bEmpty => wOUTBuffEmpty (port_id),
        send_error_id => send_error_id,
          error_flag => wErrorFlag (port_id),
          error_data => error_data,
          status_data => status_data,
          status_port_id => status_port_id,
          reconf_data => reconf_data,
          reconf_port_id => reconf_port_id,
          myType => wOUTPortType (port_id),
          -- myId => wOUTPortId (port_id),
          destination => wOUTPortDestAddr (port_id)
        );
      end generate;

      -- generate loop to generate input ports
      in_ports_s: for port_id in NR_OUT_PORTS to NR_PORTS - 2
      generate
        input_port_slave_inst: entity work.ent_port(safepower)
        generic map (
          MY_CONFIG => map_pcfg (CONF_PCFG (port_id)),
          state_bram_enable => state_bram_enable,
          event_bram_enable => event_bram_enable,
          PORT_ID => port_id
        )
        port map (
          clk => clk,
          reset_n => reset_n,
          pTimeCnt => wTimeCnt,
          -- enq => wPortEnq (port_id),
          enq => wINPortEnq (port_id),
          wr_addr_en => '0',
          wr_addr => (others => '0'),
          rd_addr_en => '0',
          rd_addr => (others => '0'),
          terminate => IN_WR_TERM,
          qin => wINPortQIn,
          deq => wINPortDeq (port_id),
          rd_s => wINPortStatRd (port_id),
          qout => wINPortQout (port_id),
          newMsg => wNewMsg (port_id),
          bFull => wINBuffFull (port_id),
          full => wINPortFull (port_id),
          bEmpty => wINBuffEmpty(port_id),
          empty => wINPortEmpty(port_id),
        send_error_id => send_error_id,
          error_flag => wErrorFlag (port_id),
          error_data => error_data,
          status_data => status_data,
          status_port_id => status_port_id,
          reconf_data => reconf_data,
          reconf_port_id => reconf_port_id
        );
      end generate;
      -- instantiation of the RECP
      wNewMsg (NR_PORTS - 1) <= '0'; 		-- as the RECP is placed in Port#(NR_PORTS - 1) and newMsg for RECP means new reconfiguration

      recp_s: entity work.ent_port(safepower)
      generic map (
        MY_CONFIG => map_pcfg (CONF_PCFG (NR_PORTS - 1)),
        state_bram_enable => state_bram_enable,
        event_bram_enable => event_bram_enable,
        PORT_ID => NR_PORTS - 1
      )
      port map (
        clk => clk,
        reset_n => reset_n,
        pTimeCnt => wTimeCnt,
        enq => wINPortEnq (NR_PORTS - 1),
        terminate => OUT_WR_TERM,
        wr_addr_en => '0',
        wr_addr => (others => '0'),
        rd_addr_en => '0',
        rd_addr => (others => '0'),
        qin => wINPortQIn,
        full => wINPortFull (NR_PORTS - 1),
        bFull => wINBuffFull (NR_PORTS - 1),
        newMsg => new_conf,
        deq => recp_deq,
        qout => recp_data,
        rd_s => wINPortStatRd (NR_PORTS - 1),
        empty => wINPortEmpty (NR_PORTS - 1),
        bEmpty => wINBuffEmpty (NR_PORTS - 1),
        send_error_id => send_error_id,
        error_flag => wErrorFlag (NR_PORTS - 1),
        error_data => error_data,
        status_data => status_data,
        status_port_id => status_port_id,
        reconf_data => reconf_data,
        reconf_port_id => reconf_port_id
        -- myId => wOUTPortId (NR_PORTS - 1),
      );

    end generate;
end generate;

    OUTPortDQU_inst: outportdequnit
    generic map (
        NR_OUT_PORTS => NR_OUT_PORTS
    )
    port map (
      pTTDeqEbu => pTTDeqIn,
      pTTPortIdEbu => pTTPortId,
      pETDeqEbu => pETDeqIn,
      pETOpIdEbu => pETOpId,
      pAxiTxDone => pAxiTxDone,
      pBypassLetIt => pBypassLetIt,
      pOUTPortEmpty => std_logic_vector (wOUTPortEmpty),
      pOUTBufferFull => wNewMsg (NR_OUT_PORTS - 1 downto 0),
--      pOUTBufferFull => std_logic_vector (wOUTBuffFull),
      pPortType => wOUTPortType,
      -- pPortDeqEn => wOUTPortDeq,
      pTrigAxiOut => wTrigAxiOut,
      pOUTPortId => wOUTPortId,
      -- => ,
      clk => clk,
      reset_n => reset_n
    );

    int_gen_inst: int_gen
    generic map (
      NR_OUT_PORTS => NR_OUT_PORTS,
      NR_IN_PORTS => NR_IN_PORTS
    )
    port map (
      interrupt2core => pIntToCore,
      -- portIdCore => ,
      newMsg => wNewMsg (NR_PORTS - 1 downto NR_OUT_PORTS),
      clk => clk,
      reset_n => reset_n
    );

    -- process for IN_RD_STATUS
    process (reset_n, IN_RD_STATUS, rRdInPortIdCore)
    begin
      if reset_n = '0' or IN_RD_STATUS = '0' then
        wINPortStatRd <= (others => '0');
      else
        wINPortStatRd (rRdInPortIdCore) <= IN_RD_STATUS;   --transmitt the states into port
      end if;
    end process;

    -- process for portIdCore capture
    process (clk)
    begin
      if rising_edge (clk) then
  	    if reset_n = '0' then
  	      rWrOutPortIdCore <= 0;
        else
          if OUT_WR_IDVALID = '1' then
            rWrOutPortIdCore <= to_integer (unsigned (OUT_WR_ID));
          end if;
        end if;
      end if;
    end process;

    -- process for pTTPortId capture
    process (clk)
    begin
      if rising_edge (clk) then
  	    if reset_n = '0' then
  	      rRdOutPortIdNoC <= 1;
        else
          if wTrigAxiOut = '1' then
            rRdOutPortIdNoC <= to_integer (unsigned (wOUTPortId));
          end if;
        end if;
      end if;
    end process;

    -- process for IN_WR_ID capture
    process (clk)
    begin
      if rising_edge (clk) then
  	    if reset_n = '0' then
  	      rWrInPortIdNoC <= NR_OUT_PORTS;
        else
          if IN_WR_IDVALID = '1' then
            rWrInPortIdNoC <= to_integer (unsigned (IN_WR_ID));
          end if;
        end if;
      end if;
    end process;

    -- process for IN_RD_ID capture
    process (clk)
    begin
      if rising_edge (clk) then
  	    if reset_n = '0' then
  	      rRdInPortIdCore <= NR_OUT_PORTS;
        else
          if IN_RD_IDVALID = '1' then
            rRdInPortIdCore <= to_integer (unsigned (IN_RD_ID));
          end if;
        end if;
      end if;
    end process;

    -- signals connect the AXI_S_Core to the ports
    process (reset_n, rWrOutPortIdCore, OUT_WR_EN)
    variable temp_cntr : integer := 0;
    begin
      if reset_n = '0' then
        wOUTPortEnq <= (others => '0');
      else
        for temp_cntr in 0 to NR_OUT_PORTS - 1 loop
            if temp_cntr = rWrOutPortIdCore then
                wOUTPortEnq (temp_cntr) <= OUT_WR_EN;
            else
                wOUTPortEnq (temp_cntr) <= '0';
            end if;
        end loop;
      end if;
    end process;


    wOUTPortQIn <= OUT_WR_DATA;
    -- signals connect the AXI_M to the ports
    process (reset_n, rRdOutPortIdNoC, OUT_RD_EN)
    variable temp_cntr : integer := 0;
    begin
      if reset_n = '0' then
        wOUTPortDeq <= (others => '0');
      else
        for temp_cntr in 0 to NR_OUT_PORTS - 1 loop
          if temp_cntr = rRdOutPortIdNoC then
            wOUTPortDeq (temp_cntr) <= OUT_RD_EN;
          else
            wOUTPortDeq (temp_cntr) <= '0';
          end if;
        end loop;
      end if;
    end process;

    process (reset_n, rRdInPortIdCore, IN_RD_EN)
    variable temp_cntr : integer := NR_OUT_PORTS;
    begin
      if reset_n = '0' then
        wINPortDeq <= (others => '0');
      else
        for temp_cntr in NR_OUT_PORTS to NR_PORTS - 1 loop
          if temp_cntr = rRdInPortIdCore then
            wINPortDeq (temp_cntr) <= IN_RD_EN;
          else
            wINPortDeq (temp_cntr) <= '0';
          end if;
        end loop;
      end if;
    end process;

    OUT_RD_DATA <= wOUTPortQout (rRdOutPortIdNoC);
    msglen<=wmsglen(rRdOutPortIdNoC);
    -- signals connect the AXI_S_NoC to input ports

    process (reset_n, rWrInPortIdNoC, IN_WR_EN)
    variable temp_cntr : integer := NR_OUT_PORTS;
    begin
      if reset_n = '0' then
        wINPortEnq <= (others => '0');
      else
        for temp_cntr in NR_OUT_PORTS to NR_PORTS - 1 loop
          if temp_cntr = rWrInPortIdNoC then
            wINPortEnq (temp_cntr) <= IN_WR_EN;
          else
            wINPortEnq (temp_cntr) <= '0';
          end if;
        end loop;
      end if;
    end process;

    wINPortQIn <= IN_WR_DATA;

    IN_RD_DATA <= wINPortQout (rRdInPortIdCore);

    OUT_RD_DEST <=port_config_data_reg(95 downto 64);

    OUT_WR_BFULL <= wOUTBuffFull (rWrOutPortIdCore);
    OUT_WR_PFULL <= wOUTPortFull (rWrOutPortIdCore);
    OUT_RD_BEMPTY <= wOUTBuffEmpty (rRdOutPortIdNoC);
    OUT_RD_PEMPTY <= wOUTPortEmpty (rRdOutPortIdNoC);

    IN_WR_BFULL <= wINBuffFull (rWrInPortIdNoC);
    IN_WR_PFULL <= wINPortFull (rWrInPortIdNoC);
    IN_RD_BEMPTY <= wINBuffEmpty (rRdInPortIdCore);
    IN_RD_PEMPTY <= wINPortEmpty (rRdInPortIdCore);

    wTimeCnt <= pTimeCnt;
    OUT_RD_TRIG <= wTrigAxiOut;

  end Behavioral;
