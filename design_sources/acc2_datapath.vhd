library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.types.all;
use work.array_types.all;

entity acc_datapath is
    port (
        clk      : in  bit_t;           -- The clock.
        reset    : in  bit_t;           -- The reset signal. Active high.
        dataR    : in  word_t;          -- The data bus.
        dataW    : out word_t;          -- The data bus.
        read1_en : in std_logic;        -- Whether to save dataR to the top row
        read2_en : in std_logic;        -- Whether to save dataR to the middle row
        shift_en : in std_logic;        -- Whether to shift registers 4 pixels to the left
        f_top    : in std_logic;        -- Flag is 1 if we are calculating the top edge
        f_left   : in std_logic;        -- Flag is 1 if we are calculating the left edge
        f_right  : in std_logic;        -- Flag is 1 if we are calculating the right edge
        f_bottom : in std_logic         -- Flag is 1 if we are calculating the bottom edge
    );
end acc_datapath;

--------------------------------------------------------------------------------
-- The description of the accelerator.
--------------------------------------------------------------------------------

architecture rtl of acc_datapath is
    component regs
        generic (
            width      : natural;
            height     : natural
        );
        port (
            clk, reset : in  std_logic;
            en         : in  t_en_array(1 to 12, 1 to 3);
            data_in    : in  t_2d_data_array(1 to 12, 1 to 3);
            data_out   : out t_2d_data_array(1 to 12, 1 to 3)
        );
    end component;

    component convs
        generic (
            n        : natural
        );
        port (
            data_in  : in  t_2d_data_array(1 to 4, 1 to 8);
            data_out : out t_1d_data_array(1 to n)
        );
    end component;

    signal regs_en           : t_en_array(1 to 12, 1 to 3);
    signal regs_in, regs_out : t_2d_data_array(1 to 12, 1 to 3);

    signal convs_in          : t_2d_data_array(1 to 4, 1 to 8);
    signal convs_out         : t_1d_data_array(1 to 4);
    signal convs_input_regs  : t_2d_data_array(1 to 6, 1 to 3); -- signals replicating regs_out but after applying e.g. f_left
