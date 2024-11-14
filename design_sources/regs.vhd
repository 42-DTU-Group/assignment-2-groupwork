library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.array_types.all;

entity regs is
    generic (
        width    : natural;                                       -- width of register array.
        height   : natural                                        -- height of register array.
    );
    port (
        clk      : in  std_logic;                                 -- clock signal.
        reset    : in  std_logic;                                 -- reset signal.
        en       : in  t_en_array(1 to width, 1 to height);       -- enable signal.
        data_in  : in  t_2d_data_array(1 to width, 1 to height);  -- input data.
        data_out : out t_2d_data_array(1 to width, 1 to height)   -- output data.
    );
end regs;

architecture behaviour of regs is
    component reg is
        generic (
            n              : natural
        );
        port (
            clk, reset, en : in std_logic;
            data_in        : in unsigned(n downto 1);
            data_out       : out unsigned(n downto 1)
        );
    end component;
begin
    gen_reg_x:
    for x in 1 to width generate
        gen_reg_y:
        for y in 1 to height generate
            gen_reg: reg
            generic map (
                n        => 8
            )
            port map (
                clk      => clk,
                reset    => reset,
                en       => en(x, y),
                data_in  => data_in(x, y),
                data_out => data_out(x, y)
            );
        end generate gen_reg_y;
    end generate gen_reg_x;
end behaviour;

