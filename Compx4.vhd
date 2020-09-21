library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity Compx4 is port (
   A		:in	std_logic_vector(3 downto 0);--Input bit
	B		:in	std_logic_vector(3 downto 0);--Input bit
	AGTB:out	std_logic;--1 if A>B
	AEQB:out	std_logic;--1 if A=B
	ALTB:out	std_logic--1 if A<B	
); 
end Compx4;

architecture fourbit_Comparator of Compx4 is

component Compx1 port(
	A		:in	std_logic;--Input bit
	B		:in	std_logic;--Input bit
	AGTB:out	std_logic;--1 if A>B
	AEQB:out	std_logic;--1 if A=B
	ALTB:out	std_logic--1 if A<B 
	);
	end component;
	
-- Here the circuit begins

signal AGTB_Compx1: std_logic_vector(3 downto 0); --greater than signals from single bit comparators
signal AEQB_Compx1: std_logic_vector(3 downto 0); --equal to signals from single bit comparators
signal ALTB_Compx1: std_logic_vector(3 downto 0); --less than signals from single bit comparators
signal ALTB_out: std_logic; --A<B signal
signal AEQB_out: std_logic; --A=B signal

begin
 
 INST1: Compx1 port map(A(3), B(3), AGTB_Compx1(3), AEQB_Compx1(3), ALTB_Compx1(3));
 INST2: Compx1 port map(A(2), B(2), AGTB_Compx1(2), AEQB_Compx1(2), ALTB_Compx1(2));
 INST3: Compx1 port map(A(1), B(1), AGTB_Compx1(1), AEQB_Compx1(1), ALTB_Compx1(1));
 INST4: Compx1 port map(A(0), B(0), AGTB_Compx1(0), AEQB_Compx1(0), ALTB_Compx1(0));
 --Single bit comparators A3B3, A2B2, A1B1, A0B0
 
 AEQB_out <= AEQB_Compx1(3) AND AEQB_Compx1(2) AND AEQB_Compx1(1) AND AEQB_Compx1(0);
 --compares signals from single bit comparators to determine if A=B
 ALTB_out <= ALTB_Compx1(3) OR (AEQB_Compx1(3) AND ALTB_Compx1(2)) OR (AEQB_Compx1(3) AND AEQB_Compx1(2) AND ALTB_Compx1(1)) OR (AEQB_Compx1(3) AND AEQB_Compx1(2) AND AEQB_Compx1(1) AND ALTB_Compx1(0));
 --compares signals from single bit comparators to determine if A<B
 ALTB <= ALTB_out;
 AEQB <= AEQB_out;
 --outputs signals
 AGTB <= ALTB_out NOR AEQB_out;
 --optimization to reduce number of gates, output for AGTB
end fourbit_Comparator;

