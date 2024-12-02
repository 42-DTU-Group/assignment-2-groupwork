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
        read2_en : in std_logic;        -- Whether to read dataR to the middle row
        shift_en : in std_logic;        -- Whether to shift registers 4 pixels to the left
        fifo1_read_en  : in std_logic;  -- Whether to save data from fifo1 to the top row
        fifo2_read_en  : in std_logic;  -- Whether to save data from fifo2 to the middle row
        fifo1_write_en : in std_logic;  -- Whether to write to fifo1
        fifo2_write_en : in std_logic;  -- Whether to write to fifo2
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

    component bram_fifo is
        port (
            clk : in std_logic;
            srst : in std_logic;
            din : in std_logic_vector(31 downto 0);
            wr_en : in std_logic;
            rd_en : in std_logic;
            dout : out std_logic_vector(31 downto 0);
            full : out std_logic;
            empty : out std_logic
        );
    end component;

    signal regs_en           : t_en_array(1 to 12, 1 to 3);
    signal regs_in, regs_out : t_2d_data_array(1 to 12, 1 to 3);

    signal convs_in          : t_2d_data_array(1 to 4, 1 to 8);
    signal convs_out         : t_1d_data_array(1 to 4);
    signal convs_input_regs  : t_2d_data_array(1 to 6, 1 to 3); -- signals replicating regs_out but after applying e.g. f_left

    signal fifo1_data_in, fifo2_data_in, fifo1_data_out, fifo2_data_out : std_logic_vector(31 downto 0);
    signal fifo1_full, fifo2_full, fifo1_empty, fifo2_empty : std_logic;
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

    -- create FIFOs
    bram_fifo1: bram_fifo
        port map (
            clk   => clk,
            srst  => reset,
            din   => fifo1_data_in,
            wr_en => fifo1_write_en,
            rd_en => fifo1_read_en,
            dout  => fifo1_data_out,
            full  => fifo1_full,
            empty => fifo1_empty
        );

    bram_fifo2: bram_fifo
        port map (
            clk   => clk,
            srst  => reset,
            din   => fifo2_data_in,
            wr_en => fifo2_write_en,
            rd_en => fifo2_read_en,
            dout  => fifo2_data_out,
            full  => fifo2_full,
            empty => fifo2_empty
        );

    -- Enable flags for reading and shifting
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
    regs_in(9, 2) <= unsigned(dataR(7 downto 0));
    regs_in(10, 2) <= unsigned(dataR(15 downto 8));
    regs_in(11, 2) <= unsigned(dataR(23 downto 16));
    regs_in(12, 2) <= unsigned(dataR(31 downto 24));

    -- Pipe data to/from the FIFOs
    fifo1_data_in(7 downto 0) <= std_logic_vector(regs_out(1, 2));
    fifo1_data_in(15 downto 8) <= std_logic_vector(regs_out(2, 2));
    fifo1_data_in(23 downto 16) <= std_logic_vector(regs_out(3, 2));
    fifo1_data_in(31 downto 24) <= std_logic_vector(regs_out(4, 2));
    fifo2_data_in(7 downto 0) <= std_logic_vector(regs_out(1, 3));
    fifo2_data_in(15 downto 8) <= std_logic_vector(regs_out(2, 3));
    fifo2_data_in(23 downto 16) <= std_logic_vector(regs_out(3, 3));
    fifo2_data_in(31 downto 24) <= std_logic_vector(regs_out(4, 3));

    -- Pipe data for shifting
    gen_regs_shift_data_y:
    for y in 1 to 3 generate
        regs_in(1, y) <= regs_out(5, y);
        regs_in(2, y) <= regs_out(6, y);
        regs_in(3, y) <= regs_out(7, y);
        regs_in(4, y) <= regs_out(8, y);
    end generate gen_regs_shift_data_y;

    regs_in(5, 1) <= unsigned(fifo1_data_out(7 downto 0));
    regs_in(6, 1) <= unsigned(fifo1_data_out(15 downto 8));
    regs_in(7, 1) <= unsigned(fifo1_data_out(23 downto 16));
    regs_in(8, 1) <= unsigned(fifo1_data_out(31 downto 24));
    regs_in(5, 2) <= regs_out(9, 2) when (f_top = '1') else unsigned(fifo2_data_out(7 downto 0));
    regs_in(6, 2) <= regs_out(10, 2) when (f_top = '1') else unsigned(fifo2_data_out(15 downto 8));
    regs_in(7, 2) <= regs_out(11, 2) when (f_top = '1') else unsigned(fifo2_data_out(23 downto 16));
    regs_in(8, 2) <= regs_out(12, 2) when (f_top = '1') else unsigned(fifo2_data_out(31 downto 24));
    regs_in(5, 3) <= unsigned(dataR(7 downto 0));
    regs_in(6, 3) <= unsigned(dataR(15 downto 8));
    regs_in(7, 3) <= unsigned(dataR(23 downto 16));
    regs_in(8, 3) <= unsigned(dataR(31 downto 24));

    -- Drive the unused registers
    -- TODO: Consider not generating the registers... but then we need to regs arrays with different names, etc. etc.
    gen_regs_unused:
    for x in 9 to 12 generate
        regs_in(x, 1) <= to_unsigned(0, 8);
        regs_en(x, 1) <= '0';
        regs_in(x, 3) <= to_unsigned(0, 8);
        regs_en(x, 3) <= '0';
    end generate gen_regs_unused;

    -- Piping registers to convolution input
    muxed_signals_for_conv_input: process (regs_out, dataR, fifo1_data_out, fifo2_data_out, f_top, f_left, f_right, f_bottom) is
    begin
        -- defaults
        convs_input_regs(1, 1) <= regs_out(4, 1);
        convs_input_regs(2, 1) <= regs_out(5, 1);
        convs_input_regs(3, 1) <= regs_out(6, 1);
        convs_input_regs(4, 1) <= regs_out(7, 1);
        convs_input_regs(5, 1) <= regs_out(8, 1);
        convs_input_regs(6, 1) <= unsigned(fifo1_data_out(7 downto 0));
        convs_input_regs(1, 2) <= regs_out(4, 2);
        convs_input_regs(2, 2) <= regs_out(5, 2);
        convs_input_regs(3, 2) <= regs_out(6, 2);
        convs_input_regs(4, 2) <= regs_out(7, 2);
        convs_input_regs(5, 2) <= regs_out(8, 2);
        convs_input_regs(6, 2) <= unsigned(fifo2_data_out(7 downto 0));
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
            convs_input_regs(6, 2) <= regs_out(9, 2);
        end if;
        if f_bottom = '1' then
            convs_input_regs(1, 3) <= regs_out(4, 2);
            convs_input_regs(2, 3) <= regs_out(5, 2);
            convs_input_regs(3, 3) <= regs_out(6, 2);
            convs_input_regs(4, 3) <= regs_out(7, 2);
            convs_input_regs(5, 3) <= regs_out(8, 2);
            convs_input_regs(6, 3) <= unsigned(fifo2_data_out(7 downto 0));
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
