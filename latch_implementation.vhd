
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity latch_implementation is

  port ( latch_input: in std_logic ; 
  		latch_output: out std_logic; 
  		sampling_clock : in std_logic);

end entity;

architecture latch_architecture of latch_implementation is

signal latch_temp_output : std_logic ;

begin

process(sampling_clock)

begin

if rising_edge(sampling_clock) then 
	latch_temp_output <= latch_input;
end if;

end process;	

latch_output <= latch_temp_output;	

end latch_architecture;
