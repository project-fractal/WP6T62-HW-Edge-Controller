---------------------------------------------------------------------------------------------------
-- Project		: SAFEPOWER
-- Module       : PU
-- File			: priorityunit.vhd
-- Author		: Hamidreza Ahmadian
-- created		: November, 3rd 2015
-- last mod. by	: Hamidreza Ahmadian
-- last mod. on	: October, 10th 2015
-- contents		: Priority Unit
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
-- library includes
---------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
-- use IEEE.std_logic_arith.all;	-- for conv_integer
-- use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.ALL;


library SAFEPOWER;
use SAFEPOWER.TTEL.all;        		-- constants, datatypes, and component declarations of the current TTEL
use SAFEPOWER.ttel_parameter.all;	-- parameters of the current NoC instance

library SYSTEMS;
use SYSTEMS.system_parameter.all;	-- parameters of the current NoC instance
use SYSTEMS.auxiliary.all;         	-- for extracting configuration parameters from the files


entity priorityunit is
  generic
  (
    TIMELY_BLOCK			: std_logic := '1';
    NR_OUT_PORTS        : integer;
    C_PQ_LENGTH       : integer := 64
  );
  port
  (
    pNewMsg           : in std_logic_vector (NR_OUT_PORTS - 1 downto 0);
    pPortType         : in vt_porttype (NR_OUT_PORTS - 1 downto 0);

    pInjectETMsg      : in std_logic;
    pETPortIdOut      : out t_portid;
    pETDeqPort        : out std_logic;
    pPQEmpty          : out std_logic;

    PQEmpty           : out std_logic_vector (C_PQ_NUMBERS - 1 downto 0);

    err               : out std_logic_vector (1 downto 0);

    clk               : in std_logic;
    reset_n           : in std_logic
  );
end priorityunit;

architecture safepower of priorityunit is
  ---------------------------------------------------------------------------------------------------
  -- Constants
  ---------------------------------------------------------------------------------------------------
  constant C_PQU_ADDRWIDTH    : integer := ld (C_PQ_LENGTH);
  constant C_PQU_WORDWIDTH    : integer := PORTID_WIDTH;

  constant C_NO_NEW_MSG       : std_logic_vector (NR_OUT_PORTS - 1 downto 0):= (others => '0');
  ---------------------------------------------------------------------------------------------------
  -- Components declarations
  ---------------------------------------------------------------------------------------------------
  component ent_buffer
    Generic (
      AddrWidth     : natural := 4;  -- Depth of the RAM = 2^AddrWidth
      WordWidth     : natural := 32
    );
    Port (
      enq           : in std_logic;
      din           : in std_logic_vector (WordWidth - 1 downto 0);
      full          : out std_logic;
      deq           : in std_logic;
      dout          : out std_logic_vector (WordWidth - 1 downto 0);
      empty         : out std_logic;
      clk           : in std_logic;
      reset_n       : in std_logic
    );
  end component;


  ---------------------------------------------------------------------------------------------------
  -- Signals declaration
  ---------------------------------------------------------------------------------------------------
  type data_line_type is array (C_PQ_NUMBERS - 1 downto 0) of std_logic_vector (C_PQU_WORDWIDTH - 1 downto 0);
  type control_line_type is array (C_PQ_NUMBERS - 1 downto 0) of std_logic;

  signal wPQEnq                   : control_line_type;
  signal wPQDin                   : data_line_type;
  signal wPQFull                  : control_line_type;
  signal wPQDeq                   : control_line_type;
  signal wPQDout                  : data_line_type;
  signal wPQEmpty                 : control_line_type;

  signal rNewMsg                  : std_logic := '0';

  signal rPortId                  : integer;

  signal rInjectETMsg             : std_logic := '0';
  signal rInjectETMsg_ff          : std_logic := '0';
  signal rInjectETMsg_ff2         : std_logic := '0';
  signal rInjectETMsg_pulse       : std_logic := '0';

  signal rPqId                     : integer := 0;



begin

