library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

Entity Mealy_SM IS Port
(
 clk_input, rst_n								: IN std_logic;  --clock and reset input
 x_motion										: IN std_logic;  --push button 3, x-drive enable
 y_motion										: IN std_logic;  --push button 2, y drive enable
 extender_out									: IN std_logic;  --input from SM1, '0' if extender retracted
 x_comp											: IN std_logic_vector(2 downto 0); --X_EQ, X_GT, X_LT
 y_comp											: IN std_logic_vector(2 downto 0); --Y_EQ, Y_GT, Y_LT
 error_out										: OUT std_logic; -- '1' if x_motion or y_motion engaged and extender not retracted
 extender_enable								: OUT std_logic; --RAC at specified location
 clk_en_x, u_d_x								: OUT std_logic; --control signals for x-drive
 clk_en_y, u_d_y								: OUT std_logic; --control signals for y-drive
 con_x, con_y									: OUT std_logic
 );
END ENTITY;
 

 Architecture SM of Mealy_SM is
 
  
 TYPE STATE_NAMES IS (Start, Move, Error, At_Position);   -- list all the STATE_NAMES values but use more meaningful names

 
 SIGNAL current_state, next_state	:  STATE_NAMES;     	-- signals of type STATE_NAMES


 BEGIN
 
 --------------------------------------------------------------------------------
 --State Machine:
 --------------------------------------------------------------------------------

 -- REGISTER_LOGIC PROCESS:
 
Register_Section: PROCESS (clk_input, rst_n)  -- this process synchronizes the activity to a clock
BEGIN
	IF (rst_n = '0') THEN
		current_state <= Start;
	ELSIF(rising_edge(clk_input)) THEN
		current_state <= next_State;
	END IF;
END PROCESS;	



-- TRANSITION LOGIC PROCESS

Transition_Section: PROCESS (x_motion, y_motion, extender_out, x_comp, y_comp, current_state) 

BEGIN
     CASE current_state IS
         WHEN  Start =>		
				IF(((((NOT x_motion) AND (NOT x_comp(2))) OR ((NOT y_motion) AND (NOT y_comp(2)))) AND extender_out) = '1') THEN --TODO should only engage when x_comp or y_comp is not equivalent
					next_state <= Error;
				ELSIF ((((NOT x_motion) OR (NOT y_motion)) AND (NOT extender_out) AND ((NOT x_comp(2)) OR (NOT y_comp(2)))) = '1') THEN
					next_state <= Move;
				ELSIF ((x_comp(2) AND y_comp(2)) = '1') THEN
					next_state <= At_Position;
				ELSE
					next_state <= Start;
				END IF;       
			WHEN Error => 
				IF ((NOT extender_out) = '1') THEN
					next_state <= Start;
				ELSE
					next_state <= Error;
				END IF;
			WHEN Move =>
				IF ((x_comp(2) AND y_comp(2)) = '1') THEN
					next_state <= At_Position;
				ELSIF (((NOT (x_comp(2) AND y_comp(2))) AND ((NOT x_motion) OR (NOT y_motion))) = '1') THEN
					next_state <= Move;
				ELSE
					next_state <= Start;
				END IF;
			WHEN At_Position =>
				IF ((x_comp(2) AND y_comp(2)) = '1') THEN
					next_state <= At_Position;
				ELSE
					next_state <= Start;
				END IF;
			WHEN OTHERS =>
               next_state <= Start;
 		END CASE;

 END PROCESS;

-- DECODER SECTION PROCESS (Mealy Form)

Decoder_Section: PROCESS (clk_input, x_motion, y_motion, x_comp, y_comp, current_state, extender_out) 

	BEGIN
		IF (current_state = Move) THEN
			--X
			IF (x_comp(2) = '0') THEN
			clk_en_x <=  NOT x_motion;
			ELSE
			--clk_en_x <= '0';
			clk_en_x <= NOT x_comp(2);
			END IF;
			--clk_en_x <= (NOT x_motion) AND (NOT x_comp(2)); --Active Low
			
			u_d_x <= x_comp(0);
			
			--Y
			IF (y_comp(2) = '0') THEN
			clk_en_y <= NOT y_motion;
			ELSE
			--clk_en_y <= '0';
			clk_en_y <= NOT y_comp(2);
			END IF;
			--clk_en_y <= (NOT y_motion) AND (NOT y_comp(2)); --Active Low
			
			u_d_y <= y_comp(0);
			
		ELSIF (current_state = Error) THEN
			error_out <= extender_out;
			--error_out <= '1';
			extender_enable <= extender_out;	
			--error_out <= '1';
			con_x <= clk_input;
			con_y <= clk_input;
		ELSIF (current_state = At_Position) THEN
			extender_enable <= x_comp(2) AND y_comp(2);
			--extender_enable <= '1';
		ELSE
			extender_enable <= '0';
			error_out		 <= '0';
			clk_en_x 		 <= '0';
			clk_en_y 		 <= '0';
			u_d_x 			 <= '0';
			u_d_y				 <= '0';
			con_x 			 <= '1';
			con_y				 <= '1';
		END IF;     
	END PROCESS;

 END ARCHITECTURE SM;
