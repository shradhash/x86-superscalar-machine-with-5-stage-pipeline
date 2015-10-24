/***********************************************************************************
 *  Programmed by : Shradha Shekhar
 *
 *  Supervised by : Ali Zamani
 * 
 *  Description   : Implementing an N Way Set Associative Data Cache which is 
 *                  configurable. By default it is implemented as 4 ways.
 *                  The Cache line size is taken as 64 Bytes(also configurable).
 *                  and each way is 32KB in size.
 *                  The write policy used is Write Back with Write Allocate.
 **********************************************************************************/                  

module cacheNway ( input clk,
                   input reset,
                   /* verilator lint_off UNUSED */
                   /* verilator lint_off UNDRIVEN */
                   input logic [63:0] input_addr,
                   output logic [63:0] read_data,
                   input logic [63:0] write_data,
                   output logic respcyc_ff,
                   input CACHE::req_type req_t,
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
  logic [2:0] offset;

  `define tagbits (64-indexbits-offsetbits)
  `define metadatabits `tagbits+statebits

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
   logic memwr_reqcyc;
   logic memrd_respcyc;
   logic memwr_respcyc;
   logic [63:0] memrd_addr;
   logic [63:0] memwr_addr;
   logic [0:64*8-1] memrd_data;
   logic [0:64*8-1] memwr_data;

   /* verilator lint_off WIDTH */
 
   assign index = input_addr[indexbits+offsetbits-1 : offsetbits];
   assign inp_tag = input_addr[63 : indexbits + offsetbits];
   assign offset =  input_addr[5:3];

   enum { IDLE,
          READCACHE,
          WRITECACHE,
          FLUSHCACHE,
          READMEMRY,
          WRITEMEMRY,
          FLUSHCHACK,
          NEXTSTATE }  state_ff, cache_state;

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
             if(state_ff == IDLE)
             begin
                  case(req_t)
                     CACHE::READ: state_ff <= READCACHE;
                     CACHE::WRITE: state_ff <= WRITECACHE;
                     CACHE::FLUSH: state_ff <= FLUSHCACHE;
                     default: state_ff <= IDLE;
                  endcase
            end
       end
   end

   generate
       genvar dcacheway;
       for (dcacheway  = 0; dcacheway < N; dcacheway = dcacheway + 1)
       begin
          SRAM #(.logDepth(indexbits))   datacache (clk,
                                                    reset,
                                                    index,
                                                    readdata[dcacheway],
                                                    index,
                                                    writedata[dcacheway],
                                                    writeenable[dcacheway]);
      end
   endgenerate

   generate
      genvar mcacheway;
      for (mcacheway = 0; mcacheway < N; mcacheway = mcacheway + 1)
      begin
        SRAM #(.width(`metadatabits),
               .logDepth(indexbits),  
               .wordsize(`metadatabits))  datacache (clk,
                                                     reset,
                                                     index,
                                                     readmetadata[mcacheway],
                                                     index,
                                                     writemetadata[mcacheway],
                                                     writemetaenable[mcacheway]);
      end
   endgenerate

   /* verilator lint_off UNDRIVEN */
   Mybus mybusrd, mybuswr;
   /* verilator lint_on UNDRIVEN */

   MemoryReader mreader(reset,
                        clk,
                        mybusrd,
                        memrd_reqcyc,
                        memrd_addr,
                        memrd_respcyc,
                        memrd_data);

   MemoryWriter mwriter (reset,
                         clk,
                         mybuswr,
                         memwr_reqcyc,
                         memwr_addr,
                         memwr_respcyc,
                         memwr_data);

   MemoryBusMux mmux(reset,
                     clk,
                     mybusrd,
                     mybuswr,
                     bus);  

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

   task automatic cache_init;
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
   endtask

   task automatic request_memory_read;
       input int free_block;
       /* verilator lint_off UNUSED */
       input int evict_block;
       /* verilator lint_on UNUSED */
   begin
       /* There can be 3 cases :
             1. There is no free block, so a block needs to evicted and the evicted block has dirty bit set
             2. There is no free block, so a block needs to evicted and the evicted block does not have dirty bit set
             3. Free block is available */
         if (free_block >= N)
       begin
           if (readmetadata[free_block][`tagbits+1 : `tagbits+1] == 1'b1)
           begin
             /* Perform write back to memory */
             memwr_reqcyc = 1'b1;  /* Raise request for memory write */
             memwr_data = readdata[evict_block];
             memwr_addr = {readmetadata[evict_block][`tagbits-1 : 0], index , 6'b0};
             cache_state = WRITEMEMRY;
           end
           else
           begin
             /* No need to write to memory, just unset the valid bit and write that bit to metadata cache */
             writemetadata[evict_block][`tagbits : `tagbits] = 1'b0;
             writemetaenable[evict_block] = 1'b1;
             cache_state = NEXTSTATE;    /* Once the write is performed , original cache read or write which got stalled due to cache miss should perform */
           end
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
                                 
   always_comb
   begin
       cache_state = state_ff;
       cache_init(); 
 
       cb = locate_cache_block();
       fb = free_cache_block();
       eb = evict_cache_block();

       if (reset)
       begin
            memrd_reqcyc = 1'b0;
            memwr_reqcyc = 1'b0;
       end
 
       case(state_ff)
            FLUSHCACHE : begin
                            if (cb < N && readmetadata[cb][`tagbits + 1 : `tagbits + 1] == 1'b1) /* Valid cache block and dirty bit is set */
                            begin
                               memwr_reqcyc = 1'b1;
                               memwr_data = readdata[cb];
                               memwr_addr = {inp_tag, index, 6'b0};
                               cache_state = FLUSHCHACK;
                            end
                            if (respcyc_ff == 1'b0)
                               cache_respcyc = 1'b1;    /* Indicate that Cache Flush has happened */
                            else  /*Cache Flush already happened and conveyed */
                            begin
                               cache_state = IDLE;
                               cache_respcyc = 1'b0;
                            end
                         end
                            
            FLUSHCHACK : begin
                            /* Cache is flushed to memory , now unset the dirty bit and write to metadata cache */
                            if (memwr_respcyc == 1'b1)
                            begin
                                writemetadata[cb][`tagbits+1 : `tagbits+1] = 1'b0;
                                writemetaenable[cb] = 1'b1;
                                memwr_reqcyc = 1'b0;
                                cache_state = NEXTSTATE;
                            end          
                         end

            READCACHE  : begin
                            if (cb < N) /* Cache Hit */
                            begin
                               read_data = readdata[cb][(7-offset)*64 +: 64];
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

            WRITECACHE : begin
                            if (cb < N)  /* Cache Hit */
                            begin
                               writedata[cb][(7-offset)*64 +: 64] = write_data;
                               writemetadata[cb][`tagbits + 1 : `tagbits + 1] = 1'b1;    /* Set the dirty bit */
                               if (respcyc_ff == 1'b0)
                               begin
                                  writeenable[cb][(7-offset) +: 1] = 1'b1;  /* Write respective wordsize to cache */
                                  writemetaenable[cb] = 1'b1;   /* Write respective meta data - dirty bit is set in the data */
                                  cache_respcyc = 1'b1;  /* Indicate Cache Write has been done */
                               end
                               else 
                               begin
                                  cache_state = IDLE;
                                  cache_respcyc = 1'b0;
                               end
                            end
                            else /* Cache Miss - Fetch requested address into cache from memory */
                            begin 
                               request_memory_read(fb,eb);
                            end
                         end

            READMEMRY  : begin
                           if (memrd_respcyc == 1'b1)
                           begin
                              writedata[fb] = memrd_data;
                              writeenable[fb] = 8'b11111111;
                              writemetadata[fb] = { 1'b0, 1'b1, inp_tag } ;  /* Set dirty bit to 0, valid bit to 1 and tag as the tag bits in the input address */
                              memrd_reqcyc = 1'b0;
                              writemetaenable[fb] = 1'b1;
                              cache_state = NEXTSTATE;
                           end 
                         end
 
            WRITEMEMRY : begin
                            if (memrd_respcyc == 1'b1)
                            begin
                               writemetadata[eb][`tagbits : `tagbits] = 1'b0;
                               writemetaenable[eb] = 1'b1;
                               count = count_ff + 1;
                               memwr_reqcyc = 1'b0; 
                               cache_state = NEXTSTATE;
                            end
                         end       

            NEXTSTATE  : begin
                            case(req_t)
                               CACHE::READ  : cache_state = READCACHE;
                               CACHE::WRITE : cache_state = WRITECACHE;
                               CACHE::FLUSH : cache_state = FLUSHCACHE;
                               CACHE::IDLE  : cache_state = IDLE;
                               default    : cache_state = IDLE;
                            endcase
                         end
               
            default    : ;                     
       
       endcase 

   end
         
/* verilator lint_on WIDTH */
endmodule  
   
