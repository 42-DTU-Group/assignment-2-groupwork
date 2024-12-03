library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.types.all;

entity acc_fsm is
    port (
        clk          : in  bit_t;             -- The clock.
        reset        : in  bit_t;             -- The reset signal. Active high.
        addr         : out halfword_t;        -- Address bus for data.
        en           : out bit_t;             -- Request signal for data.
        we           : out bit_t;             -- Read/Write signal for data.
        start        : in  bit_t;
        finish       : out bit_t;
        read1_en     : out std_logic;
        read2_en     : out std_logic;
        shift_en     : out std_logic;
        is_moving    : out std_logic;
        manual_reset : out std_logic
    );
end acc_fsm;

--------------------------------------------------------------------------------
-- The description of the accelerator.
--------------------------------------------------------------------------------

architecture rtl of acc_fsm is
    component reg
        generic (
            n              : natural
        );
        port (
            clk, reset, en : in std_logic;
            data_in : in unsigned(n downto 1);
            data_out       : out unsigned(n downto 1)
        );
    end component;

    signal write_addr_en : std_logic;
    signal read_addr_in_1, read_addr_in_2, read_addr_in_3, write_addr_in, write_addr_out : unsigned(16 downto 1);
    signal read_addr_en_1, read_addr_en_2, read_addr_en_3 : std_logic;
    signal read_addr_out_1, read_addr_out_2, read_addr_out_3 : unsigned(16 downto 1);
    -- Made additional state types - Christine
    type statetype is ( idle_state, read_state_1, read_state_2, read_state_3, write_state, finish_state,
    pre_read_state_1, pre_read_state_2, pre_read_state_3, pre_read_state_4, pre_read_state_5, pre_read_state_6, read_2_top_row_state, write_bottom_row_state, final_write_word_state);
    signal state, next_state : statetype;
