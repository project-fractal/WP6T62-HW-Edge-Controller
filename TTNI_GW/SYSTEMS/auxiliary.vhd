------------------------------------------------------------------------------------------------------------
-- Project		: SAFEPOWER
-- Module       : package "auxiliary"
-- File			: auxiliary.vhd
-- Author		: Hamidreza Ahmadian
-- created		: August, 13th 2015
-- last mod. by	: Hamidreza Ahmadian
-- last mod. on	: August, 13th 2015
-- contents		: helper functions and helper procedures
------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------
-- library includes
------------------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
--use IEEE.std_logic_unsigned.all;
use IEEE.STD_LOGIC_TEXTIO.all;

library STD;
use STD.TEXTIO.all;

library unisim;
use unisim.vcomponents.all;
use unisim.vpkg.all;

library SYSTEMS;
use SYSTEMS.system_parameter.all;	-- PHYNAME_WIDTH and TIMEFORMAT_COUNTER_WIDTH
------------------------------------------------------------------------------------------------------------
-- package "auxiliary"
------------------------------------------------------------------------------------------------------------
  -- use SAFEPOWER.auxiliary.all;         	-- helper functions and helper procedures

package auxiliary is

------------------------------------------------------------------------------------------------------------
-- declaration of subprograms
------------------------------------------------------------------------------------------------------------

	function clogb2 (bit_depth : integer) return integer;
	function ld(m : integer) return integer;
	function max(a : integer; b : integer) return integer;
	function min(a : integer; b : integer) return integer;
	function calc_word(vector : integer; width : integer) return integer;
	function calc_byte(i : integer) return integer;
	function GetWEWidth (bram_size : in string; device : in string; wr_width : in integer) return integer;
    function GetADDRWidth (d_width : in integer; func_bram_size : in string; device : in string) return integer;
    type port_semantics_array is array (0 to 15) of string (1 to 5);
    type at_phyname    is array (0 to 15) of std_logic_vector (PHYNAME_WIDTH - 1 downto 0); 
    type mint_artype    is array (0 to 15) of std_logic_vector(TIMEFORMAT_COUNTER_WIDTH-1 downto 0);
    type ptype_artype   is array (0 to 15) of std_logic_vector (1 downto 0);
    constant TT : std_logic_vector (1 downto 0) := "00";
    constant RC1 : std_logic_vector (1 downto 0) := "01";
    constant RC2 : std_logic_vector (1 downto 0) := "10";
    constant BE : std_logic_vector (1 downto 0) := "11";
--    impure function init_nr_ports (ttel_name : string) return natural;
--    constant INIT_PATH : string := "/home/hamid/Projects/LRS/init/";

------------------------------------------------------------------------------------------------------------

end auxiliary;

------------------------------------------------------------------------------------------------------------
-- body of the package "auxiliary"
------------------------------------------------------------------------------------------------------------

package body auxiliary is

