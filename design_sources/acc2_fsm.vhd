library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.types.all;
-- use work.regs_types.all;

entity acc_fsm is
    generic (
        width   : natural := 352;      -- width of image.
        height  : natural := 288       -- height of image.
    );
    port (
        clk     : in  bit_t;             -- The clock.
        reset   : in  bit_t;             -- The reset signal. Active high.
        addr    : out halfword_t;        -- Address bus for data.
        en      : out bit_t;             -- Request signal for data.
        we      : out bit_t;             -- Read/Write signal for data.
        start   : in  bit_t;
        finish  : out bit_t
        -- reading : out std_logic          -- Whether the datapath should save the incoming data
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
            data_in        : in unsigned(n downto 1);
            data_out       : out unsigned(n downto 1)
        );
    end component;

    signal read_addr_en, write_addr_en : std_logic;
    signal read_addr_in, read_addr_out, write_addr_in, write_addr_out : unsigned(16 downto 1);

    type statetype is ( idle_state, read_state, write_state, finish_state );
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
            data_in  => read_addr_in,
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
            data_in  => write_addr_in,
            data_out => write_addr_out
        );

    -- Next state logic
    state_logic: process (state, start, read_addr_in, read_addr_out, write_addr_out) is
    begin
        next_state <= state;
        finish <= '0';
        read_addr_in <= to_unsigned(0, 16);
        read_addr_en <= '0';
        write_addr_in <= to_unsigned(0, 16);
        write_addr_en <= '0';
        en <= '0';
        we <= '0';
        addr <= halfword_zero;
        -- reading <= '0';

        case state is
            when idle_state =>
                read_addr_in <= to_unsigned(0, 16); -- the first read address
                read_addr_en <= '1';
                write_addr_in <= to_unsigned(25344, 16); -- = 352*288/4 which is the first write address
                write_addr_en <= '1';
                if start = '1' then
                    next_state <= read_state;
                end if;
            when read_state =>
                addr <= std_logic_vector(read_addr_out);
                read_addr_in <= read_addr_out + 1;
                read_addr_en <= '1';
                next_state <= write_state;
                en <= '1';
            when write_state =>
                if read_addr_out = 25344 then
                    next_state <= finish_state;
                else
                    next_state <= read_state;
                end if;
                -- reading <= '1'; -- The memory returns the data one clock cycle after we request it - which is every time we are in the write_state
                addr <= std_logic_vector(write_addr_out);
                write_addr_in <= write_addr_out + 1;
                write_addr_en <= '1';
                en <= '1';
                we <= '1';
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
