CLANG ?= clang
LLC ?= llc
BPFTOOL ?= bpftool

BPF_PROG = xdp_drop_ip_kern.o

all: $(BPF_PROG)

%.o: %.c
	$(CLANG) -O2 -g -target bpf -D__TARGET_ARCH_x86 -c $< -o $@

clean:
	rm -f *.o *.ll

