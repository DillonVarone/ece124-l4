library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;



entity two_one_mux_1bit is port (
   
   input_A	   :  in  std_logic;   
	input_B	   :  in  std_logic;   
	control		:  in	 std_logic;
	output		:  out std_logic    -- 1bit output
); 
end two_one_mux_1bit;

architecture simple of two_one_mux_1bit is

begin
with control select						     --              -- data in   
	output 				    			   <= input_A when '0',    -- [0]
													input_B when others;		-- [1]	

end architecture simple; 
----------------------------------------------------------------------
