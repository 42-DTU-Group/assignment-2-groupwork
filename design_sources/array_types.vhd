library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package array_types is
    type t_en_array is array (natural range <>, natural range <>) of std_logic;
    type t_1d_data_array is array (natural range <>) of unsigned(7 downto 0);
    type t_2d_data_array is array (natural range <>, natural range <>) of unsigned(7 downto 0);
end package;

package body array_types is
end package body;
