library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart is
    generic(
        CYCLES_PER_BIT: integer:= 234 -- 27,000,000 (27Mhz) / 115200 Baud rate
    );
    port(
        clk: in std_logic;
        uart_tx: out std_logic;
        uart_rx: in std_logic;
        byte_ready: out std_logic;
        byte_out: out std_logic_vector(7 downto 0);
        data_ready_led: out std_logic := '1';
        tx_data_in: in std_logic_vector(7 downto 0) := "00000000";
        tx_data_ready: in std_logic := '0'
    );
end;

architecture rtl of uart is
    type t_rx_state is (
        RX_STATE_IDLE,
        RX_STATE_START_BIT,
        RX_STATE_READ_WAIT,
        RX_STATE_READ,
        RX_STATE_STOP_BIT);
    signal rx_state: t_rx_state := RX_STATE_IDLE;
    signal CYCLES_PER_HALF_BIT: integer := CYCLES_PER_BIT / 2;
    signal rx_counter: integer := 0;
    signal rx_bit_number: integer := 0;
    signal rx_buffer: std_logic_vector (7 downto 0);
    signal data_ready_buffer: std_logic := '1';

    type t_tx_state is (
        TX_STATE_WAIT_FOR_IDLE,
        TX_STATE_IDLE,
        TX_STATE_START_BIT,
        TX_STATE_WRITE,
        TX_STATE_STOP_BIT);
    signal tx_state: t_tx_state := TX_STATE_IDLE;
    signal tx_counter: integer := 0;
    signal tx_bit_number: integer := 0;

    begin

    process(clk) is
    begin
        if (rising_edge(clk)) then
            case tx_state is
                when TX_STATE_WAIT_FOR_IDLE =>
                    if (tx_data_ready = '0') then
                        tx_state <= TX_STATE_IDLE;
                    else
                        tx_state <= TX_STATE_WAIT_FOR_IDLE;
                    end if;
                when TX_STATE_IDLE =>
                    if (tx_data_ready = '1') then
                        tx_state <= TX_STATE_START_BIT;
                        tx_counter <= 0;
                        tx_bit_number <= 0;
                    else
                        uart_tx <= '1';
                    end if;
                when TX_STATE_START_BIT =>
                    uart_tx <= '0';
                    if (tx_counter = CYCLES_PER_BIT) then
                        tx_state <= TX_STATE_WRITE;
                        tx_counter <= 0;
                    else
                        tx_counter <= tx_counter + 1;
                    end if;
                when TX_STATE_WRITE =>
                    uart_tx <= tx_data_in(tx_bit_number);
                    if (tx_counter + 1 = CYCLES_PER_BIT) then
                        if (tx_bit_number = 7) then
                            tx_state <= TX_STATE_STOP_BIT;
                        else
                            tx_state <= TX_STATE_WRITE;
                            tx_bit_number <= tx_bit_number + 1;
                        end if;
                        tx_counter <= 0;
                    else
                        tx_counter <= tx_counter + 1;
                    end if;
                when TX_STATE_STOP_BIT =>
                    uart_tx <= '1';
                    if (tx_counter + 1 = CYCLES_PER_BIT) then
                        tx_state <= TX_STATE_WAIT_FOR_IDLE;
                        tx_counter <= 0;
                    else
                        tx_state <= TX_STATE_STOP_BIT;
                        tx_counter <= tx_counter + 1;
                    end if;
            end case;
        end if;
    end process;

    process(clk) is
    begin
        if(rising_edge(clk)) then
            case rx_state is
                when RX_STATE_IDLE =>
                    if (uart_rx = '0') then
                        rx_state <= RX_STATE_START_BIT;
                        rx_counter <= 1;
                        rx_bit_number <= 0;
                        byte_ready <= '0';
                    end if;
                when RX_STATE_START_BIT =>
                    if (rx_counter = CYCLES_PER_HALF_BIT) then
                        rx_state <= RX_STATE_READ_WAIT;
                        rx_counter <= 1;
                    else
                        rx_counter <= rx_counter + 1;
                    end if;
                when RX_STATE_READ_WAIT =>
                    rx_counter <= rx_counter + 1;
                    -- +1 to account for extra clock cycle to do this check
                    if (rx_counter + 1 = CYCLES_PER_BIT) then
                        rx_state <= RX_STATE_READ;
                    end if;
                when RX_STATE_READ =>
                    rx_counter <= 1;
                    -- shift in uart_rx
                    rx_buffer <= uart_rx & rx_buffer(7 downto 1);
                    rx_bit_number <= rx_bit_number + 1;
                    if (rx_bit_number = 2#111#) then
                        rx_state <= RX_STATE_STOP_BIT;
                    else
                        rx_state <= RX_STATE_READ_WAIT;
                    end if;
                when RX_STATE_STOP_BIT =>
                    rx_counter <= rx_counter + 1;
                    if (rx_counter + 1 = CYCLES_PER_BIT) then
                        rx_state <= RX_STATE_IDLE;
                        rx_counter <= 0;
                        byte_ready <= '1';
                        byte_out <= rx_buffer;
                        data_ready_buffer <= not data_ready_buffer;
                        data_ready_led <= data_ready_buffer;
                    end if;
            end case;
        end if;
    end process;
end;
