-- SPDX-License-Identifier: Apache-2.0
--
-- A small design that uses the IEEE libraries, so that the toolchain's
-- standard libraries are read as well as its binary run.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity prebuilt_tb is
end entity;

architecture sim of prebuilt_tb is
begin
    process
        variable sum : unsigned(7 downto 0) := (others => '0');
    begin
        for i in 1 to 10 loop
            sum := sum + to_unsigned(i, 8);
        end loop;
        assert sum = 55 report "the sum is wrong" severity failure;
        report "ran under the prebuilt NVC";
        wait;
    end process;
end architecture;
