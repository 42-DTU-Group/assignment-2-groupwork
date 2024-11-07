library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.types.all;
-- use work.regs_types.all;

entity acc_datapath is
    generic (
        width   : natural := 352;      -- width of image.
        height  : natural := 288       -- height of image.
    );
    port (
        clk     : in  bit_t;           -- The clock.
        reset   : in  bit_t;           -- The reset signal. Active high.
        dataR   : in  word_t;          -- The data bus.
        dataW   : out word_t;          -- The data bus.
        reading : in  std_logic        -- Whether to save dataR or not
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
            en         : in  t_reg_en_array(1 to 4, 1 to 1);
            data_in    : in  t_reg_data_array(1 to 4, 1 to 1);
            data_out   : out t_reg_data_array(1 to 4, 1 to 1)
        );
    end component;

    signal regs_en           : t_reg_en_array(1 to 4, 1 to 1);
    signal regs_in, regs_out : t_reg_data_array(1 to 4, 1 to 1);
begin
    buf: regs
        generic map (
            width    => 4,
            height   => 1
        )
        port map (
            clk      => clk,
            reset    => reset,
            en       => regs_en,
            data_in  => regs_in,
            data_out => regs_out
        );

    -- NOTE: Since we have reintroduced the registers as sample code (which we skipped in task 0),
    --       we are currently one clock cycle late, so the data that we put in dataW is wrong - but
    --       this should be fixed by not having some specific registers in the final buffer, and
    --       instead using the data directly as we read it from dataR.
    regs_en(1,1) <= reading;
    regs_en(2,1) <= reading;
    regs_en(3,1) <= reading;
    regs_en(4,1) <= reading;
    regs_in(1,1) <= unsigned(dataR(7 downto 0));
    regs_in(2,1) <= unsigned(dataR(15 downto 8));
    regs_in(3,1) <= unsigned(dataR(23 downto 16));
    regs_in(4,1) <= unsigned(dataR(31 downto 24));
    dataW(7  downto  0) <= std_logic_vector(to_unsigned(255, 8) - regs_out(1,1));
    dataW(15 downto  8) <= std_logic_vector(to_unsigned(255, 8) - regs_out(2,1));
    dataW(23 downto 16) <= std_logic_vector(to_unsigned(255, 8) - regs_out(3,1));
    dataW(31 downto 24) <= std_logic_vector(to_unsigned(255, 8) - regs_out(4,1));
end rtl;
