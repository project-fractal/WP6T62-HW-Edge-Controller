---------------------------------------------------------------------------------------------------
-- Project		: SAFEPOWER
-- Module       : OUT port DQ Unit
-- File			: outportdequnit.vhd
-- Author		: Hamidreza Ahmadian
-- created		: November, 3rd 2015
-- last mod. by	: Hamidreza Ahmadian
-- last mod. on	:
-- contents		: Top level and architecture
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
use SAFEPOWER.ttel_parameter.all;	-- parameters of the current NoC instance

library SYSTEMS;
use SYSTEMS.system_parameter.all;	-- parameters of the current NoC instance
use SYSTEMS.auxiliary.all;         	-- for extracting configuration parameters from the files


entity outportdequnit is
   generic
   (
    NR_OUT_PORTS      : integer
   );
  port
  (
    pTTDeqEbu             : in std_logic;
    pTTPortIdEbu          : in std_logic_vector (PORTID_WIDTH - 1 downto 0);
    pETDeqEbu             : in std_logic;
    pETOpIdEbu            : in std_logic_vector (OPID_WIDTH - 1 downto 0);
    pBypassLetIt          : out std_logic;

    pAxiTxDone            : in std_logic;
    pOUTPortEmpty         : in std_logic_vector (NR_OUT_PORTS - 1 downto 0);
    pOUTBufferFull        : in std_logic_vector (NR_OUT_PORTS - 1 downto 0);
    pPortType             : in vt_porttype (NR_OUT_PORTS - 1 downto 0);

    -- pPortDeqEn            : out std_logic_vector (NR_OUT_PORTS - 1 downto 0);
    pTrigAxiOut           : out std_logic;
    pOUTPortId            : out t_portid;
    -- pError              : out t_errorid;
    clk                   : in std_logic;
    reset_n               : in std_logic
  );
end outportdequnit;

architecture safepower of outportdequnit is

component priorityunit
  generic
  (
    NR_OUT_PORTS      : integer;
    -- C_PQ_NUMBERS      : integer := 3;      -- TODO: should be parameterized
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
end component;


component outportdeqselector
    generic
(
  NR_OUT_PORTS      : integer
);
  port
  (
    pTTDeqIn            : in std_logic;
    pTTPortId           : in t_portid;
    pETDeqIn            : in std_logic;
    pETPortId           : in t_portid;
    pOUTPortEmpty       : in std_logic_vector (NR_OUT_PORTS - 1 downto 0);
    -- pPortDeqEn          : out std_logic_vector (NR_OUT_PORTS - 1 downto 0);
    -- pError              : out t_errorid;
    pOUTPortId          : out t_portid;
    pTrigAxiOut         : out std_logic;
    clk                 : in std_logic;
    reset_n             : in std_logic
  );
end component;

component etopcodedecoder
  port
  (
    pAxiTxDone              : in std_logic;
    pETDeqIn                : in std_logic;
    pPQEmpty                : in std_logic;
    pOpIdIn_Ebu             : in std_logic_vector (OPID_WIDTH - 1 downto 0);
    pInjectETMsg            : out std_logic;
    pBypassLetIt            : out std_logic;
    clk                     : in std_logic;
    reset_n                 : in std_logic

  );
end component;


  signal wETDeqIn             : std_logic;
  signal wETPortId            : std_logic_vector (PORTID_WIDTH - 1 downto 0);
  signal wInjectETMsg         : std_logic := '0';
  signal wPQEmpty              : std_logic;

  begin

    OUTPDQSEL_inst: outportdeqselector
    generic map (
        NR_OUT_PORTS => NR_OUT_PORTS
    )
    port map (
      pTTDeqIn => pTTDeqEbu,
      pTTPortId => pTTPortIdEbu,
      pETDeqIn => wETDeqIn,
      pETPortId => wETPortId,
      pOUTPortEmpty => pOUTPortEmpty,
      pOUTPortId => pOUTPortId,
      pTrigAxiOut => pTrigAxiOut,
      -- pPortDeqEn => pPortDeqEn,
      clk => clk,
      reset_n => reset_n
    );

    PU_inst: priorityunit
    generic map (
      NR_OUT_PORTS => NR_OUT_PORTS
    )
    port map (
    pNewMsg => pOUTBufferFull,
    pPortType => pPortType,
    pInjectETMsg => wInjectETMsg,
    pPQEmpty    => wPQEmpty,
    pETPortIdOut => wETPortId,
    pETDeqPort => wETDeqIn,
    clk => clk,
    reset_n => reset_n

    );

    ETOPDECODER_inst: etopcodedecoder
    port map (
      pAxiTxDone => pAxiTxDone,
      pETDeqIn => pETDeqEbu,
      pOpIdIn_Ebu => pETOpIdEbu,
      pPQEmpty    => wPQEmpty,
      pInjectETMsg => wInjectETMsg,
      pBypassLetIt => pBypassLetIt,
      clk => clk,
      reset_n => reset_n
    );

--    inject_et_msg_gen: if TIMELY_BLOCK = '0'
--    generate
--        wInjectETMsg2 <= '1';
--    end generate;


--    inject_et_msg_gen: if TIMELY_BLOCK = '1'
--    generate
--        wInjectETMsg2 <= wInjectETMsg;
--    end generate;

end safepower;
