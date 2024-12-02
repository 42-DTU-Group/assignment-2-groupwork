-- -----------------------------------------------------------------------------
--
--  Title      :  Edge-Detection design project - task 2.
--             :
--  Developers :  YOUR NAME HERE - s??????@student.dtu.dk
--             :  YOUR NAME HERE - s??????@student.dtu.dk
--             :
--  Purpose    :  This design contains an entity for the accelerator that must be build
--             :  in task two of the Edge Detection design project. It contains an
--             :  architecture skeleton for the entity as well.
--             :
--  Revision   :  1.0   ??-??-??     Final version
--             :
--
-- -----------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- The entity for task two. Notice the additional signals for the memory.
-- reset is active high.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.types.all;

entity acc is
    generic (
        width    : natural := 352;      -- width of image.
        height   : natural := 288       -- height of image.
    );
    port (
        clk    : in  bit_t;             -- The clock.
        reset  : in  bit_t;             -- The reset signal. Active high.
        addr   : out halfword_t;        -- Address bus for data.
        dataR  : in  word_t;            -- The data bus.
        dataW  : out word_t;            -- The data bus.
        en     : out bit_t;             -- Request signal for data.
        we     : out bit_t;             -- Read/Write signal for data.
        start  : in  bit_t;
        finish : out bit_t
    );
end acc;

--------------------------------------------------------------------------------
-- The description of the accelerator.
--------------------------------------------------------------------------------

architecture rtl of acc is
    component acc_fsm is
        port (
            clk          : in  bit_t;             -- The clock.
            reset        : in  bit_t;             -- The reset signal. Active high.
            addr         : out halfword_t;        -- Address bus for data.
            en           : out bit_t;             -- Request signal for data.
            we           : out bit_t;             -- Read/Write signal for data.
            start        : in  bit_t;
            finish       : out bit_t;
            read2_en     : out std_logic;
            shift_en     : out std_logic;
            fifo1_read_en  : out std_logic;
            fifo2_read_en  : out std_logic;
            fifo1_write_en : out std_logic;
            fifo2_write_en : out std_logic;
            is_moving    : out std_logic;
            manual_reset : out std_logic
        );
    end component;

    component acc_datapath is
        port (
            clk      : in  bit_t;           -- The clock.
            reset    : in  bit_t;           -- The reset signal. Active high.
            dataR    : in  word_t;          -- The data bus.
            dataW    : out word_t;          -- The data bus.
            read2_en : in  std_logic;
            shift_en : in  std_logic;
            fifo1_read_en  : in std_logic;
            fifo2_read_en  : in std_logic;
            fifo1_write_en : in std_logic;
            fifo2_write_en : in std_logic;
            f_top    : in  std_logic;
            f_left   : in  std_logic;
            f_right  : in  std_logic;
            f_bottom : in  std_logic
        );
    end component;

    component acc_image_location_datapath is
        generic (
            width        : natural;
            height       : natural
        );
        port (
            clk          : in  bit_t;
            reset        : in  bit_t;
            is_moving    : in  std_logic;
            manual_reset : in  std_logic;
            f_top        : out std_logic;
            f_left       : out std_logic;
            f_right      : out std_logic;
            f_bottom     : out std_logic
        );
    end component;

    signal read2_en_wire, shift_en_wire, is_moving_wire, manual_reset_wire, f_top_wire, f_left_wire, f_right_wire, f_bottom_wire, fifo1_read_en_wire, fifo2_read_en_wire, fifo1_write_en_wire, fifo2_write_en_wire : std_logic;
begin
    fsm: acc_fsm
        port map (
            clk          => clk,
            reset        => reset,
            addr         => addr,
            en           => en,
            we           => we,
            start        => start,
            finish       => finish,
            read2_en     => read2_en_wire,
            shift_en     => shift_en_wire,
            fifo1_read_en  => fifo1_read_en_wire,
            fifo2_read_en  => fifo2_read_en_wire,
            fifo1_write_en => fifo1_write_en_wire,
            fifo2_write_en => fifo2_write_en_wire,
            is_moving    => is_moving_wire,
            manual_reset => manual_reset_wire
        );

    datapath: acc_datapath
        port map (
            clk      => clk,
            reset    => reset,
            dataR    => dataR,
            dataW    => dataW,
            read2_en => read2_en_wire,
            shift_en => shift_en_wire,
            fifo1_read_en  => fifo1_read_en_wire,
            fifo2_read_en  => fifo2_read_en_wire,
            fifo1_write_en => fifo1_write_en_wire,
            fifo2_write_en => fifo2_write_en_wire,
            f_top    => f_top_wire,
            f_left   => f_left_wire,
            f_right  => f_right_wire,
            f_bottom => f_bottom_wire
        );

    image_location: acc_image_location_datapath
        generic map (
            width        => width,
            height       => height
        )
        port map (
            clk          => clk,
            reset        => reset,
            is_moving    => is_moving_wire,
            manual_reset => manual_reset_wire,
            f_top        => f_top_wire,
            f_left       => f_left_wire,
            f_right      => f_right_wire,
            f_bottom     => f_bottom_wire
        );
end rtl;
