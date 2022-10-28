library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library SAFEPOWER;
use SAFEPOWER.TTEL.all;        		-- constants, datatypes, and component declarations of the current TTEL
--use SAFEPOWER.stnoc_parameter.all;	-- for AXI parameters
use SAFEPOWER.ttel_parameter.all;	-- NR_PORTS2

library SYSTEMS;
use SYSTEMS.configman.all;         	-- for extracting configuration parameters from the files
use SYSTEMS.system_parameter.all;	-- parameters of the current NoC instance


entity TTEL is
	generic (
        MY_ID                     : integer := 0;
        MY_VNET                   : integer := 1;
        Resource_Management_Enable : std_logic := '0';
        state_bram_enable         : std_logic := '0';
        event_bram_enable         : std_logic := '0';
        EVENT_TRIGGERED_ENABLE    : integer := 0;
        NoC_Slave_AXI_Enable      : std_logic := '1';
        SLAVE_TTEL			      : std_logic := '0';
		MUX_READ_WAIT_CNTR        : integer := 32;
        CI_WORDWIDTH              : natural := 32;
        NOS_NR_OUT_CH             : integer := 2; 
        NOS_OUT_CH_PORT           : integer := 1; 
        Nos_LENGTH_RD             : integer    := 1;
        -- generics for write channels
        C_NOS_BASE_ADDR           : std_logic_vector := x"70000000";
         
		NOS_WR_CH0_BASE_ADD               : std_logic_vector := x"00028400";
        NOS_WR_CH1_BASE_ADD               : std_logic_vector := x"00028200";
        NOS_WR_CH2_BASE_ADD               : std_logic_vector := x"00028000";
        --NOS_WR_CH3_BASE_ADD               : std_logic_vector := x"00028000";
        
        NOS_WR_TRIG_ADD                   : std_logic_vector := x"00020000";
        --NOS_WR_TRIG_ADD_CH0               : std_logic_vector := x"00020000";
        --NOS_WR_TRIG_ADD_CH1               : std_logic_vector := x"00020000";
        --NOS_WR_TRIG_ADD_CH2               : std_logic_vector := x"00020000";
        --NOS_WR_TRIG_ADD_CH3               : std_logic_vector := x"00020000"; 
        
        NOS_WR_TRIG_VAL_CH0               : std_logic_vector := x"00002000";
        NOS_WR_TRIG_VAL_CH1               : std_logic_vector := x"00001000";
        NOS_WR_TRIG_VAL_CH2               : std_logic_vector := x"00000000";
        --NOS_WR_TRIG_VAL_CH3               : std_logic_vector := x"00000025";
        
        
        --NOS_WR_TRIG_ADD           : std_logic_vector := x"00020000"; 
        --NOS_WR_TRIG_VAL           : std_logic_vector := x"00000009";
        -- generics for read channels
        rChEmpty                  : std_logic_vector(3 downto 0):="1111" ;
        NOS_NR_IN_CH              : integer := 1;
        NOS_IN_CH_PORT            : integer := 7;
        NOS_RD_CH0_BASE_ADD       : std_logic_vector := x"00030400";
        NOS_RD_CH1_BASE_ADD       : std_logic_vector := x"00030200";
        NOS_RD_CH2_BASE_ADD       : std_logic_vector := x"00030000";
        --NOS_RD_CH3_BASE_ADD       : std_logic_vector := x"00030010";  
        NOS_RD_CH_SIZE            : integer := 16;



		-- Parameters of Axi Slave Bus Interface S_AXI
		C_PORTS_BASE_ADDR	      : std_logic_vector	:= x"40000000";
		C_CORE_AXI_ID_WIDTH			: integer	:= 6;
		C_CORE_AXI_DATA_WIDTH		: integer	:= 32;
		C_CORE_AXI_ADDR_WIDTH		: integer	:= 32;
		C_CORE_AXI_AWUSER_WIDTH	: integer	:= 1;
		C_CORE_AXI_ARUSER_WIDTH	: integer	:= 1;
		C_CORE_AXI_WUSER_WIDTH	: integer	:= 1;
		C_CORE_AXI_RUSER_WIDTH	: integer	:= 1;
		C_CORE_AXI_BUSER_WIDTH	: integer	:= 1;
		-- Parameters of Axi Master Bus Interface M_AXI
		C_NOC_AXI_BURST_LEN			: integer	:= 16;
		C_NOC_AXI_ID_WIDTH			: integer	:= 6;
		C_NOC_AXI_ID_BASE				: integer := 0;
		C_NOC_AXI_ADDR_WIDTH		: integer	:= 32;
		C_NOC_AXI_DATA_WIDTH		: integer	:= 32;
		C_NOC_AXI_AWUSER_WIDTH	: integer	:= 1;
		C_NOC_AXI_ARUSER_WIDTH	: integer	:= 1;
		C_NOC_AXI_WUSER_WIDTH		: integer	:= 1;
		C_NOC_AXI_RUSER_WIDTH		: integer	:= 1;
		C_NOC_AXI_BUSER_WIDTH		: integer	:= 1;
		WordWidth                   : integer:=32 -- for source
	);   
	port (
	   --from noc ready signal(caore interface write into noc)
	   out_rd_en :in std_logic;
	  --EBU OUT
	    trigger   : out std_logic; --come from EBU DEQOUT
	    trigger2   : out std_logic;--msglen transmit
	    source_datain: out std_logic_vector (WordWidth - 1 downto 0);
	    destination_address:  out std_logic_vector (PHYNAME_WIDTH - 1 downto 0); --going to routing unit
	     msglen            : out std_logic_vector (10-1 downto 0);
	    deq : in std_logic;
	    --for noc write to core interface
	    sink_dataout               : in std_logic_vector (WordWidth - 1 downto 0); --   IN_WR_DATA             -DATA
		sink_portid                 : in t_portid;                                   --     IN_WR_ID               --port_id for seect which port will be used
	    portid_valid            : in std_logic;                                     --    IN_WR_IDVALID         --write port_id enable
		write_en                 : in std_logic;                                    --    IN_WR_EN              --write data enable
		sink_terminate               : in std_logic;                                --    IN_WR_TERM    
		sel                          : in bit ;
		
		       -- tell core interface , currently we have finished transmitting(pulse)
		                                                                                    
		-- clock signals                                                                       
		clk							:	in	std_logic;		-- system operation frequency
		TimeCntIn       			: in std_logic_vector (63 downto 0);
		-- hardware reset wire
		reset_n					    :	in	std_logic;
        pIntToCore                  : out std_logic;
        CoreInterrupt               : out std_logic;
        PeriodIntr                  : out std_logic;
        IntFromNostrum              : in std_logic;
		-- Ports of Axi Slave Bus Interface S_AXI   
--		s_axi_core_aclk				: in std_logic;		-- for future work
--		s_axi_core_aresetn		: in std_logic;		-- for future work
		s_axi_core_awid				: in std_logic_vector(C_CORE_AXI_ID_WIDTH-1 downto 0);
		s_axi_core_awaddr			: in std_logic_vector(C_CORE_AXI_ADDR_WIDTH-1 downto 0);
		s_axi_core_awlen			: in std_logic_vector(7 downto 0);
		s_axi_core_awsize			: in std_logic_vector(2 downto 0);
		s_axi_core_awburst		: in std_logic_vector(1 downto 0);
		s_axi_core_awlock			: in std_logic;
		s_axi_core_awcache		: in std_logic_vector(3 downto 0);
		s_axi_core_awprot			: in std_logic_vector(2 downto 0);
		s_axi_core_awqos			: in std_logic_vector(3 downto 0);
		s_axi_core_awregion		: in std_logic_vector(3 downto 0);
		s_axi_core_awuser			: in std_logic_vector(C_CORE_AXI_AWUSER_WIDTH-1 downto 0);
		s_axi_core_awvalid		: in std_logic;
		s_axi_core_awready		: out std_logic;
		s_axi_core_wdata			: in std_logic_vector(C_CORE_AXI_DATA_WIDTH-1 downto 0);
		s_axi_core_wstrb			: in std_logic_vector((C_CORE_AXI_DATA_WIDTH/8)-1 downto 0);
		s_axi_core_wlast			: in std_logic;
		s_axi_core_wuser			: in std_logic_vector(C_CORE_AXI_WUSER_WIDTH-1 downto 0);
		s_axi_core_wvalid			: in std_logic;
		s_axi_core_wready			: out std_logic;
		s_axi_core_bid				: out std_logic_vector(C_CORE_AXI_ID_WIDTH-1 downto 0);
		s_axi_core_bresp			: out std_logic_vector(1 downto 0);
		s_axi_core_buser			: out std_logic_vector(C_CORE_AXI_BUSER_WIDTH-1 downto 0);
		s_axi_core_bvalid			: out std_logic;
		s_axi_core_bready			: in std_logic;
		s_axi_core_arid				: in std_logic_vector(C_CORE_AXI_ID_WIDTH-1 downto 0);
		s_axi_core_araddr			: in std_logic_vector(C_CORE_AXI_ADDR_WIDTH-1 downto 0);
		s_axi_core_arlen			: in std_logic_vector(7 downto 0);
		s_axi_core_arsize			: in std_logic_vector(2 downto 0);
		s_axi_core_arburst		: in std_logic_vector(1 downto 0);
		s_axi_core_arlock			: in std_logic;
		s_axi_core_arcache		: in std_logic_vector(3 downto 0);
		s_axi_core_arprot			: in std_logic_vector(2 downto 0);
		s_axi_core_arqos			: in std_logic_vector(3 downto 0);
		s_axi_core_arregion		: in std_logic_vector(3 downto 0);
		s_axi_core_aruser			: in std_logic_vector(C_CORE_AXI_ARUSER_WIDTH-1 downto 0);
		s_axi_core_arvalid		: in std_logic;
		s_axi_core_arready		: out std_logic;
		s_axi_core_rid				: out std_logic_vector(C_CORE_AXI_ID_WIDTH-1 downto 0);
		s_axi_core_rdata			: out std_logic_vector(C_CORE_AXI_DATA_WIDTH-1 downto 0);
		s_axi_core_rresp			: out std_logic_vector(1 downto 0);
		s_axi_core_rlast			: out std_logic;
		s_axi_core_ruser			: out std_logic_vector(C_CORE_AXI_RUSER_WIDTH-1 downto 0);
		s_axi_core_rvalid			: out std_logic;
		s_axi_core_rready			: in std_logic ;
		tx_adaptiveRMI : in bit 

	);
