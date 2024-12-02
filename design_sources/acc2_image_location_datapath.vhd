library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.types.all;

entity acc_image_location_datapath is
    generic (
        width        : natural;      -- width of image.
        height       : natural       -- height of image.
    );
    port (
        clk          : in  bit_t;           -- The clock.
        reset        : in  bit_t;           -- The reset signal. Active high.
        is_moving    : in  std_logic;       -- Flag defining whether we move the sliding window this frame
        manual_reset : in  std_logic;
        f_top        : out std_logic;       -- Flag is 1 if we are calculating the top edge
        f_left       : out std_logic;       -- Flag is 1 if we are calculating the left edge
        f_right      : out std_logic;       -- Flag is 1 if we are calculating the right edge
        f_bottom     : out std_logic        -- Flag is 1 if we are calculating the bottom edge
    );
end acc_image_location_datapath;

--------------------------------------------------------------------------------
-- The description of the accelerator.
--------------------------------------------------------------------------------

architecture rtl of acc_image_location_datapath is
    component reg
        generic (
            n              : natural;
            reset_value    : natural
        );
        port (
            clk, reset, en : in std_logic;
            data_in : in unsigned(n downto 1);
            data_out       : out unsigned(n downto 1)
        );
    end component;

    signal x_coord_en, y_coord_en, reset_wire : std_logic;
    signal x_coord_in, y_coord_in, x_coord_out, y_coord_out : unsigned(8 downto 0);
begin
    x_coord: reg  -- Register row 1
        generic map (
            n           => 9,
            reset_value => 0
        )
        port map (
            clk         => clk,
            reset       => reset_wire,
            en          => x_coord_en,
            data_in     => x_coord_in,
            data_out    => x_coord_out
        );
    y_coord: reg  -- Register row 1
        generic map (
            n           => 9,
            reset_value => 0
        )
        port map (
            clk         => clk,
            reset       => reset_wire,
            en          => y_coord_en,
            data_in     => y_coord_in,
            data_out    => y_coord_out
        );

    reset_wire <= reset or manual_reset;

    x_coord_en <= is_moving;
    y_coord_en <= '1' when (is_moving = '1') and (x_coord_in = to_unsigned(0, 9)) else '0';

    x_coord_in <= x_coord_out + 1 when (x_coord_out < width/4-1) else to_unsigned(0, 9);
    y_coord_in <= y_coord_out + 1;

    f_top    <= '1' when (y_coord_out = to_unsigned(0, 9)) else '0';
    f_left   <= '1' when (x_coord_out = to_unsigned(0, 9)) else '0';
    f_right  <= '1' when (x_coord_out = to_unsigned(width/4-1, 9)) else '0';
    f_bottom <= '1' when (y_coord_out = to_unsigned(height-1, 9)) else '0';
end rtl;
