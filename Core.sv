module Core ( input[63:0] entry,
              /* verilator lint_off UNDRIVEN */
              /* verilator lint_off UNUSED */
              Sysbus bus
              /* verilator lint_on UNUSED */
              /* verilator lint_on UNDRIVEN */ );

    logic reset, clk;
    /* verilator lint_off UNDRIVEN */
    /* verilator lint_off UNUSED */
    Mybus mybus;
    /* verilator lint_on UNUSED */
    /* verilator lint_on UNDRIVEN */

    assign reset = bus.reset;
    assign clk = bus.clk;

    assign bus.reqcyc = mybus.reqcyc;
    assign bus.reqtag = mybus.reqtag;
    assign bus.req = mybus.req;
    assign bus.respack = mybus.respack;

    assign mybus.respcyc = bus.respcyc;
    assign mybus.resp = bus.resp;
    assign mybus.reqack = bus.reqack;

    Pipeline pipe(entry, reset, clk, mybus);

endmodule

