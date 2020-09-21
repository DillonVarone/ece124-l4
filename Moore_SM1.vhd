library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

Entity Moore_SM1 IS Port
(
 clk_input, rst_n					: IN std_logic;
 extender_en						: IN std_logic;
 extender_toggle					: IN std_logic;
 servo_state						: IN std_logic_vector(3 downto 0);
 extender_out						: OUT std_logic;
 clk_en								: OUT std_logic;
 l_r									: OUT std_logic;
 grappler_en						: OUT std_logic 
 );
END ENTITY;
 

 Architecture SM of Moore_SM1 is
 
  
 TYPE STATE_NAMES IS (Retracted, Extend, Retract, Extended);   -- list all the STATE_NAMES values but use more meaningful names

 
 SIGNAL current_state, next_state	:  STATE_NAMES;     	-- signals of type STATE_NAMES


 BEGIN
 
 --------------------------------------------------------------------------------
 --State Machine:
 --------------------------------------------------------------------------------

 -- REGISTER_LOGIC PROCESS:
 
Register_Section: PROCESS (clk_input, rst_n)  -- this process synchronizes the activity to a clock
BEGIN
	IF (rst_n = '0') THEN
		current_state <= Retracted;
	ELSIF(rising_edge(clk_input)) THEN
		current_state <= next_State;
	END IF;
END PROCESS;	



-- TRANSITION LOGIC PROCESS

Transition_Section: PROCESS (extender_en, extender_toggle, servo_state, current_state) 

BEGIN
     CASE current_state IS
          WHEN Retracted =>		
				IF (((NOT extender_toggle) AND extender_en)= '1') THEN
					next_state <= Extend;
				ELSE
					next_state <= Retracted;
				END IF;
			WHEN Extend =>		
				IF (servo_state = "1111") THEN
					next_state <= Extended;
				ELSE
					next_state <= Extend;
				END IF;
			WHEN Extended =>
				IF ((NOT extender_toggle) = '1') THEN
					next_state <= Retract;
				ELSE
					next_state <= Extended;
				END IF;
			WHEN Retract =>
				IF (servo_state = "0000") THEN
					next_state <= Retracted;
				ELSE
					next_state <= Retract;
				END IF;
				
			WHEN OTHERS =>
               next_state <= Retracted;
 		END CASE;

 END PROCESS;

-- DECODER SECTION PROCESS (Moore Form)

Decoder_Section: PROCESS (current_state) 

BEGIN
     CASE current_state IS
         		
         WHEN Extend =>		
			extender_out	<= '1';				
			clk_en			<= '1';					
			l_r				<= '1';			
			grappler_en		<= '0';	
			
			WHEN Extended =>		
			extender_out	<= '1';				
			clk_en			<= '0';					
			l_r				<= '0';			
			grappler_en		<= '1';	
			
			WHEN Retract =>		
			extender_out	<= '1';				
			clk_en			<= '1';					
			l_r				<= '0';			
			grappler_en		<= '0';					
				
         WHEN others =>		
 			extender_out	<= '0';				
			clk_en			<= '0';					
			l_r				<= '0';			
			grappler_en		<= '0';	
	  END CASE;
 END PROCESS;

 END ARCHITECTURE SM;
