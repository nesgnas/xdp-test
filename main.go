package main

import (
    "bufio"
    "encoding/binary"
    "fmt"
    "log"
    "net"
    "os"
    "strings"

    "github.com/cilium/ebpf"
)

// Chuyển IP string sang uint32 theo định dạng big endian (network byte order)
func ipToLE32(ip string) (uint32, error) {
    parsed := net.ParseIP(ip)
    if parsed == nil {
        return 0, fmt.Errorf("Invalid IP")
    }
    ipv4 := parsed.To4()
    if ipv4 == nil {
        return 0, fmt.Errorf("Not IPv4")
    }
    return binary.LittleEndian.Uint32(ipv4), nil
}

// Chuyển uint32 sang IP string
func le32ToIP(ip uint32) net.IP {
    b := make([]byte, 4)
    binary.LittleEndian.PutUint32(b, ip)
    return net.IP(b)
}

func main() {
    // Đường dẫn đến pinned map eBPF
    mapPath := "/sys/fs/bpf/blocked_ips"

    // Load map eBPF đã pin
    blockedIPsMap, err := ebpf.LoadPinnedMap(mapPath, nil)
    if err != nil {
        log.Fatalf("Failed to load pinned map: %v", err)
    }
    defer blockedIPsMap.Close()

    fmt.Println("Nhập lệnh: add <ip> | del <ip> | list | exit")

    scanner := bufio.NewScanner(os.Stdin)
    for {
        fmt.Print("> ")
        if !scanner.Scan() {
            break
        }
        line := strings.TrimSpace(scanner.Text())
        if line == "" {
            continue
        }
        parts := strings.Fields(line)
        if len(parts) == 0 {
            continue
        }
        cmd := strings.ToLower(parts[0])
        fmt.Printf("DEBUG: line=%q, cmd=%q\n", line, cmd)

        switch cmd {
        case "exit":
            return

        case "add":
            if len(parts) < 2 {
                fmt.Println("Thiếu IP để thêm")
                continue
            }
            ipKey, err := ipToLE32(parts[1])
            if err != nil {
                fmt.Println("IP không hợp lệ:", err)
                continue
            }
            val := uint8(1)
            err = blockedIPsMap.Put(ipKey, val)
            if err != nil {
                fmt.Println("Thêm IP thất bại:", err)
            } else {
                fmt.Printf("Đã chặn IP %s\n", parts[1])
            }

        case "del":
            if len(parts) < 2 {
                fmt.Println("Thiếu IP để xóa")
                continue
            }
            ipKey, err := ipToLE32(parts[1])
            if err != nil {
                fmt.Println("IP không hợp lệ:", err)
                continue
            }
            err = blockedIPsMap.Delete(ipKey)
            if err != nil {
                fmt.Println("Xóa IP thất bại:", err)
            } else {
                fmt.Printf("Đã bỏ chặn IP %s\n", parts[1])
            }

        case "list":
            iter := blockedIPsMap.Iterate()
            var ip uint32
            var val uint8
            fmt.Println("Danh sách IP bị chặn:")
            for iter.Next(&ip, &val) {
                fmt.Println(" -", le32ToIP(ip).String())
            }
            if err := iter.Err(); err != nil {
                fmt.Println("Lỗi đọc map:", err)
            }

        default:
            fmt.Println("Lệnh không hợp lệ. Dùng add/del/list/exit")
        }
    }
}