begin
    -- create registers
    buf: regs
        generic map (
            width    => 12,
            height   => 3
        )
        port map (
            clk      => clk,
            reset    => reset,
            en       => regs_en,
            data_in  => regs_in,
            data_out => regs_out
        );

    -- create convolutions
    convolutions: convs
        generic map (
            n        => 4
        )
        port map (
            data_in  => convs_in,
            data_out => convs_out
        );

    -- Enable flags for reading and shifting
    gen_regs_read1_en:
    for x in 9 to 12 generate
        regs_en(x, 1) <= read1_en;
    end generate gen_regs_read1_en;

    gen_regs_read2_en:
    for x in 9 to 12 generate
        regs_en(x, 2) <= read2_en;
    end generate gen_regs_read2_en;

    gen_regs_shift_en_x:
    for x in 1 to 8 generate
        gen_regs_shift_en_y:
        for y in 1 to 3 generate
            regs_en(x, y) <= shift_en;
        end generate gen_regs_shift_en_y;
    end generate gen_regs_shift_en_x;

    -- Pipe data from dataR to registers
    gen_dataR_to_regs:
    for y in 1 to 2 generate
        regs_in(9, y) <= unsigned(dataR(7 downto 0));
        regs_in(10, y) <= unsigned(dataR(15 downto 8));
        regs_in(11, y) <= unsigned(dataR(23 downto 16));
        regs_in(12, y) <= unsigned(dataR(31 downto 24));
    end generate gen_dataR_to_regs;

    -- Pipe data for shifting
    gen_regs_shift_data_x:
    for x in 1 to 2 generate
        gen_regs_shift_data_y:
        for y in 1 to 3 generate
            gen_regs_shift_not_bottom_right_corner:
            if not ((x = 2) and (y = 3)) generate
                regs_in(1+4*(x-1), y) <= regs_out(1+4*x, y);
                regs_in(2+4*(x-1), y) <= regs_out(2+4*x, y);
                regs_in(3+4*(x-1), y) <= regs_out(3+4*x, y);
                regs_in(4+4*(x-1), y) <= regs_out(4+4*x, y);
            end generate gen_regs_shift_not_bottom_right_corner;

            gen_regs_shift_bottom_right_corner:
            if ((x = 2) and (y = 3)) generate
                regs_in(1+4*(x-1), y) <= unsigned(dataR(7 downto 0));
                regs_in(2+4*(x-1), y) <= unsigned(dataR(15 downto 8));
                regs_in(3+4*(x-1), y) <= unsigned(dataR(23 downto 16));
                regs_in(4+4*(x-1), y) <= unsigned(dataR(31 downto 24));
            end generate gen_regs_shift_bottom_right_corner;
        end generate gen_regs_shift_data_y;
    end generate gen_regs_shift_data_x;

    -- Piping registers to convolution input
    muxed_signals_for_conv_input: process (regs_out, dataR, f_top, f_left, f_right, f_bottom) is
    begin
        -- defaults
        convs_input_regs(1, 1) <= regs_out(4, 1);
        convs_input_regs(2, 1) <= regs_out(5, 1);
        convs_input_regs(3, 1) <= regs_out(6, 1);
        convs_input_regs(4, 1) <= regs_out(7, 1);
        convs_input_regs(5, 1) <= regs_out(8, 1);
        convs_input_regs(6, 1) <= regs_out(9, 1);
        convs_input_regs(1, 2) <= regs_out(4, 2);
        convs_input_regs(2, 2) <= regs_out(5, 2);
        convs_input_regs(3, 2) <= regs_out(6, 2);
        convs_input_regs(4, 2) <= regs_out(7, 2);
        convs_input_regs(5, 2) <= regs_out(8, 2);
        convs_input_regs(6, 2) <= regs_out(9, 2);
        convs_input_regs(1, 3) <= regs_out(4, 3);
        convs_input_regs(2, 3) <= regs_out(5, 3);
        convs_input_regs(3, 3) <= regs_out(6, 3);
        convs_input_regs(4, 3) <= regs_out(7, 3);
        convs_input_regs(5, 3) <= regs_out(8, 3);
        convs_input_regs(6, 3) <= unsigned(dataR(7 downto 0));

        -- edge cases (badum tsh)
        if f_top = '1' then
            convs_input_regs(1, 1) <= regs_out(4, 2);
            convs_input_regs(2, 1) <= regs_out(5, 2);
            convs_input_regs(3, 1) <= regs_out(6, 2);
            convs_input_regs(4, 1) <= regs_out(7, 2);
            convs_input_regs(5, 1) <= regs_out(8, 2);
            convs_input_regs(6, 1) <= regs_out(9, 2);
        end if;
        if f_bottom = '1' then
            convs_input_regs(1, 3) <= regs_out(4, 2);
            convs_input_regs(2, 3) <= regs_out(5, 2);
            convs_input_regs(3, 3) <= regs_out(6, 2);
            convs_input_regs(4, 3) <= regs_out(7, 2);
            convs_input_regs(5, 3) <= regs_out(8, 2);
            convs_input_regs(6, 3) <= regs_out(9, 2);
        end if;
        if f_left = '1' then
            convs_input_regs(1, 1) <= regs_out(5, 1);
            convs_input_regs(1, 2) <= regs_out(5, 2);
            convs_input_regs(1, 3) <= regs_out(5, 3);
        end if;
        if f_right = '1' then
            convs_input_regs(6, 1) <= regs_out(8, 1);
            convs_input_regs(6, 2) <= regs_out(8, 2);
            convs_input_regs(6, 3) <= regs_out(8, 3);
        end if;
        if (f_top = '1') and (f_left = '1') then
            convs_input_regs(1, 1) <= regs_out(5, 2);
        end if;
        if (f_top = '1') and (f_right = '1') then
            convs_input_regs(6, 1) <= regs_out(8, 2);
        end if;
        if (f_bottom = '1') and (f_left = '1') then
            convs_input_regs(1, 3) <= regs_out(5, 2);
        end if;
        if (f_bottom = '1') and (f_right = '1') then
            convs_input_regs(6, 3) <= regs_out(8, 2);
        end if;
    end process;

    -- The input data surrounding the convolution pixel 'c' uses the indices
    -- 1 2 3
    -- 4 c 5
    -- 6 7 8
    gen_pipe_data_to_convs:
    for n in 1 to 4 generate
        convs_in(n, 1) <= convs_input_regs(1+(n-1), 1);
        convs_in(n, 2) <= convs_input_regs(2+(n-1), 1);
        convs_in(n, 3) <= convs_input_regs(3+(n-1), 1);
        convs_in(n, 4) <= convs_input_regs(1+(n-1), 2);
        convs_in(n, 5) <= convs_input_regs(3+(n-1), 2);
        convs_in(n, 6) <= convs_input_regs(1+(n-1), 3);
        convs_in(n, 7) <= convs_input_regs(2+(n-1), 3);
        convs_in(n, 8) <= convs_input_regs(3+(n-1), 3);
    end generate gen_pipe_data_to_convs;

    -- Piping convolution output to dataW
    dataW(7  downto  0) <= std_logic_vector(convs_out(1));
    dataW(15 downto  8) <= std_logic_vector(convs_out(2));
    dataW(23 downto 16) <= std_logic_vector(convs_out(3));
    dataW(31 downto 24) <= std_logic_vector(convs_out(4));
end rtl;
