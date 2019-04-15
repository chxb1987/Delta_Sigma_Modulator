
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_loopback is 
	generic (  sampling_cycles : integer := 150 ; -- Sampling_rate = 400KHz approximately
			   decimation_factor : integer := 10;-- 15KHz approximately
			   bitsize : integer := 8;
			   wait_cycles : integer := 30;
			   idle_number_of_cycles : integer := 1000;

			--number_of_clock_cycles: integer := 1302; -- This is for 9600bps
			--samples_per_bit : integer := 4);

			number_of_clock_cycles: integer := 18; -- This is for 460,800bps
			samples_per_bit : integer := 6);

			--number_of_clock_cycles: integer := 9; -- This is for 921,600bps.Doesn't work!
			--samples_per_bit : integer := 6);

	port( sys_clock: in std_logic;
	 	reset : in std_logic;
		tx_line : out std_logic;
		input_line : in std_logic;
		sampling_output : out std_logic;
		sampling_dense_output : out std_logic;
	 	tx_active : out std_logic;
	 	transmit_done : out std_logic
	 	);
end entity;

architecture UART_loopback_architecture of UART_loopback is 


component UART_clock_generation is 
	generic (number_of_clock_cycles : integer := 9); -- 
	port( main_clock: in std_logic;
	 	reset : in std_logic;
	 	uart_clock : out std_logic
	);
end component;

component pack_line is
	generic (bitsize : integer := 8;
			decimation_factor : integer := 10);
    port ( sampling_line : in std_logic;
		   sampling_clk : in std_logic;		
           reset : in std_logic;	
           pack_line_out_previous : out std_logic_vector(bitsize - 1  downto 0)
    );
end component;

component latch_implementation is

  port ( latch_input: in std_logic ; 
  		latch_output: out std_logic; 
  		sampling_clock : in std_logic);

end component;

component UART_tx is 
	generic (samples_per_bit : integer := 6;
			bitsize : integer := 5;
			idle_number_of_cycles : integer := 1000);
	port( uart_clock: in std_logic;
	 	reset : in std_logic;
	 	tx_data_array : in std_logic_vector(bitsize - 1  downto 0);
	 	tx_line : out std_logic;
	    tx_start_transmitting :  in std_logic;
	    tx_active : out std_logic;
	    transmit_done : out std_logic
		);
end component;

signal uart_clock : std_logic;

signal tx_start_transmitting_var : std_logic; -- Write 1 to indicate start of communication
signal tx_start_transmitting_1 : std_logic;
signal tx_start_transmitting_2 : std_logic;


signal transmit_done_var : std_logic; -- Reads output.Don't write to it
signal sampling_clk : std_logic;
signal sampled_input_line : std_logic;
signal packed_output : std_logic_vector(bitsize - 1 downto 0);

signal decimated_clock : std_logic ;

signal flag : std_logic;

--constant sampling_cycles : integer := number_of_clock_cycles*samples_per_bit;

begin
--

x_0 : UART_clock_generation 
		generic map (number_of_clock_cycles => sampling_cycles)
		port map ( main_clock => sys_clock,
		 		   reset => reset,
		 		   uart_clock => sampling_clk
			);

x_1 : latch_implementation
			 port map ( latch_input => input_line,
  						latch_output => sampled_input_line,
  						sampling_clock => sampling_clk);

x_2 : UART_clock_generation 
		generic map (number_of_clock_cycles => number_of_clock_cycles) -- number of clock cycles stands for number of
		port map ( main_clock => sys_clock,							   -- uart clock cycles each sys clock cycle.
		 		   reset => reset,
		 		   uart_clock => uart_clock
			);

x_3 : pack_line 
	generic map (bitsize => bitsize,
				decimation_factor => decimation_factor)
    port map( sampling_line => sampled_input_line,
		   sampling_clk => sampling_clk,		
           reset => reset,
           pack_line_out_previous => packed_output
    );

x_4 : UART_clock_generation 
		generic map (number_of_clock_cycles => decimation_factor*sampling_cycles)	-- Decimated from sampling clock by a factor of 
		port map ( main_clock => sys_clock,
		 		   reset => reset,
		 		   uart_clock => decimated_clock
			);


x_5 : UART_tx 
			generic map (samples_per_bit => samples_per_bit,
							bitsize => bitsize,
							idle_number_of_cycles => idle_number_of_cycles)
			port map (  reset => reset,
						uart_clock => uart_clock,
					 	tx_data_array => packed_output,
					 	tx_line => tx_line,
					    tx_start_transmitting => tx_start_transmitting_var,  -- Once we receive we retransmit it 
					    tx_active =>tx_active,
					    transmit_done => transmit_done_var
						);

process(sys_clock,reset,transmit_done_var,decimated_clock)

variable flag_var : std_logic := '0';
variable tx_start_transmitting_var_1 : std_logic := '0';

begin

	if((not reset) = '1') then
		flag_var := '0';
		tx_start_transmitting_var_1 := '0';
	elsif(transmit_done_var = '1') then
				tx_start_transmitting_var_1 := '0';
				flag_var := '0';
	elsif (rising_edge(decimated_clock)) then
		flag_var := '1';
		tx_start_transmitting_var_1 := '1';
	

	end if;
	

tx_start_transmitting_1 <= tx_start_transmitting_var_1;
flag <= flag_var;
end process;

process(sys_clock,reset,transmit_done_var,decimated_clock)
variable wait_cycles_count :  integer := 0;
variable tx_start_transmitting_var_2  : std_logic := '0';
begin

	if((not reset = '1')) then
		tx_start_transmitting_var_2 := '0';
	elsif(rising_edge(sys_clock)) then
		if(flag = '1') then
			if (wait_cycles_count = wait_cycles) then
					tx_start_transmitting_var_2 := '1';
					wait_cycles_count := 0;
			else 
					wait_cycles_count := wait_cycles_count + 1;
					--tx_start_transmitting_var_2 := '0';
			end if;
		else                                          -- This takes care of the case when transmission is done.
			tx_start_transmitting_var_2 := '0'; 
			wait_cycles_count := 0;
		end if;	
	end if;

tx_start_transmitting_2 <= tx_start_transmitting_var_2;
end process;

tx_start_transmitting_var <= tx_start_transmitting_1 and tx_start_transmitting_2;
transmit_done <= transmit_done_var;
sampling_output <= sampled_input_line;
sampling_dense_output <= sampled_input_line and sampling_clk;
end UART_loopback_architecture ; 