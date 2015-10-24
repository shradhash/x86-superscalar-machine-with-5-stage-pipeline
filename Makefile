include PACKAGES.mk

.PHONY: run clean submit

RUNELF=$(PWD)/prog5

TRACE=--trace

LIBPATH=/usr/include:/usr/local/share/verilator/include/:/home/shradha/verilator-3.868/include
INCPATH=/usr/include:/usr/local/share/verilator/include/:/home/shradha/verilator-3.868/include

VFILES=$(wildcard *.sv)
CFILES=$(wildcard *.cpp)

obj_dir/Vtop: obj_dir/Vtop.mk
	$(MAKE) -j2 -C obj_dir/ -f Vtop.mk CXX="ccache g++"

obj_dir/Vtop.mk: $(VFILES) $(CFILES)
	verilator -Wall -Wno-LITENDIAN -O3 $(TRACE) --no-skip-identical --cc $(PACKAGES) top.sv --top-module top --exe $(CFILES) ../dramsim2/libdramsim.so -CFLAGS -I$(INCPATH) -LDFLAGS -Wl,-rpath=../dramsim2/ -LDFLAGS -L$(LIBPATH) -LDFLAGS -lncurses

run: obj_dir/Vtop
	cd obj_dir/ && ./Vtop $(RUNELF)

clean:
	rm -rf obj_dir/