end TTEL;


architecture arch_imp of TTEL is

	constant NR_PORTS						    : integer		:= CONF_NR_PORTS (MY_ID);

    

	component core_interface is
	  Generic (
      MY_ID       : integer := 0;
      NR_PORTS                 : integer;
      Resource_Management_Enable : std_logic := '0';
      state_bram_enable     : std_logic := '1';
      event_bram_enable        : std_logic := '1';
      SLAVE_TTEL			   : std_logic := '0';
			RAddrWidth  : natural := 7;  -- Depth of the RAM = 2^AddrWidth
	    RWordWidth  : natural := 8;
	    WordWidth   : natural := 32
		);  
	  Port (
	     --   latency            : out std_logic_vector (31 downto 0);
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
      		IN_RD_STATUS  			 : in std_logic;
			-- AXI_M (NoC read)   <-> OUT ports
			OUT_RD_EN                : in std_logic;
			OUT_RD_DATA              : out std_logic_vector (WordWidth - 1 downto 0);
			OUT_RD_BEMPTY            : out std_logic;
			OUT_RD_PEMPTY            : out std_logic;
			OUT_RD_TRIG              : out std_logic;
			OUT_RD_DEST			         : out std_logic_vector (PHYNAME_WIDTH - 1 downto 0);
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
      monp_addr					: in std_logic_vector (8 downto 0); -- last address is 0x111, hence 9 bits
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

      -- RMI ports:
      -- status.rmi <-> ports
      status_data               : out  std_logic_vector (31 downto 0);
      status_port_id            : in t_portid;

      -- err.rmi <-> ports
--      send_error                : in std_logic_vector (NR_PORTS - 1 downto 0);
        send_error_id           : in t_portid;

      error_flags               : out  std_logic_vector (NR_PORTS - 1 downto 0);
      error_data                : out  std_logic_vector (31 downto 0);

      -- reconf.rmi <-> ports
      reconf_port_id           : in t_portid;
      reconf_data               : in std_logic_vector (15 downto 0);

      pTimeCnt                  : in t_timeformat;
      reset_n                   : in std_logic;
      clk                       : in std_logic
	  );
	end component;

	component EBU is
    Generic (
      MY_ID       : integer := 0;
      MY_VNET                     : integer := 1;
      TIMELY_BLOCK_ACTIVE         : std_logic := '1'; 
      EVENT_TRIGGERED_ENABLE      : integer := 0;
      USE_BOOTSTRAP	: boolean := false		-- true...boot-strapping / false...start-up
    );
	port 		(
	    CoreInterrupt               : out std_logic;
		pTTDeqOut       	 				: out std_logic;
		pPortIdOut	    	 				: out t_portid;
		pTTCommSchedAddrIn	     	:	in t_ttcommsched_addr;
		pTTCommSchedDataIn		   	:	in t_ttcommsched;
		pTTCommSchedWrEnIn		   	:	in std_logic;
		---------------------------------------------------
		pTTCommSchedAddrIn2	     	:	in t_ttcommsched_addr;
		pTTCommSchedDataIn2		   	:	in t_ttcommsched;
		pTTCommSchedWrEnIn2		   	:	in std_logic;
		-----------------------------------------------------
		sel : in bit ;
		pETDeqOut       	 				: out std_logic;
		pOpIdOut	    	 					: out t_opid;
		pETCommSchedAddrIn	     	:	in t_etcommsched_addr;
		pETCommSchedDataIn		   	:	in t_etcommsched;
		pETCommSchedWrEnIn		   	:	in std_logic;
		pPeriodEnIn		  					: in std_logic_vector(NR_PERIODS-1 downto 0);
		pReconfInstIn							: in std_logic;
		clk								 				:	in	std_logic;		-- system operation frequency
		pTimeCntIn     		 				: in t_timeformat;
		reset_n						 				:	in	std_logic
	);
	end component;

	component rmi
    Generic (
      MY_ID       							: integer := 0;
      Resource_Management_Enable : std_logic := '0';
      NR_PORTS                  : integer

    );
		port (
	  -- between the RMI and the MON port
	    -- LRM notifies the RMI to fetch new configuration
	    tx_adaptiveRMI : in bit;
	    
	    new_conf                  : in  std_logic;
	    tx_mux : out bit;
	    -- conf_port_data
	    recp_data           		 : in  std_logic_vector (31 downto 0);
	    -- conf_port_data
	    recp_deq               	  : out std_logic;
			recp_err                  : out std_logic;

	    --RMI and MON_port
	    monp_data                : out std_logic_vector (31 downto 0);
	    monp_enq                  : out std_logic;
	    monp_term           : out std_logic;
	    monp_addr             : out std_logic_vector (8 downto 0);

	    -- RMI and ERR_port
	    errp_data                  : out std_logic_vector (31 downto 0);
	    errp_enq                    : out std_logic;
	    errp_term             : out std_logic;

	    -- err.rmi <-> err port interface
--	    send_error                : out std_logic_vector (NR_PORTS - 1 downto 0);
        send_error_id           : out t_portid;

	    error_flags                : in  std_logic_vector (NR_PORTS - 1 downto 0);
	    error_data                : in  std_logic_vector (31 downto 0);

	    -- status.rmi <-> mon port interface
	    status_data               : in  std_logic_vector (31 downto 0);
	    status_port_id            : out t_portid;                   --max port=256
	    --preamble (127:120)  reserve(119:72) port_ID (71:64) command_ID (63:56) new_value(63:0)

    -- reconf.rmi <-> reconf interface at port
        reconf_data               : out std_logic_vector (15 downto 0);
		reconf_port_id            : out t_portid;
--        reconf_port_sel           : out std_logic_vector (NR_PORTS - 1 downto 0);
	    pTTCommSchedAddrOut	      : out t_ttcommsched_addr;
	    pTTCommSchedDataOut		    : out t_ttcommsched;
	    pTTCommSchedWrEnOut		    : out std_logic;
	    ------------------------------------------------------
	    
	   pTTCommSchedAddrOut2	      : out t_ttcommsched_addr;
       pTTCommSchedDataOut2		    : out t_ttcommsched;
       pTTCommSchedWrEnOut2	    : out std_logic;
	    ------------------------------------------------------
	    pETCommSchedAddrOut	      : out t_etcommsched_addr;
	    pETCommSchedDataOut		    : out t_etcommsched;
	    pETCommSchedWrEnOut		    : out std_logic;
	    -- activation / deactivation of specific periods
			pPeriodEnaOut		          : out std_logic_vector(NR_PERIODS-1 downto 0);
	    -- trigger signal for reconfiguration instant
	    pReconfInstOut		        : out std_logic;
	    -- pPortIdIn_Ebu            : in std_logic_vector (PORTID_WIDTH - 1 downto 0);
	    pTimeCnt                  : in  t_timeformat;
	    clk							          : in std_logic;	-- system clock
	    reset_n					          : in std_logic	-- hardware reset
	  );
	end component;

	

	component S_AXI is
		generic (
			C_S_AXI_ID_WIDTH	: integer	:= 1;
			C_S_AXI_DATA_WIDTH	: integer	:= 32;
			C_S_AXI_ADDR_WIDTH	: integer	:= 6;
			C_S_AXI_AWUSER_WIDTH	: integer	:= 0;
			C_S_AXI_ARUSER_WIDTH	: integer	:= 0;
			C_S_AXI_WUSER_WIDTH	: integer	:= 0;
			C_S_AXI_RUSER_WIDTH	: integer	:= 0;
			C_S_AXI_BUSER_WIDTH	: integer	:= 0
		);
		port (
			PORT_WR 							: out std_logic;
			PORT_ID_WR 						: out t_portid;
			PORT_DATA_WR					: out std_logic_vector (C_S_AXI_DATA_WIDTH-1 downto 0);
			PortIdValid_WR 				: out std_logic;
			TERMINATE_WR					: out std_logic;
			BUFF_FULL_WR					: in std_logic;
			PORT_FULL_WR					: in std_logic;

			PORT_RD	  						: out std_logic;
			PORT_ID_RD 						: out t_portid;
			PORT_DATA_RD					: in std_logic_vector (C_S_AXI_DATA_WIDTH-1 downto 0);
			PortIdValid_RD 				: out std_logic;
			TERMINATE_RD					: in std_logic;
			BUFF_EMPTY_RD					: in std_logic;
			PORT_EMPTY_RD					: in std_logic;
		PORT_STATUS_RD				: out std_logic;

			S_AXI_ACLK	: in std_logic;
			S_AXI_ARESETN	: in std_logic;
			S_AXI_AWID	: in std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
			S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
			S_AXI_AWLEN	: in std_logic_vector(7 downto 0);
			S_AXI_AWSIZE	: in std_logic_vector(2 downto 0);
			S_AXI_AWBURST	: in std_logic_vector(1 downto 0);
			S_AXI_AWLOCK	: in std_logic;
			S_AXI_AWCACHE	: in std_logic_vector(3 downto 0);
			S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
			S_AXI_AWQOS	: in std_logic_vector(3 downto 0);
			S_AXI_AWREGION	: in std_logic_vector(3 downto 0);
			S_AXI_AWUSER	: in std_logic_vector(C_S_AXI_AWUSER_WIDTH-1 downto 0);
			S_AXI_AWVALID	: in std_logic;
			S_AXI_AWREADY	: out std_logic;
			S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
			S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
			S_AXI_WLAST	: in std_logic;
			S_AXI_WUSER	: in std_logic_vector(C_S_AXI_WUSER_WIDTH-1 downto 0);
			S_AXI_WVALID	: in std_logic;
			S_AXI_WREADY	: out std_logic;
			S_AXI_BID	: out std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
			S_AXI_BRESP	: out std_logic_vector(1 downto 0);
			S_AXI_BUSER	: out std_logic_vector(C_S_AXI_BUSER_WIDTH-1 downto 0);
			S_AXI_BVALID	: out std_logic;
			S_AXI_BREADY	: in std_logic;
			S_AXI_ARID	: in std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
			S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
			S_AXI_ARLEN	: in std_logic_vector(7 downto 0);
			S_AXI_ARSIZE	: in std_logic_vector(2 downto 0);
			S_AXI_ARBURST	: in std_logic_vector(1 downto 0);
			S_AXI_ARLOCK	: in std_logic;
			S_AXI_ARCACHE	: in std_logic_vector(3 downto 0);
			S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
			S_AXI_ARQOS	: in std_logic_vector(3 downto 0);
			S_AXI_ARREGION	: in std_logic_vector(3 downto 0);
			S_AXI_ARUSER	: in std_logic_vector(C_S_AXI_ARUSER_WIDTH-1 downto 0);
			S_AXI_ARVALID	: in std_logic;
			S_AXI_ARREADY	: out std_logic;
			S_AXI_RID	: out std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
			S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
			S_AXI_RRESP	: out std_logic_vector(1 downto 0);
			S_AXI_RLAST	: out std_logic;
			S_AXI_RUSER	: out std_logic_vector(C_S_AXI_RUSER_WIDTH-1 downto 0);
			S_AXI_RVALID	: out std_logic;
			S_AXI_RREADY	: in std_logic
		);
	end component S_AXI;

	signal sMtgen_mtclk						: std_logic;
    signal wTimeCnt         			: t_timeformat;

	-- signal sPortEnq								: std_logic := '0';
	signal wAxiMNoCRdEn						: std_logic := '0';
	signal wCITrigAxiM						: std_logic := '0';
	signal wAxiMTXDone						: std_logic := '0';
	signal wAxiMBusy							: std_logic := '0';
	-- signal sInit_axi_txn						: std_logic := '0';

	-- signals between the AXI_S and the Core Interface
	-- signal sAxiSMsgInPort			: std_logic := '0';
	signal wAxiSCoreWrEn  				: std_logic;
	signal wAxiSCoreWrPortId			: t_portid;
	signal wAxiSCoreDout  				: std_logic_vector (C_CORE_AXI_DATA_WIDTH - 1 downto 0);
	signal wAxiSCoreWrPortIdValid	: std_logic;
	signal wAxiSCoreWrTerminate		: std_logic;

	signal wAxiSCoreRdEn					: std_logic;
	signal wAxiSCoreRdPortId  		: t_portid;
	signal wAxiSCoreDin  					: std_logic_vector (C_CORE_AXI_DATA_WIDTH - 1 downto 0);
	signal wAxiSCoreRdPortIdValid	: std_logic;
	signal wAxiSCoreRdTerminate		: std_logic;
    signal wAxiSCoreRdStat          : std_logic;

	-- signals for the EBU
	-- TT part
	signal wEbuTTDeq							: std_logic := '0';
	-- signal wEbuRd									: std_logic := '0';
	signal wEbuPortId							: t_portid;
	-- ET part
	signal wEbuETDeq							: std_logic := '0';
	signal wEbuOpId								: t_opid;

	-- signals for the AXI_M_NoC/IBU Read 
	signal wAxiMNoCQin						: std_logic_vector (C_NOC_AXI_DATA_WIDTH - 1 downto 0);
	signal wAxiMNoCWrPortId					: t_portid;
	signal wAxiMNoCWrPortIdValid		: std_logic;
	signal wAxiMNoCWrTerminate		: std_logic;

	signal wAxiMNoCWrEn					: std_logic;

	signal wAxiSNoCQin						: std_logic_vector (C_NOC_AXI_DATA_WIDTH - 1 downto 0);
	signal wAxiSNoCWrPortId					: t_portid;
	signal wAxiSNoCWrPortIdValid		: std_logic;
	signal wAxiSNoCWrTerminate		: std_logic;

	signal wAxiSNoCWrEn					: std_logic;
	-- signals between the AXI_M and the Core Interface 
