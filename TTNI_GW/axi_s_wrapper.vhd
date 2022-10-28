library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

library SAFEPOWER;
use SAFEPOWER.TTEL.all;	-- parameters of the current TTEL (for PORTID_WIDTH)
use SAFEPOWER.ttel_parameter.all;	-- NR_PORTS

library SYSTEMS;
use SYSTEMS.auxiliary.all;         	-- helper functions and helper procedures
use SYSTEMS.system_parameter.all;	-- parameters of the current NoC instance


entity S_AXI is
	generic (
		-- Width of ID for for write address, write data, read address and read data
		C_S_AXI_ID_WIDTH			: integer	:= 1;
		-- Width of S_AXI data bus
		C_S_AXI_DATA_WIDTH		: integer	:= 32;
		-- Width of S_AXI address bus
		C_S_AXI_ADDR_WIDTH		: integer	:= 32;
		-- Width of optional user defined signal in write address channel
		C_S_AXI_AWUSER_WIDTH	: integer	:= 0;
		-- Width of optional user defined signal in read address channel
		C_S_AXI_ARUSER_WIDTH	: integer	:= 0;
		-- Width of optional user defined signal in write data channel
		C_S_AXI_WUSER_WIDTH		: integer	:= 0;
		-- Width of optional user defined signal in read data channel
		C_S_AXI_RUSER_WIDTH		: integer	:= 0;
		-- Width of optional user defined signal in write response channel
		C_S_AXI_BUSER_WIDTH		: integer	:= 0
	);
	port (
		PORT_WR 							: out std_logic;
		PortIdValid_WR 				: out std_logic;
		PORT_ID_WR 						: out std_logic_vector (PORTID_WIDTH - 1 downto 0);
		PORT_DATA_WR					: out std_logic_vector (C_S_AXI_DATA_WIDTH-1 downto 0);
		-- PORT_ADDR_WR          : out std_logic_vector (C_PORT_ADDR_RANGE - 1 downto 0);
		BUFF_FULL_WR					: in std_logic;
		PORT_FULL_WR					: in std_logic;
		TERMINATE_WR					: out std_logic;

		PORT_RD	  						: out std_logic;
		PortIdValid_RD 				: out std_logic;
		PORT_ID_RD 						: out std_logic_vector (PORTID_WIDTH - 1 downto 0);
		PORT_DATA_RD					: in std_logic_vector (C_S_AXI_DATA_WIDTH-1 downto 0);
		PORT_STATUS_RD				: out std_logic;
		-- PORT_ADDR_RD          : out std_logic_vector (C_PORT_ADDR_RANGE - 1 downto 0);
		BUFF_EMPTY_RD					: in std_logic;
		PORT_EMPTY_RD					: in std_logic;
		TERMINATE_RD					: in std_logic;
		----------------------------------------------------------------------------
		-- AXI standard signals
		----------------------------------------------------------------------------

		-- Global Clock Signal
		S_AXI_ACLK	: in std_logic;
		-- Global Reset Signal. This Signal is Active LOW
		S_AXI_ARESETN	: in std_logic;
		-- Write Address ID
		S_AXI_AWID	: in std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
		-- Write address
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		-- Burst length. The burst length gives the exact number of transfers in a burst
		S_AXI_AWLEN	: in std_logic_vector(7 downto 0);
		-- Burst size. This signal indicates the size of each transfer in the burst
		S_AXI_AWSIZE	: in std_logic_vector(2 downto 0);
		-- Burst type. The burst type and the size information,
    -- determine how the address for each transfer within the burst is calculated.
		S_AXI_AWBURST	: in std_logic_vector(1 downto 0);
		-- Lock type. Provides additional information about the
    -- atomic characteristics of the transfer.
		S_AXI_AWLOCK	: in std_logic;
		-- Memory type. This signal indicates how transactions
    -- are required to progress through a system.
		S_AXI_AWCACHE	: in std_logic_vector(3 downto 0);
		-- Protection type. This signal indicates the privilege
    -- and security level of the transaction, and whether
    -- the transaction is a data access or an instruction access.
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		-- Quality of Service, QoS identifier sent for each
    -- write transaction.
		S_AXI_AWQOS	: in std_logic_vector(3 downto 0);
		-- Region identifier. Permits a single physical interface
    -- on a slave to be used for multiple logical interfaces.
		S_AXI_AWREGION	: in std_logic_vector(3 downto 0);
		-- Optional User-defined signal in the write address channel.
		S_AXI_AWUSER	: in std_logic_vector(C_S_AXI_AWUSER_WIDTH-1 downto 0);
		-- Write address valid. This signal indicates that
    -- the channel is signaling valid write address and
    -- control information.
		S_AXI_AWVALID	: in std_logic;
		-- Write address ready. This signal indicates that
    -- the slave is ready to accept an address and associated
    -- control signals.
		S_AXI_AWREADY	: out std_logic;
		-- Write Data
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		-- Write strobes. This signal indicates which byte
    -- lanes hold valid data. There is one write strobe
    -- bit for each eight bits of the write data bus.
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		-- Write last. This signal indicates the last transfer
    -- in a write burst.
		S_AXI_WLAST	: in std_logic;
		-- Optional User-defined signal in the write data channel.
		S_AXI_WUSER	: in std_logic_vector(C_S_AXI_WUSER_WIDTH-1 downto 0);
		-- Write valid. This signal indicates that valid write
    -- data and strobes are available.
		S_AXI_WVALID	: in std_logic;
		-- Write ready. This signal indicates that the slave
    -- can accept the write data.
		S_AXI_WREADY	: out std_logic;
		-- Response ID tag. This signal is the ID tag of the
    -- write response.
		S_AXI_BID	: out std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
		-- Write response. This signal indicates the status
    -- of the write transaction.
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		-- Optional User-defined signal in the write response channel.
		S_AXI_BUSER	: out std_logic_vector(C_S_AXI_BUSER_WIDTH-1 downto 0);
		-- Write response valid. This signal indicates that the
    -- channel is signaling a valid write response.
		S_AXI_BVALID	: out std_logic;
		-- Response ready. This signal indicates that the master
    -- can accept a write response.
		S_AXI_BREADY	: in std_logic;
		-- Read address ID. This signal is the identification
    -- tag for the read address group of signals.
		S_AXI_ARID	: in std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
		-- Read address. This signal indicates the initial
    -- address of a read burst transaction.
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		-- Burst length. The burst length gives the exact number of transfers in a burst
		S_AXI_ARLEN	: in std_logic_vector(7 downto 0);
		-- Burst size. This signal indicates the size of each transfer in the burst
		S_AXI_ARSIZE	: in std_logic_vector(2 downto 0);
		-- Burst type. The burst type and the size information,
    -- determine how the address for each transfer within the burst is calculated.
		S_AXI_ARBURST	: in std_logic_vector(1 downto 0);
		-- Lock type. Provides additional information about the
    -- atomic characteristics of the transfer.
		S_AXI_ARLOCK	: in std_logic;
		-- Memory type. This signal indicates how transactions
    -- are required to progress through a system.
		S_AXI_ARCACHE	: in std_logic_vector(3 downto 0);
		-- Protection type. This signal indicates the privilege
    -- and security level of the transaction, and whether
    -- the transaction is a data access or an instruction access.
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		-- Quality of Service, QoS identifier sent for each
    -- read transaction.
		S_AXI_ARQOS	: in std_logic_vector(3 downto 0);
		-- Region identifier. Permits a single physical interface
    -- on a slave to be used for multiple logical interfaces.
		S_AXI_ARREGION	: in std_logic_vector(3 downto 0);
		-- Optional User-defined signal in the read address channel.
		S_AXI_ARUSER	: in std_logic_vector(C_S_AXI_ARUSER_WIDTH-1 downto 0);
		-- Write address valid. This signal indicates that
    -- the channel is signaling valid read address and
    -- control information.
		S_AXI_ARVALID	: in std_logic;
		-- Read address ready. This signal indicates that
    -- the slave is ready to accept an address and associated
    -- control signals.
		S_AXI_ARREADY	: out std_logic;
		-- Read ID tag. This signal is the identification tag
    -- for the read data group of signals generated by the slave.
		S_AXI_RID	: out std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
		-- Read Data
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		-- Read response. This signal indicates the status of
    -- the read transfer.
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		-- Read last. This signal indicates the last transfer
    -- in a read burst.
		S_AXI_RLAST	: out std_logic;
		-- Optional User-defined signal in the read address channel.
		S_AXI_RUSER	: out std_logic_vector(C_S_AXI_RUSER_WIDTH-1 downto 0);
		-- Read valid. This signal indicates that the channel
    -- is signaling the required read data.
		S_AXI_RVALID	: out std_logic;
		-- Read ready. This signal indicates that the master can
    -- accept the read data and response information.
		S_AXI_RREADY	: in std_logic
	);
