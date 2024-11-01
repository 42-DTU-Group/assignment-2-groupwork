-- -----------------------------------------------------------------------------
--
--  Title      :  Components for the GCD module
--             :
--  Developers :  Jens Sparsø and Rasmus Bo Sørensen
--             :
--  Purpose    :  This design contains models of the components that must be
--             :  used to implement the GCD module.
--             :
--  Note       :  All the components have a generic parameter that sets the
--             :  bit-width of the component. This defaults to 16 bits, so in
--             :  this assignment there is no need to change it.
--             :
--  Revision   :  02203 fall 2017 v.5.0
--
-- -----------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- A generic positive edge-triggered register with enable. Width defaults to
-- 16 bits.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg is
    generic (
        n        : natural := 8              -- width of inputs.
    );
    port (
        clk      : in  std_logic;            -- clock signal.
        reset    : in  std_logic;            -- reset signal.
        en       : in  std_logic;            -- enable signal.
        data_in  : in  unsigned(n downto 1); -- input data.
        data_out : out unsigned(n downto 1)  -- output data.
    );
end reg;

architecture behaviour of reg is
begin
    process(clk,reset)
    begin
        if reset = '1' then
            data_out <= to_unsigned(0, n);
        elsif rising_edge (clk) then
            if en = '1' then
                data_out <= data_in;
            end if;
        end if;
    end process;
end behaviour;
