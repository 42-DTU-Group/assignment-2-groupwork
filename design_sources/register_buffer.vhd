library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity three_RAM_row_buffer is
    port (
        clk, reset : in std_logic;
        en         : in std_logic;
        data_in    : in unsigned(31 downto 0);
        data_out_1 : out unsigned(31 downto 0);
        data_out_2 : out unsigned(31 downto 0);
        data_out_3 : out unsigned(31 downto 0)
    );
end three_RAM_row_buffer;

architecture rtl of three_RAM_row_buffer is
    signal reg1, reg2, reg3 : unsigned(31 downto 0);
begin
    process (clk, reset)
    begin
        if reset = '1' then
            reg1 <= (others => '0');
            reg2 <= (others => '0');
            reg3 <= (others => '0');
        elsif rising_edge(clk) then
            if en = '1' then
                reg1 <= data_in;
                reg2 <= reg1;
                reg3 <= reg2;
            end if;
        end if;
    end process;

    data_out_1 <= reg1;
    data_out_2 <= reg2;
    data_out_3 <= reg3;
end rtl;