--	signal wCIDestPhyName  				: t_phyname;

	-- signals between the AXI_s and the Core Interface
	signal wCIOutBufferFull				: std_logic;
	signal wCIOutPortFull					: std_logic;
	signal wCIOutBufferEmpty			: std_logic;
	signal wCIOutPortEmpty				: std_logic;
	signal wCIInBufferFull				: std_logic;
	signal wCIInPortFull					: std_logic;
	signal wCIInBufferEmpty				: std_logic;
	signal wCIInPortEmpty					: std_logic;

	-- wire-through signals for the RMI-> TTCommSched
	-- signal wrdaddress_ttcommsched	:	t_ttcommsched_addr;
	-- signal wrddata_ttcommsched		:	t_ttcommsched;
	-- signals for the TT-Scheduler
	signal wwraddress_ttcommsched	:	t_ttcommsched_addr;
	signal wwrdata_ttcommsched		:	t_ttcommsched;
	signal wwren_ttcommsched			:	std_logic;
	
	------------------------------------------------------------
	signal wwraddress_ttcommsched2	:	t_ttcommsched_addr;
	signal wwrdata_ttcommsched2		:	t_ttcommsched;
	signal wwren_ttcommsched2			:	std_logic;
	------------------------------------------------------------
	-- signals for ET-Interleaver
	signal wwraddress_etcommsched	:	t_etcommsched_addr;
	signal wwrdata_etcommsched		:	t_etcommsched;
	signal wwren_etcommsched			:	std_logic;

	-- wire-through signal from RMI -> TT-Scheduler
	signal wRmiPeriodEn						:  std_logic_vector (NR_PERIODS-1 downto 0);
	signal wRmiReconfInst					:  std_logic;

	signal wRmiNewPortReconf 			:	std_logic;
	signal wRmiRecPortData 				:	std_logic_vector (31 downto 0);
	signal wRmiRecPortDeq 				:	std_logic;
	signal wRmiMonPortData 				:	std_logic_vector (31 downto 0);
	signal wRmiMonPortEnq 				:	std_logic;
	signal wRmiMonPortTerm 				:	std_logic;
	signal wRmiMonPortAddr				:   std_logic_vector (8 downto 0);
	signal wRmiErrPortData 				:	std_logic_vector (31 downto 0);
	signal wRmiErrPortEnq 				:	std_logic;
	signal wRmiErrPortTerm 				:	std_logic;
	signal wRmiPortsSendErr 			:	t_portid;
	signal wRmiPortsErrFlag 			:	std_logic_vector (NR_PORTS - 1 downto 0);
	signal wRmiPortsErrData 			:	std_logic_vector (31 downto 0);
	signal wRmiPortsMonData 			:	std_logic_vector (31 downto 0);
	signal wRmiPortsSendMon 			:	t_portid;	--TODO parameterized;
	signal wRmiPortsRecId      			:	t_portid;
	signal wRmiPortsRecData 			:	std_logic_vector (15 downto 0);


