----------------------------------------------------------------------------------------------------------
-- Project		: TTSoC-NG
-- Module       : VectorCoder
-- File			: vectorcoder.vhd
-- Author		: Hamidreza Ahmadian
-- created		: August, 13th 2015
-- last mod. by	: Hamidreza Ahmadian
-- last mod. on	: August, 13th 2015
-- contents		: vector to (multiplexer) selector coder
----------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------------
-- library includes
----------------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

library SYSTEMS;
use SYSTEMS.auxiliary.all;    	-- helper functions and helper procedures

----------------------------------------------------------------------------------------------------------
-- entity declaration
----------------------------------------------------------------------------------------------------------

entity VectorCoder is
	generic
	(
		INVECTOR_WIDTH	: integer
	);
	port
	(
		-- input vector
		InVector	: in std_logic_vector(INVECTOR_WIDTH-1 downto 0);
		-- output vector
		OutVector	: out std_logic_vector(ld(INVECTOR_WIDTH)-1 downto 0);
		-- signaling validity of output vector
		OutEna		: out std_logic
	);
end VectorCoder;

----------------------------------------------------------------------------------------------------------
-- behavioural architecture
----------------------------------------------------------------------------------------------------------

architecture behavioural of VectorCoder is

	signal sEnable		: std_logic;
	signal sOut			: std_logic_vector(ld(INVECTOR_WIDTH)-1 downto 0);

begin

	ASSIGN : process(InVector)
		variable tmp : std_logic;
	begin
	-- universal decoder algorithm
		for d in 0 to ld(INVECTOR_WIDTH)-1
		loop
			tmp := '0';
			for c in 0 to (2 ** (ld(INVECTOR_WIDTH) - 1 - d))-1
			loop
				for l in 0 to (2 ** d) - 1
				loop
					tmp := tmp or InVector(2**d + c*(2**(d+1)) + l);--gaowei: eg: jige gaoyiwei d shu 
					                                                --diwei: souyoud shu 
				end loop;
			end loop;
			sOut(d) <= tmp;
		end loop;
	end process;

	ENA : process(InVector)
		variable tmp : std_logic;
	begin
		tmp := InVector(0);
		for i in 1 to INVECTOR_WIDTH-1
		loop
			tmp := tmp xor InVector(i);
		end loop;
		sEnable <= tmp;
	end process;

-- NOTES:
--	*) 2 ** (ld(INVECTOR_WIDTH)-1-d)	... no. of clusters
--	*) 2 ** d						... width of a cluster

----------------------------------------------------------------------------------------------------------
-- wire-through
----------------------------------------------------------------------------------------------------------

	OutVector <= sOut;
	OutEna <= sEnable;

end behavioural;