end S_AXI;

architecture arch_imp of S_AXI is

	-- AXI4FULL signals
	signal axi_awaddr				: std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
	signal axi_awready			: std_logic;
	signal axi_wready				: std_logic;
	signal axi_bresp				: std_logic_vector(1 downto 0);
	signal axi_buser				: std_logic_vector(C_S_AXI_BUSER_WIDTH-1 downto 0);
	signal axi_bvalid				: std_logic;
	signal axi_araddr				: std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
	signal axi_arready			: std_logic;
	signal axi_rdata				: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal axi_rresp				: std_logic_vector(1 downto 0);
	signal axi_rlast				: std_logic;
	signal axi_ruser				: std_logic_vector(C_S_AXI_RUSER_WIDTH-1 downto 0);
	signal axi_int_rvalid		: std_logic;
	signal axi_rvalid				: std_logic;
	-- aw_wrap_en determines wrap boundary and enables wrapping
	signal  aw_wrap_en 			: std_logic;
	-- ar_wrap_en determines wrap boundary and enables wrapping
	signal  ar_wrap_en 			: std_logic;
	-- aw_wrap_size is the size of the write transfer, the
	-- write address wraps to a lower address if upper address
	-- limit is reached
	signal aw_wrap_size 		: integer;
	-- ar_wrap_size is the size of the read transfer, the
	-- read address wraps to a lower address if upper address
	-- limit is reached
	signal ar_wrap_size 		: integer;
	-- The wr_add_valid flag marks the presence of write address valid
	signal wr_add_valid    	: std_logic;
	--The rd_add_valid flag marks the presence of read address valid
	signal rd_add_valid    	: std_logic;
	-- The axi_awlen_cntr internal write address counter to keep track of beats in a burst transaction
	signal axi_awlen_cntr   : std_logic_vector(7 downto 0);
	--The axi_arlen_cntr internal read address counter to keep track of beats in a burst transaction
	-- signal axi_arlen_cntr   : std_logic_vector(7 downto 0);
	signal axi_arlen_cntr   : integer;
	signal raxi_awlen				: std_logic_vector(7 downto 0);



	--local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	--ADDR_LSB is used for addressing 32/64 bit registers/memories
	--ADDR_LSB = 2 for 32 bits (n downto 2)
	--ADDR_LSB = 3 for 42 bits (n downto 3)
	constant ADDR_LSB  : integer := (C_S_AXI_DATA_WIDTH/32)+ 1;

	-- HA: changed to 0 to have word aligned addressing
	-- constant ADDR_LSB : integer := 0;
	-- constant MEM_ADDR_WIDTH : integer := 8;
	constant low : std_logic_vector (C_S_AXI_ADDR_WIDTH - 1 downto 0) := (others => '0');
	constant C_S_AXI_BURST_LEN : integer := 16;


	-- State machine to initialize counter, initialize read transactions
	type rd_state is ( IDLE,
					CHECK_READ,
					READ_ACK,
					READ_DENIED,
					READING
					);

	signal read_state  			: rd_state;
	signal read_nextstate  	: rd_state;

		------------------------------------------------
		---- Signals for user logic memory space example
		--------------------------------------------------
	-- type word_array is array (0 to 2**MEM_ADDR_WIDTH - 1) of std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	type control_line_type is array (integer range <>) of std_logic;
	type data_line_type is array (integer range <>) of std_logic_vector (C_S_AXI_DATA_WIDTH - 1 downto 0);
	-- signal ttel_int_mem 					: word_array;

	-- signal sIntMemRdEn					: control_line_type (NR_ADD_PORTS - 1 downto 0);-- std_logic; --
	-- signal sIntMemWrEn					: control_line_type (NR_ADD_PORTS - 1 downto 0);-- std_logic; --
	-- signal int_mem_wr_data			: data_line_type (NR_ADD_PORTS - 1 downto 0);
	-- signal int_mem_rd_data			: data_line_type (NR_ADD_PORTS - 1 downto 0);



	signal ebu_deq_started 			: std_logic;
	signal ebu_deq_done					: std_logic;


	-- signals for writing the data into the port
	signal sPortWrEn	: std_logic;
	signal sPortRdEn	: std_logic;

	signal sWrAddrPortId : integer;
	signal sRdAddrPortId : integer;

	signal port_status_read_bit		: std_logic;
	signal port_stat_rd_en				: std_logic;
	signal port_conf_write_bit		: std_logic;
	signal port_conf_wr_en				: std_logic;


	-- signal rPortId
	-- signal last_burst :std_logic;
	-- signal wWR_TERMINATE		: std_logic;

	-- signal write_burst_counter	: std_logic_vector(7 downto 0);
	signal rnext	: std_logic;
	signal wnext	: std_logic;
	signal read_burst_counter				: std_logic_vector (7 downto 0);
	-- signal read_beat_counter				: std_logic_vector (7 downto 0);
	signal read_beat_counter				: integer;
	signal start_single_burst_write	: std_logic;
	signal start_single_burst_read	: std_logic;
	signal termination_burst_bit :std_logic;
	signal termination_burst_en :std_logic;

	begin

		-- I/O Connections assignments
		S_AXI_AWREADY	<= axi_awready;
		S_AXI_WREADY	<= axi_wready;
		S_AXI_BRESP	<= axi_bresp;
		S_AXI_BUSER	<= axi_buser;
		S_AXI_BVALID	<= axi_bvalid;
		S_AXI_ARREADY	<= axi_arready;
		S_AXI_RDATA	<= axi_rdata;
		S_AXI_RRESP	<= axi_rresp;
		S_AXI_RLAST	<= axi_rlast;
		S_AXI_RUSER	<= axi_ruser;
		S_AXI_RVALID	<= axi_rvalid;