--  process (clk, reset_n)
--  variable temp_pqempty   : std_logic;
--  variable cntr          : integer;
--  begin
--    if reset_n = '0' then
--        pPQEmpty <= '1';
--    elsif rising_edge (clk) then
--        temp_pqempty  := wPQEmpty (1);
--        for cntr in 2 to C_PQ_NUMBERS - 1 loop
--            temp_pqempty := temp_pqempty and wPQEmpty (cntr);
--        end loop;
--        pPQEmpty <= temp_pqempty;
--    end if;
--  end process;

  process (wPQEmpty)
  variable temp_pqempty   : std_logic;
  variable cntr          : integer;
  begin
    temp_pqempty  := wPQEmpty (1);
    for cntr in 2 to C_PQ_NUMBERS - 1 loop  --
      temp_pqempty := temp_pqempty and wPQEmpty (cntr); --£¿£¿
    end loop;
    pPQEmpty <= temp_pqempty;
  end process;

  pq_generate: for i in 0 to C_PQ_NUMBERS - 1
  generate
    -- the highest priority has the lowest index. e.g., TT-> 0, RC1-> 1, RC2-> 2, BE-> 3
    priorityqueue: ent_buffer
    generic map (
      AddrWidth => C_PQU_ADDRWIDTH,
      WordWidth => C_PQU_WORDWIDTH
    )
    port map (
      enq => wPQEnq (i),
      din => wPQDin (i),
      full => wPQFull (i),
      deq => wPQDeq (i),
      dout => wPQDout (i),
      empty => wPQEmpty (i),
      clk => clk,
      reset_n => reset_n
    );
  end generate;

  -- process for finding the port id
  process (pNewMsg, reset_n)
  begin
    if reset_n = '0' then
      rPortId <= 0;
    else
      if pNewMsg = C_NO_NEW_MSG then
        rNewMsg <= '0';
      else
        for i in 0 to NR_OUT_PORTS - 1 loop
          if pNewMsg (i) = '1' then
            rPortId <= i;
            rNewMsg <= '1';
            exit;
          end if;
        end loop;
      end if;
    end if;
  end process;



  -- process for adding a new entry to the PQs
  process (clk)
  begin
    if rising_edge (clk) then
      if rNewMsg = '1' then
        wPQEnq (to_integer (unsigned (pPortType (rPortId)))) <= '1';
        wPQDin (to_integer (unsigned (pPortType (rPortId)))) <= std_logic_vector (to_unsigned (rPortId, C_PQU_WORDWIDTH));

     else
        for i in 0 to C_PQ_NUMBERS - 1 loop
          wPQEnq (i) <= '0';
          wPQDin (i) <= (others => '0');
        end loop;
      end if;
    end if;
  end process;


  -- process for putting the PortId of the highest priority ET port
  process (clk)
  begin
    if rising_edge (clk) then
      if rInjectETMsg_pulse = '1' then
        for i in 1 to C_PQ_NUMBERS - 1 loop
          if wPQEmpty (i) /= '1' then
            -- rHPPortFound <= '1';
            rPqId <= i;
            wPQDeq (i) <= '1';
            exit;
          end if;
        end loop;
      else
        for i in 0 to C_PQ_NUMBERS - 1 loop
          wPQDeq (i) <= '0';
        end loop;
      end if;
    end if;
  end process;

  pETPortIdOut <= wPQDout (rPqId); ---??

  process (clk)
  begin
  if rising_edge (clk) then
    if (reset_n = '0') then
      pETDeqPort <= '0';
    elsif wPQDeq (rPqId) = '1' then
      pETDeqPort <= '1';
    else
      pETDeqPort <= '0';
    end if;
  end if;
end process;


  --Generate a pulse for pInjectETMsg
	process(clk)
	begin
	  if rising_edge (clk) then
	    if (reset_n = '0' ) then
        rInjectETMsg_ff <= '0';
	      rInjectETMsg_ff2 <= '0';
	    else
	      rInjectETMsg_ff <= pInjectETMsg;
	      rInjectETMsg_ff2 <= rInjectETMsg_ff;
	    end if;
	  end if;
	end process;
  rInjectETMsg_pulse	<= (NOT rInjectETMsg_ff2)  AND  rInjectETMsg_ff;



end safepower;
