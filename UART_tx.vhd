
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_tx is 
	generic (samples_per_bit : integer := 6;
			bitsize : integer := 5;
			idle_number_of_cycles : integer := 1000);
	port(uart_clock: in std_logic;
	 	reset : in std_logic;
	 	tx_data_array : in std_logic_vector(bitsize-1 downto 0);
	 	tx_line : out std_logic;
	    tx_start_transmitting :  in std_logic;
	    tx_active : out std_logic;
	    transmit_done : out std_logic
		);
end entity;

architecture UART_tx_architecture of UART_tx is 


type state_type_tx is (tx_idle,tx_data_bits,tx_start_bit,tx_stop_bit,tx_exit);
signal state : state_type_tx := tx_idle;

begin

process(reset,uart_clock,tx_start_transmitting) 

variable count : integer := 0;
variable number_of_bits : integer := 0;
variable idle_number_of_cycles_count : integer := 0;

begin

	if(not(reset) = '1' ) then

		count := 0;
		number_of_bits := 0;

		state <= tx_idle;
		tx_line <= '1';
		tx_active <= '0';
		transmit_done <= '0';
		idle_number_of_cycles_count := 0;

	elsif(tx_start_transmitting = '0') then

		count := 0;
		number_of_bits := 0;

		state <= tx_idle;
		tx_line <= '1';
		tx_active <= '0';
		transmit_done <= '0';
		idle_number_of_cycles_count := idle_number_of_cycles;


	elsif(rising_edge(uart_clock)) then
		case(state) is 
			
		when	tx_idle => 	tx_active <= '0';
							transmit_done <='0';
							tx_line <= '1';
						
						if(tx_start_transmitting = '0') then 
							state <= tx_idle;
							count := 0;
						else
							if(idle_number_of_cycles_count = idle_number_of_cycles) then
								state <= tx_start_bit;	
								count := 0;	
							else
								idle_number_of_cycles_count := idle_number_of_cycles_count + 1;
						end if;
					end if;

		when	tx_start_bit =>  tx_active <= '1';
								 transmit_done <= '0';
								 tx_line <= '0';
								if(count = samples_per_bit - 1) then
										state <= tx_data_bits;
										number_of_bits := 0;
										count := 0;
								 else
								 		count := count + 1;
								 		state <= tx_start_bit;
								 end if;
								

		when 	tx_data_bits => tx_active <= '1';
								tx_line <= tx_data_array(number_of_bits);
								transmit_done <= '0';

								if(count = samples_per_bit - 1) then
									if(number_of_bits = bitsize-1) then
										number_of_bits := 0;
										state <= tx_stop_bit;
									else
										number_of_bits := number_of_bits+1;
										state <= tx_data_bits;
									end if;
									
									count := 0;
								else
									count := count + 1 ;
									state<= tx_data_bits;
								end if;
								

		when	tx_stop_bit =>  tx_active <= '1';
								tx_line <= '1';
								transmit_done <= '0';
							   if(count = samples_per_bit - 1) then
										state <= tx_exit;
										number_of_bits := 0;
										count := 0;
								 else
								 		count := count + 1;
								 end if;

		when tx_exit => 	tx_active <= '0';
							tx_line <= '1';
							transmit_done <= '1';

							if(count = samples_per_bit - 1) then
										state <= tx_idle;
										number_of_bits := 0;
										idle_number_of_cycles_count := idle_number_of_cycles ;
										count := 0;
								 else
								 		count := count + 1;
								 end if;

		when others => state <= tx_idle;


		end case;


	end if;

end process;


end UART_tx_architecture; 