------------------------------------------------------------------------------------------------------------
-- implementation of subprograms
------------------------------------------------------------------------------------------------------------

	function clogb2 (bit_depth : integer) return integer is
	 	variable depth  : integer := bit_depth;
	 	variable count  : integer := 1;
	 begin
	 	 for clogb2 in 1 to bit_depth loop  -- Works for up to 32 bit integers
	      if (bit_depth <= 2) then
	        count := 1;
	      else
	        if(depth <= 1) then
	 	       count := count;
	 	     else
	 	       depth := depth / 2;
	          count := count + 1;
	 	     end if;
	 	   end if;
	   end loop;
	   return(count);
	 end function clogb2;


	-- logarithm dualis
	function ld(m : integer) return integer is
	begin
	-- NOTE: We do NOT start from 0, because ld() is sometimes used as upper bound of a vector. In case of 0, this would lead to 0-1, which causes
	-- invalid vector boundaries and thus a compiler error.
		for n in 1 to integer'high
		loop
			if (2**n >= m) then
				return n;
			end if;
		end loop;
	end function ld;

	-- maximum
	function max(a : integer; b : integer) return integer is
	begin
		if a > b then
			return a;
		else
			return b;
		end if;
	end function max;

	-- minimum
	function min(a : integer; b : integer) return integer is
	begin
		if a < b then
			return a;
		else
			return b;
		end if;
	end function min;

	-- calculate number of data words to wrap a given vector width
	function calc_word(vector : integer; width : integer) return integer is
	begin
		for n in 1 to integer'high
		loop
			if (vector <= (n * width)) then
				return n;
			end if;
		end loop;
	end function calc_word;

	-- calculate number of bytes to wrap a given vector width
	function calc_byte(i : integer) return integer is
	begin
		return calc_word(vector=>i, width=>8);
	end function calc_byte;

	function GetWEWidth (
    bram_size : in string;
    device : in string;
    wr_width : in integer
    ) return integer is
    variable func_width : integer;
  begin
    if(DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") then
      if bram_size= "18Kb" then
        if wr_width <= 9 then
          func_width := 1;
        elsif wr_width > 9 and wr_width <= 18 then
          func_width := 2;
        elsif wr_width > 18 and wr_width <= 36 then
          func_width := 4;
        end if;
      elsif bram_size = "36Kb" then
        if wr_width <= 9 then
          func_width := 1;
        elsif wr_width > 9 and wr_width <= 18 then
          func_width := 2;
        elsif wr_width > 18 and wr_width <= 36 then
          func_width := 4;
        elsif wr_width > 36 and wr_width <= 72 then
          func_width := 8;
        end if;
      else
        func_width := 8;
      end if;
   -- begin s1
    elsif(DEVICE = "SPARTAN6") then
      if bram_size = "9Kb" then
        if wr_width <= 9 then
          func_width := 1;
        elsif wr_width > 9 and wr_width <= 18 then
          func_width := 2;
        elsif wr_width > 18 and wr_width <= 36 then
          func_width := 4;
        else
          func_width := 4;
        end if;
      elsif bram_size = "18Kb" then
        if wr_width <= 9 then
          func_width := 1;
        elsif wr_width > 9 and wr_width <= 18 then
          func_width := 2;
        elsif wr_width > 18 and wr_width <= 36 then
          func_width := 4;
        else
          func_width := 4;
        end if;
     end if; -- end s1
    else
      func_width := 8;
    end if;
    return func_width;
  end;

	function GetADDRWidth (
    d_width : in integer;
    func_bram_size : in string;
    device : in string
    ) return integer is
    variable func_width : integer;
  begin
    if (DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "SPARTAN6" or DEVICE = "7SERIES") then
      case d_width is
        when 1 => if (func_bram_size = "9Kb") then
                    func_width := 13;
                  elsif (func_bram_size = "18Kb") then
                    func_width := 14;
                  else
                    func_width := 15;
                  end if;
        when 2 => if (func_bram_size = "9Kb") then
                    func_width := 12;
                  elsif (func_bram_size = "18Kb") then
                    func_width := 13;
                  else
                    func_width := 14;
                  end if;
        when 3|4 => if (func_bram_size = "9Kb") then
                    func_width := 11;
                  elsif (func_bram_size = "18Kb") then
                    func_width := 12;
                  else
                    func_width := 13;
                  end if;
        when 5|6|7|8|9 => if (func_bram_size = "9Kb") then
                    func_width := 10;
                   elsif (func_bram_size = "18Kb") then
                    func_width := 11;
                  else
                    func_width := 12;
                  end if;
        when 10 to 18 => if (func_bram_size = "9Kb") then
                    func_width := 9;
                   elsif (func_bram_size = "18Kb") then
                     func_width := 10;
                   else
                     func_width := 11;
                   end if;
        when 19 to 36 => if (func_bram_size = "9Kb") then
                    func_width := 8;
                   elsif (func_bram_size = "18Kb") then
                     func_width := 9;
                   elsif (func_bram_size = "36Kb") then
                     func_width := 10;
                   else
                     func_width := 14;
                   end if;
        when 37 to 72 => if (func_bram_size = "36Kb") then
                     func_width := 9;
                    end if;
        when others => func_width := 15;
      end case;
  else
    func_width := 15;
  end if;
    return func_width;
  end;
  

end auxiliary;
