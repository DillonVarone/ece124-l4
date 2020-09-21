
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY LogicalStep_Lab4_top IS
   PORT
	(
   clkin_50		: in	std_logic;
	rst_n			: in	std_logic;
	pb				: in	std_logic_vector(3 downto 0);
 	sw   			: in  std_logic_vector(7 downto 0); -- The switch inputs
   leds			: out std_logic_vector(7 downto 0);	-- for displaying the switch content
   seg7_data 	: out std_logic_vector(6 downto 0); -- 7-bit outputs to a 7-segment
	seg7_char1  : out	std_logic;							-- seg7 digi selectors
	seg7_char2  : out	std_logic							-- seg7 digi selectors
	);
END LogicalStep_Lab4_top;

ARCHITECTURE SimpleCircuit OF LogicalStep_Lab4_top IS
	
	component Bidir_shift_reg port
	(
		CLK			: in std_logic := '0';							--Takes Main_Clk (divided clk)
		RESET_n			: in std_logic := '0';						--Reset
		CLK_EN			: in std_logic := '0';						--Enables the shift when '1', no transitions when '0'
		LEFT0_RIGHT1	: in std_logic := '0';						--Shifts bits left when '1', right when '0'
		REG_BITS			: out std_logic_vector (3 downto 0)		--Outputs the current state of 4 registers (4 bit output)
	);
	end component;
	
	component U_D_Bin_Counter4bit port
	(
		CLK				: in std_logic := '0';						--Takes Main_Clk (divided clk)
		RESET_N			: in std_logic := '0';						--Reset
		CLK_EN			: in std_logic := '0';						--Enables counter when '1', do nothing when '0'
		UP1_DOWN0		: in std_logic := '0';						--counts up when '1', down when '0'	
		COUNTER_BITS	: out std_logic_vector(3 downto 0)		--outputs current value of the counter (1 hex)
	);
	end component;
	
	component Mealy_SM port
	(
		clk_input, rst_n								: IN std_logic;  						  --clock and reset input
		x_motion										: IN std_logic;  							  --push button 3, x-drive enable
		y_motion										: IN std_logic;  							  --push button 2, y drive enable
		extender_out									: IN std_logic; 						  --input from SM1, '0' if extender retracted
		x_comp											: IN std_logic_vector(2 downto 0); --X_EQ, X_GT, X_LT
		y_comp											: IN std_logic_vector(2 downto 0); --Y_EQ, Y_GT, Y_LT
		error_out										: OUT std_logic; 						  -- '1' if x_motion or y_motion engaged and extender not retracted
		extender_enable								: OUT std_logic;						  --RAC at specified location when '1'
		clk_en_x, u_d_x								: OUT std_logic;                   --control signals for x-drive counters
		clk_en_y, u_d_y								: OUT std_logic 						  --control signals for y-drive counters
	);
	end component;
	
	component Moore_SM1 port
	(
		 clk_input, rst_n					: IN std_logic;									--Main_clk input and reset
		 extender_en						: IN std_logic;									--extender can be used when '1'
		 extender_toggle					: IN std_logic;									--pushbutton input to toggle extend or retract
		 servo_state						: IN std_logic_vector(3 downto 0);			--4 bit input from shift register reporting state of servo motor
		 extender_out						: OUT std_logic;									--when extender is not retracted output '1'
		 clk_en								: OUT std_logic;									--Enable signal for shift register
		 l_r									: OUT std_logic;									--shifts left when '0', right when '1'
		 grappler_en						: OUT std_logic 									--Enables the grappler to be used when '1'
	);
	end component;
	
	component Moore_SM2 port
	(
		CLK		     		: in  std_logic := '0';				--Main_clk input
      RESET_n      		: in  std_logic := '0';				--Reset
		GRAP_BUTTON			: in  std_logic := '0';				--Push button input to use grappler 
		GRAP_ENBL			: in  std_logic := '0';				--input from Moore_SM1, '1' if extender is extended
      GRAP_ON			   : out std_logic						--'1' if grappler is in "hold" position
	);
	end component;
	
	component SevenSegment port
	(
		hex	   :  in  std_logic_vector(3 downto 0);   -- The 4 bit data to be displayed   
		sevenseg :  out std_logic_vector(6 downto 0)    -- 7-bit outputs to a 7-segment
	);
	end component;
	
	component segment7_mux port
	(
		clk         : in  std_logic := '0';						--takes Clkin_50
		DIN2 			: in  std_logic_vector(6 downto 0);		--Digit 2 7seg input
		DIN1 			: in  std_logic_vector(6 downto 0);		--Digit 1 7seg input
		DOUT			: out	std_logic_vector(6 downto 0);		--Current output digit in 7seg
		DIG2			: out	std_logic;								--
		DIG1			: out	std_logic		
	);
	end component;
	
	component compx4 port
	(
		A		:in	std_logic_vector(3 downto 0);			--Input bit
		B		:in	std_logic_vector(3 downto 0);			--Input bit
		AGTB	:out	std_logic;									--1 if A>B
		AEQB	:out	std_logic;									--1 if A=B
		ALTB	:out	std_logic									--1 if A<B	
	);
	end component;
	
	component two_one_mux port
	(
		input_A	   :  in  std_logic_vector(3 downto 0);   
		input_B	   :  in  std_logic_vector(3 downto 0);   
		control		:  in	 std_logic;
		output		:  out std_logic_vector(3 downto 0)    -- 4bit output
	);
	end component;
	
	component two_one_mux_1bit port
	(
		input_A	   :  in  std_logic;   
		input_B	   :  in  std_logic;   
		control		:  in	 std_logic;
		output		:  out std_logic    -- 1bit output
	);
	end component;
	
