#include <linux/bpf.h>
#include <linux/if_ether.h>
#include <linux/ip.h>
#include <bpf/bpf_helpers.h>
#include <linux/in.h>

struct {
    __uint(type, BPF_MAP_TYPE_HASH);
    __uint(max_entries, 256);
    __type(key, __be32);
    __type(value, __u8);
    __uint(pinning, LIBBPF_PIN_BY_NAME);
    __uint(map_flags, 0);
} blocked_ips SEC(".maps");

SEC("xdp_drop_ip")
int xdp_prog(struct xdp_md *ctx) {
    void *data = (void *)(long)ctx->data;
    void *data_end = (void *)(long)ctx->data_end;

    struct ethhdr *eth = data;
    if ((void*)(eth + 1) > data_end)
        return XDP_PASS;

    if (eth->h_proto != __constant_htons(ETH_P_IP))
        return XDP_PASS;

    struct iphdr *ip = data + sizeof(*eth);
    if ((void*)(ip + 1) > data_end)
        return XDP_PASS;

    __u32 src_ip = ip->saddr;

    bpf_printk("Checking packet from IP: %u.%u.%u.%u\n",
        ((unsigned char *)&src_ip)[0],
        ((unsigned char *)&src_ip)[1],
        ((unsigned char *)&src_ip)[2],
        ((unsigned char *)&src_ip)[3]);

    __u8 *blocked = bpf_map_lookup_elem(&blocked_ips, &src_ip);
    int blocked_val = blocked ? *blocked : -1;

    bpf_printk("IP: %d.%d.%d.%d, blocked value = %d\n",
        src_ip & 0xff,
        (src_ip >> 8) & 0xff,
        (src_ip >> 16) & 0xff,
        (src_ip >> 24) & 0xff,
        blocked_val);

    if (blocked && *blocked == 1) {
        return XDP_DROP;
    } else {
        return XDP_PASS;
    }
}

char _license[] SEC("license") = "GPL";
