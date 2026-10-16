<!-- hny.sh likes to code -->
# pmtop

**pmtop** is a lightweight fork of [btop](https://github.com/aristocratos/btop) tailored specifically for user-based cgroup and resource quota control on [PulsedMedia](https://pulsedmedia.com/) seedboxes.

In multi-tenant seedbox environments, standard monitoring tools report the entire host's CPU core count (e.g. 64 cores), host RAM (e.g. 64 GiB), and whole filesystem capacity, instead of what your account is actually allocated. **pmtop** restricts resource collection to your user account and accurately reflects your plan limits.

---

## Features

- **Accurate User Memory Limits**: Reads allocated memory from `~/.config/pmss-user.json` (`ramMiB`) and user cgroup memory statistics.
- **Quota-Aware CPU Allocation**: Scales core count and CPU utilization to your assigned CPU quota (e.g. 200% = 2 cores quota).
- **Disk Quota Tracking**: Displays your actual account disk usage and limits from `~/.quota` as your primary `/home` drive.
- **User-Filtered Processes**: Shows only processes owned by your UID, preventing noise from background host services and other users.
- **Service Name Demuxing**: Automatically maps generic `dotnet` / `mono` processes to their actual seedbox services (`jellyfin`, `radarr`, `sonarr`, `prowlarr`, `qbittorrent`, `rtorrent`, `deluge`).
- **Drop-In Compatibility**: Provides both `pmtop` and a `btop` symlink.

---

## Quick Install (PulsedMedia Seedbox)

Run this one-line installer in your seedbox SSH terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/heyotw/pmtop/main/install.sh | bash
```

The installer verifies your PulsedMedia environment, compiles the binary, installs it to `~/bin/pmtop` (with symlink `~/bin/btop`), and ensures `~/bin` is in your `$PATH`.

---

## Manual Build & Installation

```bash
git clone --depth 1 https://github.com/heyotw/pmtop.git
cd pmtop
make -j$(nproc) STATIC=true GPU_SUPPORT=false
make install PREFIX=~
```

---

## Usage

Simply run:

```bash
pmtop
```

Or use the familiar shortcut:

```bash
btop
```

### Options

```
pmtop [OPTIONS]

  -c, --config <file>     Path to a config file
  -d, --debug             Start in debug mode with additional logs and metrics
  -f, --filter <filter>   Set an initial process filter
  -p, --preset <id>       Start with a preset (0-9)
  -t, --tty               Force tty mode with ANSI graph symbols
  -u, --update <ms>       Set an initial update rate in milliseconds
  -h, --help              Show help message and exit
  -V, --version           Show version
```

---

## Configuration

Config files are stored in `~/.config/pmtop/pmtop.conf` (with fallback to `~/.config/btop/btop.conf`).

To disable user mode and view host-wide metrics, set in your config:
```ini
user_mode = False
```

---

## License

GNU General Public License v3.0 (same as upstream btop).
Original btop created by [Aristocratos (Jakob P. Liljenberg)](https://github.com/aristocratos/btop).
