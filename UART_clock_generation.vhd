
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_clock_generation is 
	generic (number_of_clock_cycles : integer := 9); -- 
	port( main_clock: in std_logic;
	 	reset : in std_logic;
	 	uart_clock : out std_logic
		);
end entity;

architecture UART_clock_generation_architecture of UART_clock_generation is 

signal pos_count :integer ;
signal neg_count :integer ;
begin

process(main_clock,reset)

variable neg_count_var : integer := 0;

begin

if(not(reset) = '1') then
	pos_count <= 0;
	neg_count <= 0;

elsif (rising_edge(main_clock)) then
		if(pos_count = number_of_clock_cycles - 1) then
			pos_count <= 0;
		else
			pos_count <= pos_count + 1;
		end if;
end if;

if ((not reset) = '0' and falling_edge(main_clock)) then
		if(neg_count_var = number_of_clock_cycles - 1) then
			neg_count_var := 0;
		else
			neg_count_var := neg_count_var + 1;
		end if;
end if;

neg_count <= neg_count_var;
end process;

process(pos_count,neg_count)
begin
if ((pos_count > number_of_clock_cycles/2) or (neg_count > number_of_clock_cycles/2)) then
		uart_clock <= '1';
else
		uart_clock <= '0';
end if;
end process;

end UART_clock_generation_architecture; 