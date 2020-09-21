library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;



entity two_one_mux is port (
   
   input_A	   :  in  std_logic_vector(3 downto 0);   
	input_B	   :  in  std_logic_vector(3 downto 0);   
	control		:  in	 std_logic;
	output		:  out std_logic_vector(3 downto 0)    -- 4bit output
); 
end two_one_mux;

architecture simple of two_one_mux is

begin
with control select						     --              -- data in   
	output 				    			   <= input_A when '0',    -- [0]
													input_B when others;		-- [1]	

end architecture simple; 
----------------------------------------------------------------------