----------------------------------------------------------------------------------------------------
	CONSTANT	SIM							:  boolean := FALSE; 	-- set to TRUE for simulation runs otherwise keep at 0.
   CONSTANT CLK_DIV_SIZE				: 	INTEGER := 26;    -- size of vectors for the counters

   SIGNAL 	Main_CLK						:  STD_LOGIC; 											-- main clock to drive sequencing of State Machine

	SIGNAL 	bin_counter					:  UNSIGNED(CLK_DIV_SIZE-1 downto 0); 			-- := to_unsigned(0,CLK_DIV_SIZE); -- reset binary counter to zero
	
	
	SIGNAL	extender_out				:	std_logic;											--extender out signal from Moore_SM1
	SIGNAL	extender_en					:	std_logic;											--extender enable signal from Mealy_SM
	
	SIGNAL 	clk_en_x, u_d_x			:	std_logic;											--enable signals for up down shift registers, and direction bit					
	SIGNAL 	clk_en_y, u_d_y			:	std_logic;
	SIGNAL	x_pos							:	std_logic_vector(3 downto 0);					--current position of RAC from shift registers
	SIGNAL	y_pos							:	std_logic_vector(3 downto 0);
	SIGNAL	x_comp						:	std_logic_vector(2 downto 0);					--signals from x/y-comparator, ex: X_EQ, X_GT, X_LT
	SIGNAL	y_comp						:	std_logic_vector(2 downto 0);		

	SIGNAL	x_hex							:	std_logic_vector(3 downto 0);					--selection between current position, and desired position 
	SIGNAL	y_hex							:  std_logic_vector(3 downto 0);	
	
	SIGNAL	error							:	std_logic;											--'1' if Mealy in error state
	
	SIGNAL	servo_state					: 	std_logic_vector(3 downto 0);					--4 bit input from shift register reporting state of servo motor
	SIGNAL	servo_clk_en				:	std_logic;											--Enable signal for shift register
	SIGNAL	l_r							:	std_logic;											--shifts left when '0', right when '1'
	SIGNAL	grappler_en					:	std_logic;											--'1' when extender is fully extended
	
	
	SIGNAL	DIN1						:std_logic_vector(6 downto 0);						--x coordinate in 7seg
	SIGNAL	DIN2						:std_logic_vector(6 downto 0);						--y coordinate in 7seg
	SIGNAL 	seg7_dig1				: std_logic;												--7seg display enable signals
	SIGNAL 	seg7_dig2				: std_logic;
	
	SIGNAL	error_flash				: std_logic;												--control signal for flashing mux
