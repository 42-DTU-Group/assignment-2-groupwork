library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.array_types.all;

entity convs is
    generic (
        n        : natural                              -- number of convs
    );
    port (
        data_in  : in  t_2d_data_array(1 to n, 1 to 8); -- input data.
        data_out : out t_1d_data_array(1 to n)          -- output data.
    );
end convs;

architecture behaviour of convs is
    component conv
        port (
            data_in  : in  t_1d_data_array(1 to 8);
            data_out : out unsigned(7 downto 0)
        );
    end component;

    signal data_in_1d : t_1d_data_array(1 to 8*n);
begin
    -- flatten the 2d input array to a 1d array
    gen_flatten_data_in_i:
    for i in 1 to n generate
        gen_flatten_data_in_j:
        for j in 1 to 8 generate
            data_in_1d(j+8*(i-1)) <= data_in(i, j);
        end generate gen_flatten_data_in_j;
    end generate gen_flatten_data_in_i;

    gen_conv_i:
    for i in 1 to n generate
        gen_conv: conv
        port map (
            data_in  => data_in_1d(1+8*(i-1) to 8*i),
            data_out => data_out(i)
        );
    end generate gen_conv_i;
end behaviour;


