library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity Compx1 is port (
   A		:in	std_logic;--Input bit
	B		:in	std_logic;--Input bit
	AGTB:out	std_logic;--1 if A>B
	AEQB:out	std_logic;--1 if A=B
	ALTB:out	std_logic--1 if A<B	
); 
end Compx1;

architecture Comparator of Compx1 is
	
	
-- Here the circuit begins

begin
 
AGTB<= A AND (NOT B);	--1 if A>B
AEQB<= A XNOR B;			--1 if A=B
ALTB<= (NOT A) AND B ;	--1 if A<B
 
end Comparator;

