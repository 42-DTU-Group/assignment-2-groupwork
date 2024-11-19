library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.types.all;

entity acc_fsm is
    generic (
        width    : natural := 352;      -- width of image.
        height   : natural := 288       -- height of image.
    );
    port (
        clk      : in  bit_t;             -- The clock.
        reset    : in  bit_t;             -- The reset signal. Active high.
        addr     : out halfword_t;        -- Address bus for data.
        en       : out bit_t;             -- Request signal for data.
        we       : out bit_t;             -- Read/Write signal for data.
        start    : in  bit_t;
        finish   : out bit_t;
        read1_en : out std_logic;
        read2_en : out std_logic;
        shift_en : out std_logic;
        f_top    : out std_logic;
        f_left   : out std_logic;
        f_right  : out std_logic;
        f_bottom : out std_logic;
        reading  : out std_logic   -- I will have to ask about this one - Christine
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
            data_in_buffer_1 : in unsigned(n downto 1);
            data_in_buffer_2 : in unsigned(n downto 1);
            data_in_buffer_3 : in unsigned(n downto 1);
            data_out       : out unsigned(n downto 1)
        );
    end component;

    signal read_addr_en, write_addr_en : std_logic;
    signal read_addr_in_1, read_addr_in_2, read_addr_in_3, read_addr_out, write_addr_in, write_addr_out : unsigned(16 downto 1);

    -- Made additional state types - Christine
    type statetype is ( idle_state, read_and_shift_state, read_state_1, read_state_2, read_state_3, write_state, finish_state );
    signal state, next_state : statetype;
begin
    read_addr: reg -- TODO: Move to datapath... right?
        generic map (
            n        => 16
        )
        port map (
            clk      => clk,
            reset    => reset,
            en       => read_addr_en,
            data_in_buffer_1 => read_addr_in_1,
            data_in_buffer_2 => read_addr_in_2,
            data_in_buffer_3 => read_addr_in_3,
            data_out => read_addr_out
        );

    write_addr: reg -- TODO: Move to datapath... right?
        generic map (
            n        => 16
        )
        port map (
            clk      => clk,
            reset    => reset,
            en       => write_addr_en,
            data_in_buffer_1 => read_addr_in_1,
            data_in_buffer_2 => read_addr_in_2,
            data_in_buffer_3 => read_addr_in_3,
            data_out => write_addr_out
        );

    -- Next state logic
    state_logic: process (state, start, read_addr_in_1, read_addr_in_2, read_addr_in_3 read_addr_out, write_addr_out) is
    begin
        next_state <= state;
        finish <= '0';

        -- Following the schema - Christine
        read_addr_in_1 <= to_unsigned(0, 16);
        read_addr_in_2 <= to_unsigned(0, 16);
        read_addr_in_3 <= to_unsigned(0, 16);

        read_addr_en <= '0';
        write_addr_in <= to_unsigned(0, 16);
        write_addr_en <= '0';
        en <= '0';
        we <= '0';
        addr <= halfword_zero;
        reading <= '0';

        case state is
            when idle_state =>
                -- the first read address, which is 88th address
                read_addr_in_1 <= to_unsigned(88, 16);
                -- the second read address, which is 176th address
                read_addr_in_2 <= to_unsigned(176, 16);
                -- the third read address, which is 264th address
                read_addr_in_3 <= to_unsigned(264, 16);

                read_addr_en <= '1';
                write_addr_in <= to_unsigned(25344, 16); -- = 352*288/4 which is the first write address
                write_addr_en <= '1';
                if start = '1' then
                    next_state <= read_state_1;
                end if;

    -- Ok hear me, Christine, out; we must construct additional ~~pylons~~ states lest we do expensive operation of division checking if divisible by 4
            when read_state_1 =>
                addr <= std_logic_vector(read_addr_out);
                read_addr_in_1 <= read_addr_out + 1;
                read_addr_en <= '1';
                next_state <= read_state_2;
                en <= '1';
            when read_state_2 =>
                addr <= std_logic_vector(read_addr_out);
                read_addr_in_2 <= read_addr_out + 1;
                read_addr_en <= '1';
                next_state <= read_state_3;
                en <= '1';
                -- Todo - Add the register[3,1] <- dataR
            when read_state_3 =>
                addr <= std_logic_vector(read_addr_out);
                read_addr_in_3 <= read_addr_out + 1;
                read_addr_en <= '1';
                en <= '1';
                -- If we are just starting, we should go to the special pre-read number 4 state with shifting
                if read_addr_in_1 = 89 then
                    next_state <= read_and_shift_state;
                    shift_en <= '1';
                else
                    next_state <= write_state;
                end if;
                -- Todo - Add the register[3,2] <- dataR
            when read_and_shift_state =>
                addr <= std_logic_vector(read_addr_out);
                read_addr_in_1 <= read_addr_out + 1;
                read_addr_en <= '1';
                en <= '1';
                -- Todo: Add the shifting logic onto the registers
                --   reg[1, 1..3] <- reg[2, 1..3]
                --   reg[2, 1..2] <- reg[3, 1..2]
                --   reg[2, 3] <- dataR

                -- Go back to the read_state_2
                next_state <= read_state_2;

            when write_state =>
                shift_en <= '0';
                if read_addr_out = 25344 then
                    next_state <= finish_state;
                else
                    next_state <= read_state_1;
                end if;
                reading <= '1'; -- The memory returns the data one clock cycle after we request it - which is every time we are in the write_state
                addr <= std_logic_vector(write_addr_out);
                write_addr_in <= write_addr_out + 1;
                write_addr_en <= '1';
                en <= '1';
                we <= '1';

                -- Todo: Add the shifting logic onto the registers
                --   reg[1, 1..3] <- reg[2, 1..3]
                --   reg[2, 1..2] <- reg[3, 1..2]
                --   reg[2, 3] <- dataR


                -- Todo: Add convolution flag/call to to convolute from the convs.vhd & conv.vhd


            -- Robust patch, as per lecture's suggestion if a bit flip happens or a hardware crash, so it could recover!
            when finish_state =>
                finish <= '1';
                next_state <= idle_state;
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