begin
    read_addr_1: reg  -- Register row 1
        generic map (
            n        => 16
        )
        port map (
            clk      => clk,
            reset    => reset,
            en       => read_addr_en_1,
            data_in  => read_addr_in_1,
            data_out => read_addr_out_1
        );
    read_addr_2: reg -- Register row 2
        generic map (
            n        => 16
        )
        port map (
            clk      => clk,
            reset    => reset,
            en       => read_addr_en_2,
            data_in  => read_addr_in_2,
            data_out => read_addr_out_2
        );
    read_addr_3: reg -- Register row 3
        generic map (
            n        => 16
        )
        port map (
            clk      => clk,
            reset    => reset,
            en       => read_addr_en_3,
            data_in  => read_addr_in_3,
            data_out => read_addr_out_3
        );
    write_addr: reg
        generic map (
            n        => 16
        )
        port map (
            clk      => clk,
            reset    => reset,
            en       => write_addr_en,
            data_in  => write_addr_in,
            data_out => write_addr_out
        );

    -- Next state logic
    state_logic: process (state, start, read_addr_in_1, read_addr_in_2, read_addr_in_3, read_addr_out_1, read_addr_out_2, read_addr_out_3, write_addr_out) is
    begin
        next_state <= state;
        finish <= '0';

        -- Following the schema - Christine
        read_addr_in_1 <= to_unsigned(0, 16);
        read_addr_in_2 <= to_unsigned(0, 16);
        read_addr_in_3 <= to_unsigned(0, 16);

        read_addr_en_1 <= '0';
        read_addr_en_2 <= '0';
        read_addr_en_3 <= '0';

        write_addr_in <= to_unsigned(0, 16);
        write_addr_en <= '0';
        en <= '0';
        we <= '0';
        addr <= halfword_zero;

        read1_en <= '0';
        read2_en <= '0';
        shift_en <= '0';

        is_moving <= '0';
        manual_reset <= '0';

        case state is
            when idle_state =>
                manual_reset <= '1';

                -- the first read address, which is 0th address
                read_addr_in_1 <= to_unsigned(0, 16);
                -- the second read address, which is 88th address
                read_addr_in_2 <= to_unsigned(0, 16);
                -- the third read address, which is 176th address
                read_addr_in_3 <= to_unsigned(88, 16);

                read_addr_en_1 <= '1';
                read_addr_en_2 <= '1';
                read_addr_en_3 <= '1';

                write_addr_in <= to_unsigned(25344, 16);
                write_addr_en <= '1';
                if start = '1' then
                    next_state <= pre_read_state_1;
                end if;

    -- Ok hear me, Christine, out; we must construct additional ~~pylons~~ states lest we do expensive operation of division checking if divisible by 4
            -- PRE-READ BLOCK
            when pre_read_state_1 =>
                addr <= std_logic_vector(read_addr_out_2);
                read_addr_in_2 <= read_addr_out_2 + 1;
                read_addr_en_2 <= '1';

                read1_en <= '1';

                en <= '1';

                next_state <= pre_read_state_2;

            when pre_read_state_2 =>
                addr <= std_logic_vector(read_addr_out_3);
                read_addr_in_3 <= read_addr_out_3 + 1;
                read_addr_en_3 <= '1';

                read2_en <= '1';
                en <= '1';

                next_state <= pre_read_state_3;

            when pre_read_state_3 =>
                addr <= std_logic_vector(read_addr_out_2);
                read_addr_in_2 <= read_addr_out_2 + 1;
                read_addr_en_2 <= '1';

                en <= '1';

                read1_en <= '1';

                shift_en <= '1'; -- Note - Register shift

                next_state <= pre_read_state_4;

            when pre_read_state_4 =>
                addr <= std_logic_vector(read_addr_out_3);
                read_addr_in_3 <= read_addr_out_3 + 1;
                read_addr_en_3 <= '1';

                en <= '1';
                read2_en <= '1';

                next_state <= write_state;

            when read_state_1 =>
                addr <= std_logic_vector(read_addr_out_1);
                read_addr_in_1 <= read_addr_out_1 + 1;
                read_addr_en_1 <= '1';
                shift_en <= '0';

                we <= '0';
                en <= '1';

                next_state <= read_state_2;

            when read_state_2 =>
                addr <= std_logic_vector(read_addr_out_2);
                read_addr_in_2 <= read_addr_out_2 + 1;
                read_addr_en_2 <= '1';

                read1_en <= '1';
                en <= '1';

                if read_addr_out_3 < 25344 then
                    next_state <= read_state_3;
                else
                    next_state <= write_bottom_row_state;
                end if;

            when write_bottom_row_state =>
                addr <= std_logic_vector(write_addr_out);
                write_addr_in <= write_addr_out + 1;
                write_addr_en <= '1';

                is_moving <= '1';
                shift_en <= '1'; -- Note: Register shift
                en <= '1';
                we <= '1';

                if read_addr_out_2 >= 25344 then
                    next_state <= final_write_word_state;
                else
                    next_state <= read_state_1;
                end if;

            when read_state_3 =>
                addr <= std_logic_vector(read_addr_out_3);
                read_addr_in_3 <= read_addr_out_3 + 1;
                read_addr_en_3 <= '1';
                shift_en <= '0';


                read2_en <= '1';
                en <= '1';
                we <= '0';

                next_state <= write_state;

            when read_2_top_row_state =>
                addr <= std_logic_vector(read_addr_out_2);
                read_addr_in_2 <= read_addr_out_2 + 1;
                read_addr_en_2 <= '1';
                shift_en <= '0';
                en <= '1';

                next_state <= read_state_3;

            when write_state =>
                addr <= std_logic_vector(write_addr_out);
                write_addr_in <= write_addr_out + 1;
                write_addr_en <= '1';

                is_moving <= '1';
                shift_en <= '1'; -- Note: Register shift
                en <= '1';
                we <= '1';

                -- Note: We are constantly convoluting thus we don't need to enable separate flag

                if read_addr_out_2 < 88 then --
                    next_state <= read_2_top_row_state;
                else
                    if read_addr_out_2 >= 25344 then
                        next_state <= final_write_word_state;
                    else
                        next_state <= read_state_1;
                    end if;
                end if;



            when final_write_word_state =>
                addr <= std_logic_vector(write_addr_out);
                en <= '1';
                we <= '1';

                next_state <= finish_state;

            when finish_state =>
                finish <= '1';
                -- Only reset to idle_state when `start` is low, to prevent starting the same calculation again, and to keep the LED lit
                if start = '0' then
                    next_state <= idle_state;
                end if;
            -- Robust patch, as per lecture's suggestion if a bit flip happens or a hardware crash, so it could recover!
            when others =>
                next_state <= idle_state;

        end case;
    end process;

    -- Clock and reset logic
    rst_clk: process (clk,reset) is
    begin
        if (reset='1') then
            state <= idle_state;
        elsif rising_edge (clk) then
            state <= next_state;
        end if;
    end process;
end rtl;