--		S_AXI_BID <= S_AXI_AWID;
		S_AXI_RID <= S_AXI_ARID;
		aw_wrap_size <= ((C_S_AXI_DATA_WIDTH)/8 * to_integer(unsigned(S_AXI_AWLEN)));
		ar_wrap_size <= ((C_S_AXI_DATA_WIDTH)/8 * to_integer(unsigned(S_AXI_ARLEN)));
		aw_wrap_en <= '1' when (((axi_awaddr AND std_logic_vector(to_unsigned(aw_wrap_size,C_S_AXI_ADDR_WIDTH))) XOR std_logic_vector(to_unsigned(aw_wrap_size,C_S_AXI_ADDR_WIDTH))) = low) else '0';
		ar_wrap_en <= '1' when (((axi_araddr AND std_logic_vector(to_unsigned(ar_wrap_size,C_S_AXI_ADDR_WIDTH))) XOR std_logic_vector(to_unsigned(ar_wrap_size,C_S_AXI_ADDR_WIDTH))) = low) else '0';
		S_AXI_BUSER <= (others => '0');

		PORT_WR <= sPortWrEn;
        PORT_RD <= axi_int_rvalid when BUFF_EMPTY_RD /= '1' and port_stat_rd_en /= '1' else '0'; 
		-- last_burst <= axi_awaddr (C_LAST_BURST_BIT);
		termination_burst_bit <= S_AXI_AWADDR(15);--C_LAST_BURST_BIT=15,,axi_awaddr(14)
		TERMINATE_WR <= sPortWrEn and termination_burst_en;

		start_single_burst_write <= axi_awready and S_AXI_AWVALID;
		start_single_burst_read <= axi_arready and S_AXI_ARVALID;

		PORT_STATUS_RD <= port_stat_rd_en;-- and axi_int_rvalid;
		port_status_read_bit <= S_AXI_ARADDR (C_PORT_STATUS_BIT);

		axi_rdata <= PORT_DATA_RD;
		PORT_DATA_WR <= S_AXI_WDATA;

		process (S_AXI_AWADDR)
		begin
			sWrAddrPortId <= to_integer (unsigned (S_AXI_AWADDR (C_PORTID_LOW + PORTID_WIDTH - 1 downto C_PORTID_LOW)));
		end process;

		process (S_AXI_ARADDR)
		begin
			sRdAddrPortId <= to_integer (unsigned (S_AXI_ARADDR (C_PORTID_LOW + PORTID_WIDTH - 1 downto C_PORTID_LOW)));
		end process;


			process (S_AXI_ARESETN, S_AXI_ACLK) -- S_AXI_AWVALID, sWrAddrPortId1
			begin
				if S_AXI_ARESETN = '0' then
					termination_burst_en <= '0';
				elsif rising_edge (S_AXI_ACLK) then
					if S_AXI_AWVALID = '1' and termination_burst_bit = '1' and axi_awready = '1' then
						termination_burst_en <= '1';
					elsif S_AXI_BREADY = '1' and axi_bvalid = '1'  then
						termination_burst_en <= '0';
					end if;
				end if;
			end process;

		-- --process for generating LAST_WORD
		-- process (S_AXI_ARESETN, last_burst, axi_awlen_cntr, sPortWrEn)
		-- begin
		-- 	if S_AXI_ARESETN = '0' then
		-- 		LAST_WORD <= '0';
		-- 	elsif sPortWrEn = '1' then
		-- 		if last_burst = '1' and axi_awlen_cntr = std_logic_vector (unsigned (raxi_awlen) + 1) then
		-- 			LAST_WORD <= '1';
		-- 		else
		-- 			LAST_WORD <= '0';
		-- 		end if;
		-- 	else
		-- 		LAST_WORD <= '0';
		-- 	end if;
		-- end process;

		--process for generating TERMINATE_WR
		-- process (S_AXI_ARESETN, termination_burst, sPortWrEn)-- , axi_awlen_cntr)
		-- begin
		-- 	if S_AXI_ARESETN = '0' then
		-- 		TERMINATE_WR <= '0';
		-- 	elsif sPortWrEn = '1' and  termination_burst = '1' then -- and axi_awlen_cntr = std_logic_vector (unsigned (raxi_awlen) + 1) then
		-- 			TERMINATE_WR <= '1';
		-- 	else
		-- 		TERMINATE_WR <= '0';
		-- 	end if;
		-- end process;
		--
		-- process (S_AXI_ARESETN, S_AXI_ACLK)-- , axi_awlen_cntr)
		-- begin
		-- 	if S_AXI_ARESETN = '0' then
		-- 		wWR_TERMINATE <= '0';
		-- 	elsif rising_edge (S_AXI_ACLK) then
		-- 		if wWR_TERMINATE = '0' and termination_burst = '1' and sPortWrEn = '1' then -- and 				axi_awlen_cntr = std_logic_vector (unsigned (raxi_awlen) + 1) then
		-- 			wWR_TERMINATE <= '1';
		-- 		else
		-- 			wWR_TERMINATE <= '0';
		-- 		end if;
		-- 	end if;
		-- end process;

