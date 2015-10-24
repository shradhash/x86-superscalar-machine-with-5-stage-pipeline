module AluPipeline ( input logic reset,
                     input logic clk,
                     input logic alu_in_ready,
                     input Utilities::alu_inp_t alu_input,
                     output logic alu_out_ready,
                     output Utilities::alu_inp_t alu_output );

    import Utilities::*;
   
    logic alu_in_ready_ff, alu_out_ready_ff;
    alu_inp_t alu_input_ff;
    alu_inp_t alu_output_ff;
 
    always_ff @(posedge clk)
    begin
         if(reset)
         begin
             alu_in_ready_ff <= 0;
         end
         else
         begin
             alu_in_ready_ff <= alu_in_ready;
         end
         alu_input_ff <= alu_input;
    end
 
    always_ff @(posedge clk)
    begin
         if(reset)
         begin
             alu_out_ready_ff <= 0;
         end
         else
         begin
             alu_out_ready_ff <= alu_in_ready_ff;
             if (alu_in_ready_ff)
             begin
                alu_output_ff <= ALU::alu_main(alu_input_ff);
                print_sub_instructions(alu_output_ff);
             end 
         end
    end    
 
    assign alu_out_ready = alu_out_ready_ff;
    assign alu_output = alu_output_ff; 

endmodule