----------------------------------------------------------------------------------------------------
BEGIN

leds(7 downto 4) <= servo_state;
--maps 4 bit servo_state to leds 7 to 4
leds(0) <= error;
--maps error signal to led0
leds(2) <= pb(0); 
-- for debugging

RAC_Control: Mealy_SM port map (main_clk, rst_n, pb(3), pb(2), extender_out, x_comp, y_comp, error, extender_en, clk_en_x, u_d_x, clk_en_y, u_d_y);
--Takes in a variety of inputs to switch between 4 states, outputs control x/y counters, extender and error signal

X_UD: U_D_Bin_Counter4bit port map (main_clk, rst_n, clk_en_x, u_d_x, x_pos);
--counter for current x position

Y_UD: U_D_Bin_Counter4bit port map (main_clk, rst_n, clk_en_y, u_d_y, y_pos);
--counter for current y position

X_COMPARE: compx4	port map (x_pos, sw(7 downto 4), x_comp(1), x_comp(2), x_comp(0));
Y_COMPARE: compx4	port map (y_pos, sw(3 downto 0), y_comp(1), y_comp(2), y_comp(0));
--compares y and x positions from shift registers to desired positions from switches

Extender_Control: Moore_SM1 port map (main_clk, rst_n, extender_en, pb(1), servo_state, extender_out, servo_clk_en, l_r, grappler_en); 
--controls the extender and its associated shift register and enables grappler

Extender_Reg: Bidir_Shift_Reg port map (main_clk, rst_n, servo_clk_en, l_r, servo_state);
--shift register for extender

Grappler_Control: Moore_SM2 port map (main_clk, rst_n, NOT pb(0), grappler_en, leds(3));
--controls grappler

X_select: two_one_mux port map (x_pos, sw(7 downto 4), pb(3), x_hex); 
Y_select: two_one_mux port map (y_pos, sw(3 downto 0), pb(2), y_hex);
--switch between current position (when moving) and desired (when not moving) for output displays 

x_7seg: SevenSegment port map (x_hex, DIN1);
y_7seg: SevenSegment port map (y_hex, DIN2);
--converts x/y coordinates to 7seg

seg7_mux:	segment7_mux port map (clkin_50, DIN2, DIN1, seg7_data, seg7_dig2, seg7_dig1);
--controls 7seg displays

Error_Select: two_one_mux_1bit port map ('0', main_clk, error, error_flash);
--When in error state, selects new control signal for 7seg enable muxs

Flash_x: two_one_mux_1bit port map (seg7_dig1, '0', error_flash, seg7_char1);
Flash_y: two_one_mux_1bit port map (seg7_dig2, '0', error_flash, seg7_char2);
--when in error state, 7seg display enable signals switch between normal operation and off, resulting in "flash"



-- CLOCKING GENERATOR WHICH DIVIDES THE INPUT CLOCK DOWN TO A LOWER FREQUENCY

BinCLK: PROCESS(clkin_50, rst_n) is
   BEGIN
		IF (rising_edge(clkin_50)) THEN -- binary counter increments on rising clock edge
         bin_counter <= bin_counter + 1;
      END IF;
   END PROCESS;

Clock_Source:
				Main_Clk <= 
				clkin_50 when sim = TRUE else				-- for simulations only
				std_logic(bin_counter(23));								-- for real FPGA operation
					
---------------------------------------------------------------------------------------------------

END SimpleCircuit;
