library ieee;
use ieee.std_logic_1164.all;

entity top is
    port(
        clk: in std_logic;
        hb_led: out std_logic;
        data_ready_led: out std_logic;
        uart_tx: out std_logic;
        uart_rx: in std_logic
    );
end;

architecture rtl of top is

    signal uart_byte_ready: std_logic;
    signal uart_byte_out: std_logic_vector(7 downto 0);
    signal caesar_data_ready: std_logic;
    signal caesar_data_out: std_logic_vector(7 downto 0);

--    signal tx_data_in: std_logic_vector(7 downto 0) := "01101010";
--    signal tx_data_ready: std_logic := '1';

    begin

    hb1: entity work.hb(rtl)
        port map(
            clk => clk,
            hb_led => hb_led);

    uart: entity work.uart(rtl)
        port map(
            clk => clk,
            uart_tx => uart_tx,
            uart_rx => uart_rx,
            byte_ready => uart_byte_ready,
            byte_out => uart_byte_out,
            data_ready_led => data_ready_led,
            tx_data_in => caesar_data_out,
            tx_data_ready => caesar_data_ready);

    caesar: entity work.caesar(rtl)
        port map(
            clk => clk,
            byte_ready => uart_byte_ready,
            byte_in => uart_byte_out,
            data_ready => caesar_data_ready,
            data_out => caesar_data_out);

end rtl;
