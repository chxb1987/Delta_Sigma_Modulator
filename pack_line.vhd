library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use ieee.numeric_std.all;

entity pack_line is
	generic (bitsize : integer := 8;
			decimation_factor : integer := 10);
    port ( sampling_line : in std_logic;
		   sampling_clk : in std_logic;		
           reset : in std_logic;	
           pack_line_out_previous : out std_logic_vector(bitsize - 1  downto 0)
    );
end entity;

architecture pack_line_architecture of pack_line is

component n_bit_register is
	generic (bitsize : integer := 8);
    port ( reg_in : in std_logic_vector(bitsize - 1  downto 0);
		   clk : in std_logic;		
           reg_clr : in std_logic;		-- clear(asynchronous)
           reg_en : in std_logic	;	
           reg_out : out std_logic_vector(bitsize - 1  downto 0)
    );
end component;

signal reg_in : std_logic_vector(bitsize - 1 downto 0) ;
signal reg_en : std_logic := '0';

signal reg_en_previous : std_logic := '0';

signal pack_line_out :std_logic_vector(bitsize - 1 downto 0) ;

begin
x_1 : n_bit_register 
			generic map(bitsize => bitsize)
			port map(reg_in => reg_in,
					clk => sampling_clk,
					reg_clr => reset,
					reg_en => reg_en,
					reg_out => pack_line_out);  -- This is for tx_data_array

x_2: n_bit_register 
			generic map(bitsize => bitsize)
			port map(reg_in => pack_line_out,
					clk => sampling_clk,
					reg_clr => reset,
					reg_en => reg_en_previous,
					reg_out => pack_line_out_previous);

process(sampling_clk,reset,reg_en,sampling_line)

variable count : integer := 0;
variable value : integer := 0;
begin

if((not reset) = '1') then

	reg_en_previous <= '1'; -- This will ensure that reg_en_previous is zero initially 
							-- as registers are initialized to zero upon reset(in my code).
elsif(rising_edge(sampling_clk)) then

	if(count = decimation_factor - 1) then
		count := 0;
		value := 0;
		reg_en <= '1';
		reg_en_previous <= '1';

	else
		count := count + 1;
			if(sampling_line = '1') then
				value := value + 1;
				reg_en <= '1'; -- Maybe we don't need this 
			else
				reg_en <= '0';
			end if;
		reg_en_previous <= '0';
	end if;
end if;

reg_in <= std_logic_vector(to_unsigned(value, pack_line_out'length));
end process;
end pack_line_architecture;