-- process for writing the WDATA into the core interface
sPortWrEn <= wnext; --  when termination_burst_en = '0' else '0'; 
--  port_enable_proc : process(S_AXI_ACLK) is
--  begin
--  	if S_AXI_ARESETN = '0' then
--			sPortWrEn <= '0';
--		elsif rising_edge (S_AXI_ACLK) then
--      if axi_wready = '1' and S_AXI_WVALID = '1' then -- and port_conf_wr_en /= '1' then
--				-- if int_mem_targeted = '1' then
--				-- 	int_mem_wr_data (unsigned mem_wr_address) <= S_AXI_WDATA;
--				-- else
--				-- 	PORT_DATA_WR <= S_AXI_WDATA;
--					sPortWrEn <= '1';
--				else
--					sPortWrEn <= '0';
--			end if;
--    end if;
--  end process port_enable_proc;



	---------------------------------------------------------------------------------------------
	-- Implement axi_awready generation
	-- axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	-- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	-- de-asserted when reset is low.
	process (S_AXI_ACLK)
	begin
	    if S_AXI_ARESETN = '0' then
	      axi_awready <= '0';
	      wr_add_valid <= '0';
	    elsif rising_edge(S_AXI_ACLK) then
			if (axi_awready = '0' and S_AXI_AWVALID = '1' and wr_add_valid = '0' and rd_add_valid = '0') then
    	       wr_add_valid  <= '1'; -- used for generation of bresp() and bvalid
	           axi_awready <= '1';
		       raxi_awlen <= S_AXI_AWLEN;
	        elsif (S_AXI_WLAST = '1' and axi_wready = '1') then
	      -- preparing to accept next address after current write burst tx completion
	           wr_add_valid  <= '0';
	        else
	           axi_awready <= '0';
	        end if;
	    end if;
	end process;

	---------------------------------------------------------------------------------------------
	-- Implement axi_awaddr latching

	-- This process is used to latch the address when both
	-- S_AXI_AWVALID and S_AXI_WVALID are valid.
	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then
	    if S_AXI_ARESETN = '0' then
	      axi_awaddr <= (others => '0');
	      axi_awlen_cntr <= (others => '0');
	    else
	      if (axi_awready = '0' and S_AXI_AWVALID = '1' and wr_add_valid = '0') then
	      -- address latching
	        axi_awaddr <= S_AXI_AWADDR(C_S_AXI_ADDR_WIDTH - 1 downto 0);  ---- start address of transfer
	        axi_awlen_cntr <= (others => '0');
					PORT_ID_WR <= S_AXI_AWADDR (C_PORTID_LOW + PORTID_WIDTH - 1 downto C_PORTID_LOW); -- sWrAddrPortId;
					-- PORT_ID_WR <= S_AXI_AWADDR (C_PORTID_HIGH downto C_PORTID_LOW);
	      elsif((axi_awlen_cntr <= S_AXI_AWLEN) and axi_wready = '1' and S_AXI_WVALID = '1') then
	        axi_awlen_cntr <= std_logic_vector (unsigned(axi_awlen_cntr) + 1);
	        case (S_AXI_AWBURST) is
	          when "00" => -- fixed burst
	            -- The write address for all the beats in the transaction are fixed
	            axi_awaddr     <= axi_awaddr;       ----for awsize = 4 bytes (010)
	          when "01" => --incremental burst
	            -- The write address for all the beats in the transaction are increments by awsize
	            axi_awaddr(C_S_AXI_ADDR_WIDTH - 1 downto ADDR_LSB) <= std_logic_vector (unsigned(axi_awaddr(C_S_AXI_ADDR_WIDTH - 1 downto ADDR_LSB)) + 1);--awaddr aligned to 4 byte boundary
	            axi_awaddr(ADDR_LSB-1 downto 0)  <= (others => '0');  ----for awsize = 4 bytes (010)
	          when "10" => --Wrapping burst
	            -- The write address wraps when the address reaches wrap boundary
	            if (aw_wrap_en = '1') then
	              axi_awaddr <= std_logic_vector (unsigned(axi_awaddr) - (to_unsigned(aw_wrap_size,C_S_AXI_ADDR_WIDTH)));
	            else
	              axi_awaddr(C_S_AXI_ADDR_WIDTH - 1 downto ADDR_LSB) <= std_logic_vector (unsigned(axi_awaddr(C_S_AXI_ADDR_WIDTH - 1 downto ADDR_LSB)) + 1);--awaddr aligned to 4 byte boundary
	              axi_awaddr(ADDR_LSB-1 downto 0)  <= (others => '0');  ----for awsize = 4 bytes (010)
	            end if;
	          when others => --reserved (incremental burst for example)
	            axi_awaddr(C_S_AXI_ADDR_WIDTH - 1 downto ADDR_LSB) <= std_logic_vector (unsigned(axi_awaddr(C_S_AXI_ADDR_WIDTH - 1 downto ADDR_LSB)) + 1);--for awsize = 4 bytes (010)
	            axi_awaddr(ADDR_LSB-1 downto 0)  <= (others => '0');
	        end case;
	      end if;
	    end if;
	  end if;
	end process;

	---------------------------------------------------------------------------------------------
	-- Implement axi_wready generation

	-- axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	-- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is
	-- de-asserted when reset is low.

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then
	    if S_AXI_ARESETN = '0' then
	      axi_wready <= '0';
	    else
	      if (axi_wready = '0' and S_AXI_WVALID = '1' and wr_add_valid = '1') then
	        axi_wready <= '1';
	        -- elsif (wr_add_valid = '0') then
	      elsif (S_AXI_WLAST = '1' and axi_wready = '1') then

	        axi_wready <= '0';
	      end if;
	    end if;
	  end if;
	end process;

	---------------------------------------------------------------------------------------------
	-- Implement PortIdValid_WR generation
	PortIdValid_WR <= axi_awready and S_AXI_AWVALID;