-- signals for NosWrap
    signal wNosCIRdEn                                               : std_logic := '0';
    signal wAxiMNosReqEn                                            : std_logic := '0';
--signal wCITrigAxiM                                            : std_logic := '0';
    signal wCINosTrig                                               : std_logic := '0';
    signal wNosAxiMTrig                                             : std_logic := '0';
    signal wNosAxiMrdTrig                                           : std_logic := '0';

    signal wNoSInWrPortId               : t_portid; 
    signal wNoSInWrPortIdValid          : std_logic; 

    signal wCIOutPortDataNos                        : std_logic_vector (C_NOC_AXI_DATA_WIDTH - 1 downto 0);
    signal wCIOutBufferEmptyNoS                     : std_logic;
    signal wCIDestPhyNameNos                        : t_phyname;

    --signals between Noswrap and AXI_M
    signal wNosDataTxnAxiM                  : std_logic_vector (C_NOC_AXI_DATA_WIDTH - 1 downto 0);
    signal wNosWlastTxnAxiM                 : std_logic;
    signal wNosDestAddrAxiM                 : t_phyname;
    signal wNosSorcAddrAxiM                 : t_phyname;
    
    signal wNosAxiMLengthM                  : integer;

	constant TIMEFORMAT_WIDTH		  : integer := 64;		-- can be also defined as generic
    signal a : bit ;

    

