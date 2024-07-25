--
-- speedcontrol.vhd
--
-- This file's source taken from https://github.com/MiSTer-devel/Gameboy_MiSTer/blob/master/rtl/speedcontrol.vhd
-- This specific module was written by and added by Robert Peip (https://github.com/RobertPeip/)
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity speedcontrol is
   port
   (
      clk_sys     : in     std_logic;
      ce          : out    std_logic := '0';
      ce_2x       : buffer std_logic := '0'
   );
end entity;

architecture arch of speedcontrol is
    --creating ce and ce_2x
	signal clkdiv           : unsigned(2 downto 0) := (others => '0');

begin
    process(clk_sys)
   	begin
    	if falling_edge(clk_sys) then
			ce          <= '0';
        	ce_2x       <= '0';

			clkdiv <= clkdiv + 1;
            if (clkdiv = "000") then
                ce <= '1';
            end if;
            if (clkdiv(1 downto 0) = "00") then
                ce_2x    <= '1';
            end if;
		end if;
	end	process;
end architecture;