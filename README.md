# Thermal Control

**Thermal alerts and more**

GNOME's [Vitals](https://github.com/corecoding/Vitals) extension displays sensor data in the top bar — but it has no alerts, no thresholds, and no way to act when your machine gets hot. The **thermal-control** fills that gap: a lightweight background monitor that watches CPU and GPU temperatures and notifies you when they cross a threshold.

---

## How It Works

1. On startup, thermal-control auto-detects your CPU and GPU sensors by scanning
   `/sys/class/hwmon/` for known chip names, in this order:

   | Type | Chip names tried | Hardware |
   |------|-----------------|----------|
   | CPU | `k10temp` → `coretemp` | AMD → Intel |
   | GPU | `amdgpu` → `i915` → `nouveau` → `nvidia` | AMD → Intel iGPU → NVIDIA open → NVIDIA proprietary |

   If a sensor isn't found, the script warns and continues with whatever it has.
   If neither CPU nor GPU is detected, it exits with an error.

2. Every `--poll` seconds, it reads the temperature from each sensor.

3. When a temperature exceeds `--threshold`, it shows a dialog with two choices:

   - **Switch to Balanced Mode** — runs `powerprofilesctl set balanced` and
     continues monitoring silently.
   - **Dismiss** — suppresses all alerts for the rest of the session.

4. After an alert, a cooldown window of `--cooldown` minutes prevents repeated
   pop-ups while the system is under sustained load.

---

## Installation Guide - Git Clone

Clone this repo:
```bash
git clone https://github.com/cofuente/thermal-control.git
cd thermal-control
```

Add locally:
```bash
cp thermal-control ~/.local/bin/thermal-control
chmod +x ~/.local/bin/thermal-control
```

Verify it's in your PATH:
```bash
which thermal-control
```

### Dependencies

- `zenity` — for interactive alert dialogs (pre-installed on GNOME/Ubuntu)
- `notify-send` — for non-blocking notifications (from `libnotify-bin`, pre-installed on GNOME/Ubuntu)
- `powerprofilesctl` — for switching power profiles (from `power-profiles-daemon`, pre-installed on Ubuntu)

---

## Usage

```bash
thermal-control [OPTIONS]
```

| Flag | Description | Default |
|------|-------------|---------|
| `-t, --threshold CELSIUS` | Temperature that triggers an alert | `85` |
| `-n, --cooldown MINUTES` | Minutes to suppress repeat alerts | `5` |
| `-p, --poll SECONDS` | How often to read sensors | `30` |
| `-s, --silent` | Silent mode — no alerts at all | off |
| `--auto-remediate` | Auto-switch to balanced profile on breach | off |
| `-h, --help` | Show help | — |

### Examples

```bash
# Run with defaults (85°C threshold, 5-minute cooldown)
thermal-control

# Lower threshold for summer, longer cooldown
thermal-control -t 80 -n 10

# Hands-free summer mode — auto-switch to balanced, no dialog
thermal-control --auto-remediate

# Silent monitoring (useful with systemd journal logging)
thermal-control -s
```

---



## Advanced Configuration

### Changing the cooldown

The `-n` flag sets how many minutes to wait before alerting again after a
threshold breach. The default is 5 minutes.

```bash
# Alert at most once every 15 minutes
thermal-control -n 15
```

If you find alerts too frequent under sustained load (compiling, ML inference),
increase this value. If you want immediate re-alerting, set it to `0`.

### Changing the threshold

The `-t` flag sets the temperature in Celsius that triggers an alert.

```bash
# More conservative — alert at 80°C
thermal-control -t 80

# Relaxed — only alert near throttling territory
thermal-control -t 95
```

**Reference thresholds** (varies by hardware):

| Range | Meaning |
|-------|---------|
| < 70°C | Normal — no action needed |
| 70–85°C | Elevated — sustained load, within spec |
| 85–95°C | Hot — consider reducing workload or improving airflow |
| > 95°C | Throttling likely — the EC will intervene |

### Auto-Remediation

When `--auto-remediate` is passed, thermal-control skips the interactive dialog and immediately runs `powerprofilesctl set balanced` on threshold breach, then sends a non-blocking desktop notification.

```bash
# Enable auto-remediation
thermal-control --auto-remediate

# Combine with a lower threshold for proactive cooling
thermal-control --auto-remediate -t 80
```

To **disable** auto-remediation, simply omit the flag — the default behavior is
to show an interactive dialog and let you choose.

> ⚠️ **Note:** Auto-remediation has a cost — if it switches to balanced during a heavy compile or inference run, performance **will** drop noticeably.
> Use this when you'd rather lose some speed than risk sustained high temps, but know your output will suffer.

### Silent Mode

Silent mode suppresses all alerts and dialogs. The process still runs and logs
sensor discovery to stdout (visible in the systemd journal if running as a
service).

```bash
thermal-control -s
```

This is useful when you only want the monitoring infrastructure running (for
future integrations) without any user-facing notifications.

---

## Run at Login (Autostart)

To have thermal-control start automatically when you log in, create a systemd user
unit:

```bash
mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/thermal-control.service << 'EOF'
[Unit]
Description=Thermal alert monitor
After=graphical-session.target

[Service]
ExecStart=%h/.local/bin/thermal-control
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
EOF
```

Enable and start it:

```bash
systemctl --user daemon-reload
systemctl --user enable --now thermal-control.service
```

### Passing custom flags

Edit the `ExecStart` line in the unit file:

```ini
ExecStart=%h/.local/bin/thermal-control -t 80 -n 10 --auto-remediate
```

Then reload:

```bash
systemctl --user daemon-reload
systemctl --user restart thermal-control.service
```

### Disabling autostart

```bash
systemctl --user disable --now thermal-control.service
```

This stops the current instance and prevents it from starting at next login.

### Restart on Failure

The unit file includes `Restart=on-failure` by default, so if the script crashes
it will restart after 10 seconds. To change the restart delay:

```ini
RestartSec=30
```

To disable restart on failure entirely:

```ini
Restart=no
```

### Checking status and logs

```bash
# Status
systemctl --user status thermal-control.service

# Recent logs
journalctl --user -u thermal-control.service --since "1 hour ago"

# Follow live
journalctl --user -u thermal-control.service -f
```

---

## Roadmap

- [ ] Temperature logging to file - with option to turn off
- [ ] Multiple threshold tiers (warn / critical / emergency)
- [ ] Fan control integration
- [ ] Custom fan curves
- [ ] Integration with fan-lights script
- [ ] Configurable sensor paths

---

## License

thermal-control is licensed under the [PolyForm Noncommercial License 1.0.0](https://polyformproject.org/licenses/noncommercial/1.0.0/).

You are free to use, modify, and share this software for any **noncommercial**
purpose. Commercial use is not permitted under this license. See the
[`LICENSE.md`](./LICENSE.md) file for the full terms.

© 2026 cofuente