begin
--by 	
     trigger2<=wEbuTTDeq;
     source_datain<=wCIOutPortDataNos;
     --destination_address<=wCIDestPhyNameNos;--OUT_RD_DEST
    

	wTimeCnt <= TimeCntIn;
	
	Period_Interrupt_Controller:process (clk, reset_n)
    begin
        if reset_n = '0' then 
            PeriodIntr <= '0'; 
        elsif rising_edge (clk) then 
            if TimeCntIn(21 downto 10) = "111111111111" then
                PeriodIntr <= '1'; 
            else
                 PeriodIntr <= '0';
            end if;    
        end if; 
    end process;
	
	
	RMI_inst: rmi
	  generic map (
	    	MY_ID => MY_ID,
	    	Resource_Management_Enable => Resource_Management_Enable,
	    	NR_PORTS => NR_PORTS
	  )
	  port map (
	        tx_mux =>a ,
	        tx_adaptiveRMI =>tx_adaptiveRMI,
			new_conf => wRmiNewPortReconf,
			recp_data => wRmiRecPortData,
			recp_deq => wRmiRecPortDeq,
			-- config_interface_error =>
			monp_data => wRmiMonPortData,
			monp_enq => wRmiMonPortEnq,
			monp_term => wRmiMonPortTerm,
			monp_addr => wRmiMonPortAddr,
			send_error_id => wRmiPortsSendErr,
			error_flags => wRmiPortsErrFlag,
			error_data => wRmiPortsErrData,
			status_data => wRmiPortsMonData,
			status_port_id => wRmiPortsSendMon,
			errp_data => wRmiErrPortData,
			errp_enq => wRmiErrPortEnq,
			errp_term => wRmiErrPortTerm,
			reconf_port_id => wRmiPortsRecId,
			reconf_data => wRmiPortsRecData,
			pTTCommSchedAddrOut => wwraddress_ttcommsched,
			pTTCommSchedDataOut => wwrdata_ttcommsched,
			pTTCommSchedWrEnOut => wwren_ttcommsched,
			--------------------------------------------------
			pTTCommSchedAddrOut2 => wwraddress_ttcommsched2,
			pTTCommSchedDataOut2 => wwrdata_ttcommsched2,
			pTTCommSchedWrEnOut2 => wwren_ttcommsched2,
			---------------------------------------------------
		    pETCommSchedAddrOut => wwraddress_etcommsched,
			pETCommSchedDataOut => wwrdata_etcommsched,
			pETCommSchedWrEnOut => wwren_etcommsched,
			pPeriodEnaOut => wRmiPeriodEn,
			-- pPortIdIn_Ebu => wEbuPortId,
			pReconfInstOut => wRmiReconfInst,
			pTimeCnt => TimeCntIn,
			clk => clk,
			reset_n => reset_n
		);

	core_interface_inst: core_interface
	   generic map (
	   MY_ID => MY_ID,
	   Resource_Management_Enable => Resource_Management_Enable,
	   state_bram_enable  => state_bram_enable,
	   event_bram_enable  => event_bram_enable,
	   SLAVE_TTEL => SLAVE_TTEL,
	   NR_PORTS => NR_PORTS
	   )
		Port map (
		      msglen=>msglen,
			OUT_WR_EN => wAxiSCoreWrEn,
			OUT_WR_ID => wAxiSCoreWrPortId,
			OUT_WR_IDVALID => wAxiSCoreWrPortIdValid,
			OUT_WR_DATA => wAxiSCoreDout,
			OUT_WR_BFULL => wCIOutBufferFull,
			OUT_WR_PFULL => wCIOutPortFull,
			OUT_WR_TERM => wAxiSCoreWrTerminate,

			IN_RD_EN => wAxiSCoreRdEn,
			IN_RD_ID => wAxiSCoreRdPortId,
			IN_RD_IDVALID => wAxiSCoreRdPortIdValid,
			IN_RD_DATA => wAxiSCoreDin,
			IN_RD_BEMPTY => wCIInBufferEmpty,
			IN_RD_PEMPTY => wCIInPortEmpty,
			IN_RD_STATUS	=> wAxiSCoreRdStat,

            OUT_RD_EN               => out_rd_en ,--wNosCIRdEn
            OUT_RD_DATA             => wCIOutPortDataNos ,
            OUT_RD_BEMPTY           => wCIOutBufferEmptyNoS ,
            OUT_RD_PEMPTY           => wCIOutPortEmpty,
            OUT_RD_TRIG             => trigger,--wCINosTrig,
            OUT_RD_DEST             => destination_address,--wCIDestPhyNameNos,--destination_address


			IN_WR_EN => write_en,--wAxiMNoCWrEn,
--			IN_WR_ID => wAxiMNoCWrPortId,      commmented by HA and AM
--			 => wAxiMNoCWrPortIdValid,
			IN_WR_ID => sink_portid,--wNoSInWrPortId,
            IN_WR_IDVALID =>portid_valid,-- wNoSInWrPortIdValid,
			IN_WR_DATA =>sink_dataout,-- wAxiMNoCQin,by chen
			IN_WR_BFULL => wCIInBufferFull,
			IN_WR_PFULL => wCIInPortFull,
			IN_WR_TERM =>sink_terminate,-- wAxiMNoCWrTerminate,
            pIntToCore => pIntToCore,
			pAxiTxDone => wAxiMTXDone,
--            pBypassLetIt => wLetIt,

			pTTPortId => wEbuPortId,
			pTTDeqIn => wEbuTTDeq,
			pETDeqIn => wEbuETDeq,
			pETOpId => wEbuOpId,

			new_conf => wRmiNewPortReconf,
			reconf_data => wRmiPortsRecData,
			recp_deq => wRmiRecPortDeq,
			-- config_interface_error =>
			monp_data => wRmiMonPortData,
			monp_enq => wRmiMonPortEnq,
			monp_term => wRmiMonPortTerm,
			monp_addr => wRmiMonPortAddr,
			send_error_id => wRmiPortsSendErr,
			error_flags => wRmiPortsErrFlag,
			error_data => wRmiPortsErrData,
			status_data => wRmiPortsMonData,
			status_port_id => wRmiPortsSendMon,
			errp_data => wRmiErrPortData,
			errp_enq => wRmiErrPortEnq,
			errp_term => wRmiErrPortTerm,
			reconf_port_id => wRmiPortsRecId,
			recp_data => wRmiRecPortData,
			pTimeCnt => wTimeCnt,
			reset_n => reset_n,
			clk => clk
		);

	EBU_inst: EBU
		generic map (
        MY_ID => MY_ID,
        TIMELY_BLOCK_ACTIVE => TIMELY_BLOCK_ACTIVE,  
        MY_VNET => MY_VNET,
        EVENT_TRIGGERED_ENABLE => EVENT_TRIGGERED_ENABLE
    )
		port map (
		    CoreInterrupt   => CoreInterrupt,
			pTTDeqOut => wEbuTTDeq,
			pPortIdOut => wEbuPortId,
			pTTCommSchedAddrIn => wwraddress_ttcommsched,
			pTTCommSchedDataIn => wwrdata_ttcommsched,
			pTTCommSchedWrEnIn => wwren_ttcommsched,
			----------------------------------------------	
			pTTCommSchedAddrIn2 => wwraddress_ttcommsched2,
			pTTCommSchedDataIn2 => wwrdata_ttcommsched2,
			pTTCommSchedWrEnIn2 => wwren_ttcommsched2,
			------------------------------------------
			sel                 => a ,
			
			pETDeqOut => wEbuETDeq,
			pOpIdOut => wEbuOpId,
			pETCommSchedAddrIn => wwraddress_etcommsched,
			pETCommSchedDataIn => wwrdata_etcommsched,
			pETCommSchedWrEnIn => wwren_etcommsched,
			pPeriodEnIn => wRmiPeriodEn,
			pReconfInstIn => wRmiReconfInst,
			pTimeCntIn => wTimeCnt,
			-- AxiTXDone => wAxiMTXDone,
			clk 	=> clk,
			reset_n	=> reset_n
		);



	-- Instantiation of Axi Bus Interface S_AXI at the core side
	AXI_S_CORE : S_AXI
		generic map (
			C_S_AXI_ID_WIDTH	=> C_CORE_AXI_ID_WIDTH,
			C_S_AXI_DATA_WIDTH	=> C_CORE_AXI_DATA_WIDTH,
			C_S_AXI_ADDR_WIDTH	=> C_CORE_AXI_ADDR_WIDTH,
			C_S_AXI_AWUSER_WIDTH	=> C_CORE_AXI_AWUSER_WIDTH,
			C_S_AXI_ARUSER_WIDTH	=> C_CORE_AXI_ARUSER_WIDTH,
			C_S_AXI_WUSER_WIDTH	=> C_CORE_AXI_WUSER_WIDTH,
			C_S_AXI_RUSER_WIDTH	=> C_CORE_AXI_RUSER_WIDTH,
			C_S_AXI_BUSER_WIDTH	=> C_CORE_AXI_BUSER_WIDTH
		)
		port map (
			PORT_WR => wAxiSCoreWrEn,
			PORT_ID_WR => wAxiSCoreWrPortId,
			PORT_DATA_WR => wAxiSCoreDout,
			PortIdValid_WR => wAxiSCoreWrPortIdValid,
			TERMINATE_WR => wAxiSCoreWrTerminate,
			BUFF_FULL_WR => wCIOutBufferFull,
			PORT_FULL_WR => wCIOutPortFull,
			PORT_RD => wAxiSCoreRdEn,
			PORT_ID_RD => wAxiSCoreRdPortId,
			PORT_DATA_RD => wAxiSCoreDin,
			PortIdValid_RD => wAxiSCoreRdPortIdValid,
			BUFF_EMPTY_RD => wCIInBufferEmpty,
			PORT_EMPTY_RD => wCIInPortEmpty,
			TERMINATE_RD => wAxiSCoreRdTerminate,
			PORT_STATUS_RD => wAxiSCoreRdStat,
			S_AXI_ACLK	=>  clk, --s_axi_core_aclk, -- clk, --
			S_AXI_ARESETN	=> reset_n,--s_axi_core_aresetn, -- reset_n, --
			S_AXI_AWID	=> s_axi_core_awid,
			S_AXI_AWADDR	=> s_axi_core_awaddr,
			S_AXI_AWLEN	=> s_axi_core_awlen,
			S_AXI_AWSIZE	=> s_axi_core_awsize,
			S_AXI_AWBURST	=> s_axi_core_awburst,
			S_AXI_AWLOCK	=> s_axi_core_awlock,
			S_AXI_AWCACHE	=> s_axi_core_awcache,
			S_AXI_AWPROT	=> s_axi_core_awprot,
			S_AXI_AWQOS	=> s_axi_core_awqos,
			S_AXI_AWREGION	=> s_axi_core_awregion,
			S_AXI_AWUSER	=> s_axi_core_awuser,
			S_AXI_AWVALID	=> s_axi_core_awvalid,
			S_AXI_AWREADY	=> s_axi_core_awready,
			S_AXI_WDATA	=> s_axi_core_wdata,
			S_AXI_WSTRB	=> s_axi_core_wstrb,
			S_AXI_WLAST	=> s_axi_core_wlast,
			S_AXI_WUSER	=> s_axi_core_wuser,
			S_AXI_WVALID	=> s_axi_core_wvalid,
			S_AXI_WREADY	=> s_axi_core_wready,
			S_AXI_BID	=> s_axi_core_bid,
			S_AXI_BRESP	=> s_axi_core_bresp,
			S_AXI_BUSER	=> s_axi_core_buser,
			S_AXI_BVALID	=> s_axi_core_bvalid,
			S_AXI_BREADY	=> s_axi_core_bready,
			S_AXI_ARID	=> s_axi_core_arid,
			S_AXI_ARADDR	=> s_axi_core_araddr,
			S_AXI_ARLEN	=> s_axi_core_arlen,
			S_AXI_ARSIZE	=> s_axi_core_arsize,
			S_AXI_ARBURST	=> s_axi_core_arburst,
			S_AXI_ARLOCK	=> s_axi_core_arlock,
			S_AXI_ARCACHE	=> s_axi_core_arcache,
			S_AXI_ARPROT	=> s_axi_core_arprot,
			S_AXI_ARQOS	=> s_axi_core_arqos,
			S_AXI_ARREGION	=> s_axi_core_arregion,
			S_AXI_ARUSER	=> s_axi_core_aruser,
			S_AXI_ARVALID	=> s_axi_core_arvalid,
			S_AXI_ARREADY	=> s_axi_core_arready,
			S_AXI_RID	=> s_axi_core_rid,
			S_AXI_RDATA	=> s_axi_core_rdata,
			S_AXI_RRESP	=> s_axi_core_rresp,
			S_AXI_RLAST	=> s_axi_core_rlast,
			S_AXI_RUSER	=> s_axi_core_ruser,
			S_AXI_RVALID	=> s_axi_core_rvalid,
			S_AXI_RREADY	=> s_axi_core_rready
		);


end arch_imp;
