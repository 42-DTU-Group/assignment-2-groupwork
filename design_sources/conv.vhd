library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.array_types.all;

entity conv is
    port (
        data_in  : in  t_1d_data_array(1 to 8);
        data_out : out signed(7 downto 0)
    );
end conv;


architecture behaviour of conv is

    -- The input data surrounding the convolution pixel 'c' uses the indices
    -- 1 2 3
    -- 4 c 5
    -- 6 7 8


    -- Christine 19-11-2024
    -- I assume it is like ((1, 2, 3), (4, c, 5), (6, 7, 8)) -> (1, 2, 3, 4, c, 5, 6, 7, 8)?
    -- But we don't have the middle c index nor include it, right?
    -- I will use the kernel matrix given by the documentation

    -- Sobel matrix Gx ((-1, 0, 1),(-2,0,2),(-1,0,1))
    -- Sobel matrix Gy ((1,2,1),(0,0,0),(-1,-2,-1))

    constant Gx : t_1d_data_array(1 to 8) := (to_signed(1, 8), to_signed(0, 8), to_signed(-1, 8), to_signed(2, 8), to_signed(-2, 8), to_signed(1, 8), to_signed(0, 8), to_signed(-1, 8));
    constant Gy : t_1d_data_array(1 to 8) := (to_signed(1, 8), to_signed(2, 8), to_signed(1, 8), to_signed(0, 8), to_signed(0, 8), to_signed(-1, 8), to_signed(-2, 8), to_signed(-1, 8));

    -- The convolution result
    signal G_x : t_1d_data_array(1 downto 8);
    signal G_y : t_1d_data_array(1 downto 8);

    -- Derivative in x and y
    signal D_x : signed(7 downto 0);
    signal D_y : signed(7 downto 0);
    begin
    process(data_in)
    begin
        -- Convolute with the data_in with each of the Sobel matrices with the result D_x and D_y
        -- Make a loop
        for i in 1 to 8 loop
            G_x(i) <= to_integer(data_in(i)) * Gx(i);
            G_y(i) <= to_integer(data_in(i)) * Gy(i);
        end loop;

        -- Calculate the convolution
        -- D_x(n) = index(1,3)-index_(1,1)+2(index_(2,3)-index_(2,1))+index_(3,3)-index_(3,1)
        -- D_y(n) = index(1,1)-index_(3,1)+2(index_(1,2)-index_(3,2))+index_(1,3)-index_(3,3)

        -- TODO - NEED EXTRA PAIR OF EYES CHECKING IF THIS IS SAME AS THE COMMENT LOGIC UP HERE!
        D_x <= G_x(3) - G_x(1) + 2 * (G_x(5) - G_x(4)) + G_x(8) - G_x(6);
        D_y <= G_y(1) - G_y(6) + 2 * (G_y(2) - G_y(7)) + G_y(3) - G_y(8);

        -- Calculate the final result
        data_out <= abs(D_x) + abs(D_y);
    end process;

end behaviour;

