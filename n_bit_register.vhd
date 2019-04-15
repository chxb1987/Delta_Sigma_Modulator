library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity n_bit_register is
	generic (bitsize : integer := 8);
    port ( reg_in : in std_logic_vector(bitsize - 1  downto 0);
		   clk : in std_logic;		
           reg_clr : in std_logic;		-- clear(asynchronous)
           reg_en : in std_logic	;	
           reg_out : out std_logic_vector(bitsize - 1  downto 0)
    );
end entity;

architecture register_architecture of n_bit_register is
signal reg_out_var : std_logic_vector(bitsize - 1  downto 0);
constant zero : std_logic_vector(reg_in'range) := (others => '0');

begin

process(reg_clr, clk,reg_en)

begin
if(not(reg_clr) = '1' ) then
	reg_out_var <= zero;
elsif (reg_en = '1' and rising_edge(clk)) then
	reg_out_var <= reg_in ;
end if;
end process;

reg_out <= reg_out_var;
end register_architecture;
