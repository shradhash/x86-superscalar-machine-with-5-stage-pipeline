/* Fetch and Decode Queue */

module Queue #(INP_WIDTH = 64, OUT_WIDTH = 64, QUEUE_SIZE = 256 ) 
              (input logic reset,
               input logic clk,
               input logic en_queue,
               input int in_count,
               input logic[0: INP_WIDTH - 1] in_data,
               input logic de_queue,
               input int out_count,
               output logic[0: OUT_WIDTH -1] out_data,
               output int used_count,
               output int empty_count );

     parameter WIDTH = QUEUE_SIZE + 1;

     logic [0: WIDTH-1] queue_ff, new_queue;
     int head_ff, tail_ff;

     always_ff @ (posedge clk)
     begin

        /* On dequeue request, advance the head */     
        if (reset)
        begin
           head_ff <= 0;
        end
        else if (de_queue)
        begin
           assert(out_count <= used_count && out_count <= OUT_WIDTH) else $fatal;
           head_ff <= (head_ff + out_count) % WIDTH;
        end
    
        /* On enqueue request, advance the tail pointer */ 
        if (reset)
        begin
           tail_ff <= 0;
        end
        else if (en_queue)
        begin
           assert(in_count <= INP_WIDTH && INP_WIDTH <= empty_count) else $fatal;    
           tail_ff <= (tail_ff + in_count) % WIDTH;
           queue_ff <= new_queue;
        end
 
    end

    /* Dequeue operation - output the data from the queue 
       Since the queue is a circular queue, also take care of the end to end connection */
    always_comb 
    begin
       int linear_tail = (tail_ff < head_ff) ? WIDTH + tail_ff : tail_ff ;
       logic [0 : WIDTH + OUT_WIDTH -1] linear_queue = { queue_ff , queue_ff[0 : OUT_WIDTH -1] };
       out_data = linear_queue[head_ff +: OUT_WIDTH];
       used_count = linear_tail - head_ff;
       empty_count = WIDTH - used_count - 1;
    end

    /* Enqueue operation - add the input data into the queue
       Since the queue is circular, also take care of the end to end connection */
    always_comb
    begin
       logic [0 : WIDTH + INP_WIDTH - 1] linear_queue = {queue_ff , queue_ff[0 +: INP_WIDTH] };
       linear_queue[tail_ff +: INP_WIDTH] = in_data;
       new_queue = linear_queue[0 +: WIDTH];
       if (tail_ff + INP_WIDTH > WIDTH)
       begin
          new_queue[0 +: INP_WIDTH] = linear_queue[WIDTH +: INP_WIDTH];
       end
    end

endmodule  
