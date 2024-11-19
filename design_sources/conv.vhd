library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.array_types.all;

entity conv is
    port (
        clk      : in  std_logic;
        data_in  : in  t_1d_data_array(1 to 8);
        data_out : out signed(7 downto 0)
    );
end conv;

architecture pipelined of conv is
    -- Sobel matrix Gx ((-1, 0, 1),(-2,0,2),(-1,0,1))
    -- Sobel matrix Gy ((1,2,1),(0,0,0),(-1,-2,-1))
    constant Gx : t_1d_data_array(1 to 8) := (to_signed(1, 8), to_signed(0, 8), to_signed(-1, 8), to_signed(2, 8), to_signed(-2, 8), to_signed(1, 8), to_signed(0, 8), to_signed(-1, 8));
    constant Gy : t_1d_data_array(1 to 8) := (to_signed(1, 8), to_signed(2, 8), to_signed(1, 8), to_signed(0, 8), to_signed(0, 8), to_signed(-1, 8), to_signed(-2, 8), to_signed(-1, 8));

    -- Stage 1: Multiply input data with Sobel matrices
    signal G_x_stage1 : t_1d_data_array(1 to 8);
    signal G_y_stage1 : t_1d_data_array(1 to 8);

    -- Buffer registers for Stage 1
    signal G_x_stage1_buf : t_1d_data_array(1 to 8);
    signal G_y_stage1_buf : t_1d_data_array(1 to 8);

    -- Stage 2: Sum the results to compute the derivatives
    signal D_x_stage2 : signed(7 downto 0);
    signal D_y_stage2 : signed(7 downto 0);

    -- Buffer registers for Stage 2
    signal D_x_stage2_buf : signed(7 downto 0);
    signal D_y_stage2_buf : signed(7 downto 0);

    -- Stage 3: Calculate the final result
    signal result_stage3 : signed(7 downto 0);
begin
    -- Stage 1: Multiply input data with Sobel matrices
    process(clk)
    begin
        if rising_edge(clk) then
            for i in 1 to 8 loop
                G_x_stage1(i) <= data_in(i) * Gx(i);
                G_y_stage1(i) <= data_in(i) * Gy(i);
            end loop;
            -- Buffer registers for Stage 1
            G_x_stage1_buf <= G_x_stage1;
            G_y_stage1_buf <= G_y_stage1;
        end if;
    end process;

    -- Stage 2: Sum the results to compute the derivatives
    process(clk)
    begin
        if rising_edge(clk) then
            D_x_stage2 <= G_x_stage1_buf(3) - G_x_stage1_buf(1) + 2 * (G_x_stage1_buf(5) - G_x_stage1_buf(4)) + G_x_stage1_buf(8) - G_x_stage1_buf(6);
            D_y_stage2 <= G_y_stage1_buf(1) - G_y_stage1_buf(6) + 2 * (G_y_stage1_buf(2) - G_y_stage1_buf(7)) + G_y_stage1_buf(3) - G_y_stage1_buf(8);
            -- Buffer registers for Stage 2
            D_x_stage2_buf <= D_x_stage2;
            D_y_stage2_buf <= D_y_stage2;
        end if;
    end process;

    -- Stage 3: Calculate the final result
    process(clk)
    begin
        if rising_edge(clk) then
            result_stage3 <= abs(D_x_stage2_buf) + abs(D_y_stage2_buf);
            data_out <= result_stage3;
        end if;
    end process;
end pipelined;