--	process (S_AXI_ARESETN, S_AXI_ACLK)--, port_conf_wr_en)
--	begin
--		if S_AXI_ARESETN = '0' then
--			PortIdValid_WR <= '0';
--		elsif rising_edge(S_AXI_ACLK) then
--			if axi_awready = '1' and S_AXI_AWVALID = '1' then -- and port_conf_wr_en /= '1') then
--				PortIdValid_WR <= '1';
--			else
--				PortIdValid_WR <= '0';
--			end if;
--		end if;
--	end process;


	---------------------------------------------------------------------------------------------
	-- Implement write response logic generation

	-- The write response and response valid signals are asserted by the slave
	-- when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.
	-- This marks the acceptance of address and indicates the status of
	-- write transaction.

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then
	    if S_AXI_ARESETN = '0' then
	      axi_bvalid  <= '0';
	      axi_bresp  <= "00"; --need to work more on the responses TODO (HA): in case the buffer is full 0b01 can be returned
	    else
	      if (wr_add_valid = '1' and axi_wready = '1' and S_AXI_WVALID = '1' and axi_bvalid = '0' and S_AXI_WLAST = '1' ) then
	        axi_bvalid <= '1';
	        axi_bresp  <= "00";
	      elsif (S_AXI_BREADY = '1' and axi_bvalid = '1') then
	      --check if bready is asserted while bvalid is high)
	        axi_bvalid <= '0';
	      end if;
	    end if;
	  end if;
	end process;

	process (S_AXI_ACLK, S_AXI_ARESETN)
	begin
    if S_AXI_ARESETN = '0' then
			S_AXI_BID <= (others => '0'); --C_AXI_ID_BASE;
		elsif rising_edge(S_AXI_ACLK) then
			if S_AXI_AWVALID = '1' and axi_awready = '1' then
				S_AXI_BID <= S_AXI_AWID;
			end if;
		end if;
	end process;

	---------------------------------------------------------------------------------------------
	-- Implement axi_arready generation

	-- axi_arready is asserted for one S_AXI_ACLK clock cycle when
	-- S_AXI_ARVALID is asserted. axi_awready is
	-- de-asserted when reset (active low) is asserted.
	-- The read address is also latched when S_AXI_ARVALID is
	-- asserted. axi_araddr is reset to zero on reset assertion.

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then
	    if S_AXI_ARESETN = '0' then
	      axi_arready <= '0';
	      rd_add_valid <= '0';
	    else
	      if (axi_arready = '0' and S_AXI_ARVALID = '1' and wr_add_valid = '0' and rd_add_valid = '0') then
	        axi_arready <= '1';
	        rd_add_valid <= '1';
	      -- elsif (axi_rvalid = '1' and S_AXI_RREADY = '1' and (axi_arlen_cntr = to_integer (unsigned (S_AXI_ARLEN) - 1))) then
				elsif axi_rvalid = '1' and S_AXI_RREADY = '1' and axi_arlen_cntr = to_integer (unsigned (S_AXI_ARLEN)) then
	      -- preparing to accept next address after current read completion
	        rd_add_valid <= '0';
	      else
	        axi_arready <= '0';
	      end if;
	    end if;
	  end if;
	end process;

	-- PortIdValid_RD <= rd_add_valid;
	PortIdValid_RD <= S_AXI_ARVALID and axi_arready; --  when port_stat_rd_en /= '1';

	-- -- process for latching the PORT_ID_RD
	-- process (rd_add_valid)
	-- begin
	-- 	if rd_add_valid = '1' then
	-- 		PORT_ID_RD <= axi_araddr (C_PORTID_LOW + PORTID_WIDTH - 1  downto C_PORTID_LOW);
	-- 		PORT_ID_RD <= axi_araddr (C_PORTID_HIGH downto C_PORTID_LOW);
	-- 	end if;
	-- end process;

	---------------------------------------------------------------------------------------------
	-- Implement axi_araddr latching

	--This process is used to latch the address when both
	--S_AXI_ARVALID and S_AXI_RVALID are valid.
	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then
	    if S_AXI_ARESETN = '0' then
	      axi_araddr <= (others => '0');
	      axi_arlen_cntr <= 0;
	    else
	      if (axi_arready = '0' and S_AXI_ARVALID = '1' and rd_add_valid = '0') then
	        -- address latching
	        axi_araddr <= S_AXI_ARADDR(C_S_AXI_ADDR_WIDTH - 1 downto 0); ---- start address of transfer
	        axi_arlen_cntr <= 0;
					PORT_ID_RD <= S_AXI_ARADDR (C_PORTID_LOW + PORTID_WIDTH - 1 downto C_PORTID_LOW);-- sRdAddrPortId;
	      elsif((axi_arlen_cntr <= to_integer (unsigned (S_AXI_ARLEN))) and axi_rvalid = '1' and S_AXI_RREADY = '1') then
	        axi_arlen_cntr <= axi_arlen_cntr + 1;

	        case (S_AXI_ARBURST) is
	          when "00" =>  -- fixed burst
	            -- The read address for all the beats in the transaction are fixed
	            axi_araddr     <= axi_araddr;      ----for arsize = 4 bytes (010)
	          when "01" =>  --incremental burst
	            -- The read address for all the beats in the transaction are increments by awsize
	            axi_araddr(C_S_AXI_ADDR_WIDTH - 1 downto ADDR_LSB) <= std_logic_vector (unsigned(axi_araddr(C_S_AXI_ADDR_WIDTH - 1 downto ADDR_LSB)) + 1); --araddr aligned to 4 byte boundary
	            axi_araddr(ADDR_LSB-1 downto 0)  <= (others => '0');  ----for awsize = 4 bytes (010)
	          when "10" =>  --Wrapping burst
	            -- The read address wraps when the address reaches wrap boundary
	            if (ar_wrap_en = '1') then
	              axi_araddr <= std_logic_vector (unsigned(axi_araddr) - (to_unsigned(ar_wrap_size,C_S_AXI_ADDR_WIDTH)));
	            else
	              axi_araddr(C_S_AXI_ADDR_WIDTH - 1 downto ADDR_LSB) <= std_logic_vector (unsigned(axi_araddr(C_S_AXI_ADDR_WIDTH - 1 downto ADDR_LSB)) + 1); --araddr aligned to 4 byte boundary
	              axi_araddr(ADDR_LSB-1 downto 0)  <= (others => '0');  ----for awsize = 4 bytes (010)
	            end if;
	          when others => --reserved (incremental burst for example)
	            axi_araddr(C_S_AXI_ADDR_WIDTH - 1 downto ADDR_LSB) <= std_logic_vector (unsigned(axi_araddr(C_S_AXI_ADDR_WIDTH - 1 downto ADDR_LSB)) + 1);--for arsize = 4 bytes (010)
			  			axi_araddr(ADDR_LSB-1 downto 0)  <= (others => '0');
	        end case;
	      end if;
	    end if;
	  end if;
	end  process;


	---------------------------------------------------------------------------------------------
	-- generating axi_rlast

		process (S_AXI_ARESETN, start_single_burst_read, S_AXI_ARLEN, rnext, S_AXI_ACLK)
		begin
	    if S_AXI_ARESETN = '0' or start_single_burst_read = '1' then
	      axi_rlast <= '0';
	    else
				if unsigned (S_AXI_ARLEN) = 0 then
					axi_rlast <= rnext;
				elsif rising_edge(S_AXI_ACLK) then
		      if ((axi_arlen_cntr = to_integer (unsigned (S_AXI_ARLEN) - 1) and unsigned(S_AXI_ARLEN) >= 2 and rnext = '1') or (unsigned(S_AXI_ARLEN) = 1 and rnext = '1')) then
		        axi_rlast <= '1';
		      else -- if S_AXI_RREADY = '0' or (axi_rlast = '1' and unsigned (S_AXI_ARLEN) = 1) then
		        axi_rlast <= '0';
		      end if;
		    end if;
		  end if;
		end  process;


	-- read_burst_counter counter keeps track with the number of burst transaction initiated
  -- against the number of burst transactions the master needs to initiate
  process(S_AXI_ACLK)
  begin
   if (rising_edge (S_AXI_ACLK)) then
     if S_AXI_ARESETN = '0' then --or init_rxn_pulse = '1' then
       read_burst_counter <= (others => '0');
     else
       if (axi_arready = '1' and S_AXI_ARVALID = '1') then
        --  if (read_burst_counter(7) = '0')then
           read_burst_counter <= std_logic_vector(unsigned(read_burst_counter) + 1);
        --  end if;
       end if;
     end if;
   end if;
  end process;


	rnext <= S_AXI_RREADY and axi_rvalid;
	wnext <= S_AXI_WVALID and axi_wready;

	---------------------------------------------------------------------------------------------
	-- Implement axi_rvalid generation

	-- axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both
	-- S_AXI_ARVALID and axi_arready are asserted. The slave registers
	-- data are available on the axi_rdata bus at this instance. The
	-- assertion of axi_rvalid marks the validity of read data on the
	-- bus and axi_rresp indicates the status of read transaction.axi_rvalid
	-- is deasserted on reset (active low). axi_rresp and axi_rdata are
	-- cleared to zero on reset (active low).

	process (S_AXI_ACLK)
	begin
    if S_AXI_ARESETN = '0' then
      axi_int_rvalid <= '0';
      axi_rresp  <= "00";
	  elsif rising_edge(S_AXI_ACLK) then
			if unsigned (S_AXI_ARLEN) = 1 then
	      if (S_AXI_ARVALID = '1' and axi_arready = '1') then
					-- if (port_stat_rd_en = '0') then
						if  PORT_EMPTY_RD /= '1' then
			        axi_int_rvalid <= '1';
			        axi_rresp  <= "00"; -- 'OKAY' response
						else
							axi_int_rvalid <= '0';
							axi_rresp  <= "10"; -- 'SLVERR' response
						end if;
					-- else
					-- 	axi_int_rvalid <= '1';
					-- 	axi_rresp  <= "00"; -- 'OKAY' response
					-- end if;
				else
					axi_int_rvalid <= '0';
				end if;
			else
				if  axi_int_rvalid = '0' and rd_add_valid = '1' and read_beat_counter <= axi_arlen_cntr then
					axi_int_rvalid <= '1';
				elsif axi_int_rvalid = '1' and ((read_beat_counter >= axi_arlen_cntr and S_AXI_RREADY = '0') or read_beat_counter >= to_integer (unsigned (S_AXI_ARLEN))) then
					axi_int_rvalid <= '0';
				end if;
	    end if;
	  end if;
	end process;

	-- Burst length counter. Uses extra counter register bit to indicate
	-- terminal count to reduce decode logic
	  process(S_AXI_ACLK)
	  begin
	    if S_AXI_ARESETN = '0' or start_single_burst_read = '1' then
	      read_beat_counter <= 0;
	    elsif rising_edge (S_AXI_ACLK) then
	      if axi_int_rvalid = '1' then
	        read_beat_counter <= read_beat_counter + 1;
	      end if;
	    end if;
	  end process;


	process (S_AXI_ACLK)
	begin
    if S_AXI_ARESETN = '0' then
      axi_rvalid <= '0';
	  elsif rising_edge(S_AXI_ACLK) then
			if axi_int_rvalid = '1' then
				axi_rvalid <= '1';
			elsif (axi_rvalid = '1' and S_AXI_RREADY = '1' and (axi_arlen_cntr = to_integer (unsigned (S_AXI_ARLEN) - 1))) or (read_beat_counter >= axi_arlen_cntr + 1 and S_AXI_RREADY = '1') then
      -- elsif axi_arlen_cntr = std_logic_vector (unsigned (S_AXI_ARLEN)) then
        axi_rvalid <= '0';
			end if;
		end if;
	end  process;

	---------------------------------------------------------------------------------------------
	-- Implement axi_rdata latching

	-- PORT_RD <= (start_single_burst_read or rnext) when BUFF_EMPTY_RD /= '1' and port_stat_rd_en /= '1' else '0';
	-- PORT_RD <= axi_int_rvalid when BUFF_EMPTY_RD /= '1' and port_stat_rd_en /= '1' else '0';
	-- axi_rdata <= PORT_DATA_RD when port_stat_rd_en = '0' else int_mem_rd_data (mem_select);



	-- process for handling the rd_state
	-- slave_rd_proc : process(S_AXI_ACLK, S_AXI_ARESETN)
	-- begin
	-- 	if S_AXI_ARESETN = '0' then
	-- 		read_state <= IDLE;
	-- 	elsif rising_edge(S_AXI_ACLK) then
	-- 		read_state <= read_nextstate;
	-- 	end if;
	-- end process;


	fsm_cmb : process (S_AXI_ARVALID, start_single_burst_read, PORT_EMPTY_RD, BUFF_EMPTY_RD, rnext)
	begin
		case read_state is
			when IDLE =>
				if S_AXI_ARVALID = '1' then
					read_state <= CHECK_READ;
				end if;
			when CHECK_READ =>
				if start_single_burst_read = '1' then
					if PORT_EMPTY_RD /= '1' then
						read_state <= READ_ACK;
					else
						read_state <= READ_DENIED;
					end if;
				end if;
			when READING =>
				if BUFF_EMPTY_RD = '1' then
					read_state <= IDLE;
				end if;
				when READ_ACK =>
					if rnext = '1' then
						read_state <= READING;
					end if;
			when READ_DENIED =>
			if PORT_EMPTY_RD = '0' then
					read_state <= READ_ACK;
			-- elsif S_AXI_ARVALID = '1' then
			-- 		read_state <= CHECK_READ;
			end if;
		end case;
	end process;


	-- fsm_cmb : process (read_state, start_single_burst_read, PORT_EMPTY_RD, BUFF_EMPTY_RD, rnext)
	-- begin
	-- 	read_nextstate <= read_state;
	-- 	case read_state is
	-- 		when IDLE =>
	-- 			if start_single_burst_read = '1' then
	-- 				read_nextstate <= CHECK_READ;
	-- 			end if;
	-- 		when CHECK_READ =>
	-- 			if PORT_EMPTY_RD /= '1' then
	-- 				read_nextstate <= READ_ACK;
	-- 			else
	-- 				read_nextstate <= READ_DENIED;
	-- 			end if;
	-- 		when READING =>
	-- 			if BUFF_EMPTY_RD = '1' then
	-- 				read_nextstate <= IDLE;
	-- 			end if;
	-- 			when READ_ACK =>
	-- 				if rnext = '1' then
	-- 					read_nextstate <= READING;
	-- 				end if;
	-- 		when READ_DENIED =>
	-- 		if PORT_EMPTY_RD = '0' then
	-- 			read_nextstate <= IDLE;
	-- 		end if;
	-- 	end case;
	-- end process;

	-- ------------------------------------------
	-- -- Code to access the internal TTEL registers
	-- ------------------------------------------
	-- process for generation of port_stat_rd_en
	-- port_stat_rd_en <= port_status_read_bit and S_AXI_ARVALID and axi_arready;


	process (S_AXI_ARESETN, S_AXI_ACLK) -- S_AXI_AWVALID, sWrAddrPortId1
	begin
		if S_AXI_ARESETN = '0' then
			port_stat_rd_en <= '0';
		elsif rising_edge (S_AXI_ACLK) then
			if S_AXI_ARVALID = '1' and port_status_read_bit = '1' and axi_arready = '1' then
				port_stat_rd_en <= '1';
			elsif axi_rlast = '1' then
				port_stat_rd_en <= '0';
			end if;
		end if;
	end process;

	--
	-- process (S_AXI_ARESETN, port_status_read_bit, S_AXI_ARVALID, axi_arready, axi_rlast) -- S_AXI_AWVALID, sWrAddrPortId1
	-- begin
	-- 	if S_AXI_ARESETN = '0' then
	-- 		port_stat_rd_en <= '0';
	-- 		-- port_conf_wr_en <= '0';
	-- 	elsif port_stat_rd_en = '0' then
	-- 		if S_AXI_ARVALID = '1' and port_status_read_bit = '1' and axi_arready = '1' then
	-- 			port_stat_rd_en <= '1';
	-- 		-- else
	-- 		-- 	port_stat_rd_en <= '0';
	-- 		end if;
	-- 	elsif port_stat_rd_en = '1' then
	-- 		if axi_rlast = '1' then
	-- 			port_stat_rd_en <= '0';
	-- 		end if;
	-- 		-- if S_AXI_AWVALID = '1' then
	-- 		-- 	if sWrAddrPortId >= NR_PORTS then
	-- 		-- 		port_conf_wr_en <= '1';
	-- 		-- 	else
	-- 		-- 		port_conf_wr_en <= '0';
	-- 		-- 	end if;
	-- 		-- end if;
	-- 	end if;
	-- end process;


	-- process (S_AXI_ARESETN, start_single_burst_read, start_single_burst_write)
	-- begin
	-- 	if S_AXI_ARESETN = '0' then
	-- 		mem_wr_address <= (others => '0');
	-- 		mem_rd_address <= (others => '0');
	-- 	else
	-- 		if start_single_burst_read = '1' then
	--   		-- mem_rd_address <= axi_araddr (ADDR_LSB + MEM_ADDR_WIDTH - 1 downto ADDR_LSB);
	-- 			mem_rd_address <= axi_araddr (MEM_ADDR_WIDTH - 1 downto 0);
	-- 		elsif start_single_burst_write = '1' then
	-- 			-- mem_wr_address <= axi_awaddr (ADDR_LSB + MEM_ADDR_WIDTH - 1 downto ADDR_LSB)
	-- 			mem_wr_address <= axi_awaddr (MEM_ADDR_WIDTH - 1 downto 0)
	-- 		end if;
	-- 	end if;
	-- end process;

	-- sIntMemRdEn  <= rnext when port_stat_rd_en = '1' else '0';
	-- sIntMemWrEn  <= wnext when port_conf_wr_en = '1' else '0';

	-- todo: a process is needed for mem_select
	-- sIntMemRdEn (mem_select) <= axi_int_rvalid when port_stat_rd_en = '1' else '0';

	-- sIntMemRdEn (mem_select) <= start_single_burst_read or rnext when port_stat_rd_en = '1' else '0';
	-- sIntMemWrEn (mem_select) <= wnext when port_conf_wr_en = '1' else '0';


	-- process (int_mem_targeted, S_AXI_ARESETN, rd_add_valid, wr_add_valid)
	-- begin
	-- 	if S_AXI_ARESETN = '0' or int_mem_targeted = '0' then
	-- 		sIntMemWrEn <= (others => '0');
	-- 		sIntMemRdEn <= (others => '0');
	-- 	elsif int_mem_targeted = '1' then
	-- 		if rd_add_valid = '1' then
	--   		sIntMemRdEn (to_integer (unsigned (mem_rd_address))) <= '1';
	-- 		elsif wr_add_valid = '1' then
	-- 			sIntMemWrEn (to_integer (unsigned (mem_wr_address))) <= '1';
	-- 		end if;
	-- 	end if;
	-- end process;

	-- implement Block RAM(s)
	--Output register or memory read data

	-- process (ttel_int_mem, axi_rvalid )
	-- begin
	--   if (axi_rvalid = '1') then
	--     -- When there is a valid read address (S_AXI_ARVALID) with
	--     -- acceptance of read address by the slave (axi_arready),
	--     -- output the read dada
	--     axi_rdata <= ttel_int_mem(0);  -- memory range 0 read data
	--   else
	--     axi_rdata <= (others => '0');
	--   end if;
	-- end process;


	end arch_imp;
