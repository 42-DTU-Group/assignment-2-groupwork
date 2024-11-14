library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.array_types.all;

entity conv is
    port (
        data_in  : in  t_1d_data_array(1 to 8);
        data_out : out unsigned(7 downto 0)
    );
end conv;

architecture behaviour of conv is
begin
    -- The input data surrounding the convolution pixel 'c' uses the indices
    -- 1 2 3
    -- 4 c 5
    -- 6 7 8

    -- TODO
end behaviour;

