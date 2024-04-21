library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity caesar is
    generic(
        SHIFT: integer:= 3 -- military grade
    );
    port(
        clk: in std_logic;
        byte_ready: in std_logic;
        byte_in: in std_logic_vector(7 downto 0);
        data_ready: out std_logic;
        data_out: out std_logic_vector(7 downto 0)
    );
end;

architecture rtl of caesar is
    
    begin
    process(clk) is
    begin
        if(rising_edge(clk)) then
            data_ready <= '0';
            if (byte_ready = '1') then
                if (
                    to_integer(unsigned(byte_in)) >= 97 and
                    to_integer(unsigned(byte_in)) <= 122) then
                    data_out <= std_logic_vector(to_unsigned(
                        (((to_integer(unsigned(byte_in)) - 97) + SHIFT) mod 26 + 97),
                        data_out'length));
                elsif (
                    to_integer(unsigned(byte_in)) >= 65 and
                    to_integer(unsigned(byte_in)) <= 90) then
                    data_out <= std_logic_vector(to_unsigned(
                        (((to_integer(unsigned(byte_in)) - 65) + SHIFT) mod 26 + 65),
                        data_out'length));
                else
                    data_out <= byte_in;
                end if;
                data_ready <= '1';
            end if;
        end if;
    end process;
end;
