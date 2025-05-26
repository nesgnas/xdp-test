# DoS Defense Benchmark: iptables vs XDP

This project benchmarks **CPU usage** under a simulated DoS attack using `hping3`, comparing traditional `iptables` packet dropping against a custom **eXpress Data Path (XDP)** solution.

---

## 🔧 Requirements

- Ubuntu/Debian-based system
- Root privilege
- Tools installed:
  - `hping3`
  - `iptables`
  - `gnuplot`
  - `go` (for running XDP interface)
  - `moreutils` (optional, for `spark` CLI charts)

---

## 🧪 Test Setup

- **Attacker machine (A)**: `141.98.199.82`
- **Target machine (B)**: `167.253.159.197`  
  (this machine runs the benchmark scripts and the XDP dropper)

---

## ⚙️ Usage Instructions

### 1. Clean Slate: Remove previous iptables rule

```bash
sudo iptables -D INPUT -s 141.98.199.82 -j DROP || true
```

---

### 2. Benchmark with `iptables`

#### Step 1: Add iptables DROP rule

```bash
sudo iptables -A INPUT -s 141.98.199.82 -j DROP
```

#### Step 2: Start CPU monitoring (60s)

```bash
nohup ./monitor_cpu.sh &
```

> This logs CPU usage every second to `cpu_usage.csv` for 60 seconds.

#### Step 3: Run DoS attack from machine A

```bash
sudo timeout 10s hping3 --flood -S -p 80 167.253.159.197
```

#### Step 4: Generate CPU usage graph

```bash
gnuplot plot_cpu.gnuplot
```

This renders a diagram from `cpu_usage.csv`.

---

### 3. Benchmark with `XDP`

#### Step 1: Remove iptables rule

```bash
sudo iptables -D INPUT -s 141.98.199.82 -j DROP
```

#### Step 2: Start XDP dropper

```bash
go run main.go
```

Then in the CLI:

```bash
add 141.98.199.82
```

> This instructs the XDP program to drop packets from the attacker IP.

#### Step 3: Start CPU monitoring (again)

```bash
nohup ./monitor_cpu.sh &
```

#### Step 4: Run DoS attack again from machine A

```bash
sudo timeout 10s hping3 --flood -S -p 80 167.253.159.197
```

#### Step 5: Generate CPU usage graph again

```bash
gnuplot plot_cpu.gnuplot
```

---

## 📊 Output Example

Using [gnuplot](http://www.gnuplot.info/), you can visualize and compare the CPU usage before and after enabling XDP.

If installed, you can also use spark CLI to get a quick chart:

```bash
cat cpu_usage.csv | tail -n +2 | cut -d',' -f2 | spark
```

---

## 📁 File Structure

```text
.
├── main.go                # XDP user-space control program
├── monitor_cpu.sh         # CPU usage logger script
├── cpu_usage.csv          # Output CSV from monitor
├── plot_cpu.gnuplot       # gnuplot script for plotting CPU diagram
└── README.md              # This file
```

---

## ✅ Expected Outcome

You should observe:

- **Higher CPU usage** with only `iptables`
- **Lower CPU usage** with **XDP**, due to early packet drop at driver level

This demonstrates the performance benefits of using XDP for high-performance packet filtering.

---

## 📌 Notes

- This benchmark focuses purely on CPU usage — for deeper insights, you can also extend it to monitor memory, dropped packets, or throughput using tools like `bpftrace`, `netstat`, or `ifstat`.
- Make sure kernel and driver support `XDP` (most modern distributions do).

---

## 👨‍💻 Author

Built for academic benchmarking and thesis experiments on **high-performance packet processing with XDP/eBPF**.
