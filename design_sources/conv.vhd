library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.array_types.all;

entity conv is
    generic (
        n        : natural := 11                -- number of bits in signed integers
    );
    port (
        data_in  : in  t_1d_data_array(1 to 8);
        data_out : out unsigned(7 downto 0)
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

    -- Derivative in x and y
    signal D_x, D_y,
        sub_result_1, sub_result_2, sub_result_3, sub_result_4, sub_result_5, sub_result_6,
        sub_result_2_x2, sub_result_5_x2 : signed(10 downto 0);
    signal result : unsigned(10 downto 0);
    signal eleven_bit_signed_1, eleven_bit_signed_2, eleven_bit_signed_3, eleven_bit_signed_4,
      eleven_bit_signed_5, eleven_bit_signed_6, eleven_bit_signed_7, eleven_bit_signed_8 : signed(10 downto 0);

begin

    -- Calculate the convolution
    -- D_x(n) = index(1,3)-index_(1,1)+2(index_(2,3)-index_(2,1))+index_(3,3)-index_(3,1)
    -- D_y(n) = index(1,1)-index_(3,1)+2(index_(1,2)-index_(3,2))+index_(1,3)-index_(3,3)

    -- Convert 8-bit unsinged into 11-bit signed by adding MSB as 0 to indicate that it is a positive number
    eleven_bit_signed_1(10 downto 8) <= "000";
    eleven_bit_signed_2(10 downto 8) <= "000";
    eleven_bit_signed_3(10 downto 8) <= "000";
    eleven_bit_signed_4(10 downto 8) <= "000";
    eleven_bit_signed_5(10 downto 8) <= "000";
    eleven_bit_signed_6(10 downto 8) <= "000";
    eleven_bit_signed_7(10 downto 8) <= "000";
    eleven_bit_signed_8(10 downto 8) <= "000";

    eleven_bit_signed_1(7 downto 0) <= signed(data_in(1));
    eleven_bit_signed_2(7 downto 0) <= signed(data_in(2));
    eleven_bit_signed_3(7 downto 0) <= signed(data_in(3));
    eleven_bit_signed_4(7 downto 0) <= signed(data_in(4));
    eleven_bit_signed_5(7 downto 0) <= signed(data_in(5));
    eleven_bit_signed_6(7 downto 0) <= signed(data_in(6));
    eleven_bit_signed_7(7 downto 0) <= signed(data_in(7));
    eleven_bit_signed_8(7 downto 0) <= signed(data_in(8));

    -- TODO: Verify that 11 bits (signed) is enough to store the theoretical max value of the calculation
    -- TODO: Optimization: Do bit manipulations instead of 2* (unless vivado already does it)
    sub_result_1 <= eleven_bit_signed_3 - eleven_bit_signed_1;
    sub_result_2 <= eleven_bit_signed_5 - eleven_bit_signed_4;
    sub_result_2_x2 <= eleven_bit_signed_2(n) & sub_result_2(n-2 downto 1) & '0';
    --sub_result_2_x2 <= 2*sub_result_2;

    sub_result_3 <= eleven_bit_signed_8 - eleven_bit_signed_6;

    sub_result_4 <= eleven_bit_signed_1 - eleven_bit_signed_6;
    sub_result_5 <= eleven_bit_signed_2 - eleven_bit_signed_7;
    sub_result_5_x2 <= sub_result_5(n) & sub_result_5(n-2 downto 1) & '0';
    -- sub_result_5_x2 <= 2*sub_result_5;
    sub_result_6 <= eleven_bit_signed_3 - eleven_bit_signed_8;

    -- D_x <=  sub_result_1 + 2*sub_result_2 + sub_result_3;
    D_x <=  sub_result_1 + sub_result_2_x2 + sub_result_3;
    D_y <=  sub_result_4 + sub_result_5_x2 + sub_result_6;

    -- Calculate the final result
    result <= unsigned(abs(D_x) + abs(D_y));
    data_out <= result(7 downto 0) when (result <= 255) else to_unsigned(255, 8);

    -- TODO: Make sure the output is cut off at the correct number of bits
    -- TODO: Verify that we are supposed to crop the result at 255 and not... idk. divide it to make 255 equal the max theoretical value of the calculation?

end behaviour;

-- library ieee;
-- use ieee.std_logic_1164.all;
-- use ieee.numeric_std.all;
-- use work.array_types.all;
-- 
-- entity conv is
--     port (
--         data_in  : in  t_1d_data_array(1 to 8);
--         data_out : out signed(7 downto 0)
--     );
-- end conv;
-- 
-- 
-- architecture behaviour of conv is
-- 
--     -- The input data surrounding the convolution pixel 'c' uses the indices
--     -- 1 2 3
--     -- 4 c 5
--     -- 6 7 8
-- 
-- 
--     -- Christine 19-11-2024
--     -- I assume it is like ((1, 2, 3), (4, c, 5), (6, 7, 8)) -> (1, 2, 3, 4, c, 5, 6, 7, 8)?
--     -- But we don't have the middle c index nor include it, right?
--     -- I will use the kernel matrix given by the documentation
-- 
--     -- Sobel matrix Gx ((-1, 0, 1),(-2,0,2),(-1,0,1))
--     -- Sobel matrix Gy ((1,2,1),(0,0,0),(-1,-2,-1))
-- 
--     constant Gx : t_1d_data_array(1 to 8) := (to_signed(1, 8), to_signed(0, 8), to_signed(-1, 8), to_signed(2, 8), to_signed(-2, 8), to_signed(1, 8), to_signed(0, 8), to_signed(-1, 8));
--     constant Gy : t_1d_data_array(1 to 8) := (to_signed(1, 8), to_signed(2, 8), to_signed(1, 8), to_signed(0, 8), to_signed(0, 8), to_signed(-1, 8), to_signed(-2, 8), to_signed(-1, 8));
-- 
--     -- The convolution result
--     signal G_x : t_1d_data_array(1 downto 8);
--     signal G_y : t_1d_data_array(1 downto 8);
-- 
--     -- Derivative in x and y
--     signal D_x : signed(7 downto 0);
--     signal D_y : signed(7 downto 0);
--     begin
--     process(data_in)
--     begin
--         -- Convolute with the data_in with each of the Sobel matrices with the result D_x and D_y
--         -- Make a loop
--         for i in 1 to 8 loop
--             G_x(i) <= to_integer(data_in(i)) * Gx(i);
--             G_y(i) <= to_integer(data_in(i)) * Gy(i);
--         end loop;
-- 
--         -- Calculate the convolution
--         -- D_x(n) = index(1,3)-index_(1,1)+2(index_(2,3)-index_(2,1))+index_(3,3)-index_(3,1)
--         -- D_y(n) = index(1,1)-index_(3,1)+2(index_(1,2)-index_(3,2))+index_(1,3)-index_(3,3)
-- 
--         -- TODO - NEED EXTRA PAIR OF EYES CHECKING IF THIS IS SAME AS THE COMMENT LOGIC UP HERE!
--         D_x <= G_x(3) - G_x(1) + 2 * (G_x(5) - G_x(4)) + G_x(8) - G_x(6);
--         D_y <= G_y(1) - G_y(6) + 2 * (G_y(2) - G_y(7)) + G_y(3) - G_y(8);
-- 
--         -- Calculate the final result
--         data_out <= abs(D_x) + abs(D_y);
--     end process;
-- 
-- end behaviour;
-- 
