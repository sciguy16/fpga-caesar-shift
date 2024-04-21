library ieee;
use ieee.std_logic_1164.all;

entity hb is
    port(
        clk: in std_logic;
        hb_led: out std_logic
    );
end;

architecture rtl of hb is
    signal counter: integer := 0;
    begin
    process(clk) is
    begin
        if(rising_edge(clk)) then
            counter <= counter + 1;
            if (counter <= 13500000) then
                hb_led <= '1';
            else
                hb_led <= '0';
            end if;

            if(counter = 20000000) then
                counter <= 0;
            end if;
        end if;
    end process;
end;
