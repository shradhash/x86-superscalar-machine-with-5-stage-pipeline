/***********************************************************************************
 *  Programmed by : Shradha Shekhar
 *
 *  Supervised by : Ali Zamani
 * 
 *  Description   : Implementing an N Way Set Associative Ins Cache which is 
 *                  configurable. By default it is implemented as 4 ways.
 *                  The Cache line size is taken as 64 Bytes(also configurable).
 *                  and each way is 32KB in size.
 **********************************************************************************/                  

module cacheINway ( input clk,
                   input reset,
                   /* verilator lint_off UNUSED */
                   /* verilator lint_off UNDRIVEN */
                   input logic [63:0] input_addr,
                   output logic [0:64*8-1] read_data,
                   input logic reqcyc,
                   output logic respcyc_ff,
                   Mybus.Top bus
                   /* verilator lint_on UNUSED */
                   /* verilator lint_on UNDRIVEN */
                   );
  parameter N = 4;
  parameter indexbits = 9;
  parameter statebits = 2;
  parameter offsetbits = 6;

  logic [64*8-1:0] readdata[N];
  logic [64*8-1:0] writedata[N];
  logic [7:0] writeenable[N];
  
  logic [indexbits-1:0] index;
  logic [63-indexbits-offsetbits :0] inp_tag;
  //logic [2:0] offset;

  `define tagbits (64-indexbits-offsetbits)
  `define metadatabits `tagbits+statebits
  //`define cachelinesize (2^offsetbits * 8)

   logic [`metadatabits-1:0] readmetadata[N];
   logic [`metadatabits-1:0] writemetadata[N];
   logic  writemetaenable[N];

   int cb;
   int fb;
   int eb;
   int count;
   int count_ff;
   logic cache_respcyc;

   /* Control Signals */
   logic memrd_reqcyc;
   logic memrd_respcyc;
   logic [63:0] memrd_addr;
   logic [0:64*8-1] memrd_data;
 
   assign index = input_addr[indexbits+offsetbits-1 : offsetbits];
   assign inp_tag = input_addr[63 : indexbits + offsetbits];
   //assign offset =  input_addr[5:3];

   enum { IDLE,
          READCACHE,
          READMEMRY,
          NEXTSTATE }  state_ff, cache_state;

   function int locate_cache_block();
      int i;
   begin
      for (i=0; i<N; i=i+1)
      begin
         if (inp_tag == readmetadata[i][`tagbits-1:0] && readmetadata[i][`tagbits : `tagbits])
             return i;
      end
      return i;
   end
   endfunction

   function int free_cache_block();
      int i;
   begin
      for (i=0; i<N; i=i+1)
      begin
         if (readmetadata[i][`tagbits : `tagbits] != 1'b1)  /* Valid bit is not set */
             return i;
      end
      return i;
   end
   endfunction

   function int evict_cache_block();
   begin
      /* Random Block selected to be evicted */
      return count_ff % N;
   end
   endfunction

   always_ff @(posedge clk)
   begin
        if(reset)
        begin
             state_ff <= IDLE;
             count_ff <= 0;
        end
        else
        begin
             state_ff <= cache_state;
             respcyc_ff <= cache_respcyc;
             count_ff <= count;
             if(state_ff == IDLE && reqcyc)
             begin
                   state_ff <= READCACHE;
            end
       end
   end

   /*task automatic cache_init;
      int i;
   begin
      cb = 0;
      fb = 0;
      eb = 0;
      for (i = 0; i < N; i = i+1)
      begin
         writemetadata[i] = readmetadata[i];
         writeenable[i] = 8'b0;
         writemetaenable[i] = 1'b0;
      end
      count = count_ff;
   end
   endtask */

   task automatic request_memory_read;
       /* verilator lint_off UNUSED */
       input int free_block;
       input int evict_block;
       /* verilator lint_on UNUSED */
   begin
       /* There can be 3 cases :
             1. There is no free block, so a block needs to evicted and the evicted block has dirty bit set
             2. There is no free block, so a block needs to evicted and the evicted block does not have dirty bit set
             3. Free block is available */
       if (free_block >= N)
       begin
             /* No need to write to memory, just unset the valid bit and write that bit to metadata cache */
             writemetadata[evict_block][`tagbits : `tagbits] = 1'b0;
             writemetaenable[evict_block] = 1'b1;
             cache_state = NEXTSTATE;    /* Once the write is performed , original cache read or write which got stalled due to cache miss should perform */
       end
       else
       begin
          /* Free block is available, just read from memory to cache */
          memrd_reqcyc = 1'b1;
          memrd_addr = {inp_tag, index, 6'b0};
          cache_state = READMEMRY;
       end
   end
   endtask

   generate
       genvar icacheway;
       for (icacheway  = 0; icacheway < N; icacheway = icacheway + 1)
       begin
          SRAM #(.logDepth(indexbits))      icache (clk,
                                                    reset,
                                                    index,
                                                    readdata[icacheway],
                                                    index,
                                                    writedata[icacheway],
                                                    writeenable[icacheway]);
      end
   endgenerate

   generate
      genvar mcacheway;
      for (mcacheway = 0; mcacheway < N; mcacheway = mcacheway + 1)
      begin
        SRAM #(.width(`metadatabits),
               .logDepth(indexbits),
               .wordsize(`metadatabits)) midatacache (clk,
                                                     reset,
                                                     index,
                                                     readmetadata[mcacheway],
                                                     index,
                                                     writemetadata[mcacheway],
                                                     writemetaenable[mcacheway]);
      end
   endgenerate

   /* verilator lint_off UNDRIVEN */
   //Mybus mybusrd;
   /* verilator lint_on UNDRIVEN */

   MemoryReader mreader(reset,
                        clk,
                        bus,
                        memrd_reqcyc,
                        memrd_addr,
                        memrd_respcyc,
                        memrd_data);

   /* MemoryBusMux mmux(reset,
                        clk,
                        mybusrd,
                        mybuswr,
                        bus);  */
                                   
   always_comb
   begin
       int cnt;
       cache_state = state_ff;
       //cache_init(); 
 
       cb = locate_cache_block();
       fb = free_cache_block();
       eb = evict_cache_block();

       count = count_ff;

       for (cnt = 0; cnt < N; cnt = cnt+1)
       begin
         writemetadata[cnt] = readmetadata[cnt];
         writeenable[cnt] = 8'b0;
         writemetaenable[cnt] = 1'b0;
       end

       if (reset)
       begin
            memrd_reqcyc = 1'b0;
       end

       //$display("state_ff = %d  ", state_ff);
         
       case(state_ff)
            READCACHE  : begin
                            //$display("Inside Read Cache");
                            if (cb < N) /* Cache Hit */
                            begin
                               read_data = readdata[cb];
                               if (respcyc_ff == 1'b0)
                                   cache_respcyc = 1'b1;    /* Indicate that Cache Read has happened */
                               else  /*Cache Read already happened and conveyed */
                               begin 
                                   cache_state = IDLE;
                                   cache_respcyc = 1'b0;
                               end
                            end     
                            else /* Cache Miss - Fetch requested address into cache from memory */
                            begin
                               request_memory_read(fb, eb);
                            end
                         end

            READMEMRY  : begin
                           //$display("Read Memory  ");
                           if (memrd_respcyc)
                           begin
                              //$display("memrd_respcyc = %x ",memrd_respcyc);
                              //$display("memrd_data = %x", memrd_data);
                              writedata[fb] = memrd_data;
                              writeenable[fb] = 8'b11111111;
                              writemetadata[fb] = { 1'b0, 1'b1, inp_tag } ;  /* Set dirty bit to 0, valid bit to 1 and tag as the tag bits in the input address */
                              memrd_reqcyc = 1'b0;
                              writemetaenable[fb] = 1'b1;
                              cache_state = NEXTSTATE;
                           end 
                         end
 
            NEXTSTATE  : begin
                            if(reqcyc)
                                cache_state = READCACHE;
                         end
               
            default    : ;                     
       
       endcase 

   end

           
endmodule  
   
