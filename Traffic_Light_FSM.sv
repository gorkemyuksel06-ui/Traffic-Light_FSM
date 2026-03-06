module traffic_fsm (
    input  logic clk,       // Clock signal
    input  logic reset,     // Asynchronous reset
    input  logic TAORB,     // Traffic Sensor (1: Street A has cars, 0: Street B has cars)
    output logic [2:0] LA,  // Light signals for Street A [Red, Yellow, Green]
    output logic [2:0] LB   // Light signals for Street B [Red, Yellow, Green]
);

    // State definitions using an enumerated type
    typedef enum logic [1:0] {
        S0, // State 0: LA is Green,  LB is Red
        S1, // State 1: LA is Yellow, LB is Red (Transition state)
        S2, // State 2: LA is Red,    LB is Green
        S3  // State 3: LA is Red,    LB is Yellow (Transition state)
    } state_t;

    state_t current_state, next_state;
    
    // Internal timer to manage the 5-clock cycle delay for yellow lights
    logic [2:0] timer;

    //--------------------------------------------------------------------------
    // 1. State Register & Timer Logic (Sequential)
    //--------------------------------------------------------------------------
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= S0;
            timer         <= 3'd0;
        end else begin
            current_state <= next_state;
            
            // Increment timer during yellow light states (S1 and S3)
            if (current_state == S1 || current_state == S3) begin
                if (timer < 3'd5) 
                    timer <= timer + 3'd1;
                else              
                    timer <= 3'd0; // Reset timer when limit is reached
            end else begin
                timer <= 3'd0; // Keep timer at 0 during Green states
            end
        end
    end

    //--------------------------------------------------------------------------
    // 2. Next-State Logic (Combinational)
    //--------------------------------------------------------------------------
    always_comb begin
        next_state = current_state; // Default: Stay in current state
        
        case (current_state)
            S0: begin
                // Transition to S1 if Street A is empty (~TAORB)
                if (!TAORB) next_state = S1;
            end
            
            S1: begin
                // Transition to S2 after 5 clock cycles
                if (timer >= 3'd5) next_state = S2;
            end

            S2: begin
                // Transition to S3 if Street B is empty (TAORB becomes true)
                if (TAORB) next_state = S3;
            end

            S3: begin
                // Transition back to S0 after 5 clock cycles
                if (timer >= 3'd5) next_state = S0;
            end
            
            default: next_state = S0;
        endcase
    end

    always_comb begin
      
        LA = 3'b100; 
        LB = 3'b100;
        
        case (current_state)
            S0: begin LA = 3'b001; LB = 3'b100; end // A: Green,  B: Red
            S1: begin LA = 3'b010; LB = 3'b100; end // A: Yellow, B: Red
            S2: begin LA = 3'b100; LB = 3'b001; end // A: Red,    B: Green
            S3: begin LA = 3'b100; LB = 3'b010; end // A: Red,    B: Yellow
        endcase
    end

endmodule
