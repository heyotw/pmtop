#!/usr/bin/env bash
# hny.sh likes to code #
set -e

# Validate OS
OS="$(uname -s)"
if [ "$OS" != "Linux" ]; then
	echo "Error: Unsupported operating system: ${OS}." >&2
	echo "pmtop only supports Linux PulsedMedia seedboxes." >&2
	exit 1
fi

# Validate User
UID_NUM="$(id -u)"
if [ "$UID_NUM" -eq 0 ]; then
	echo "Error: pmtop is designed for user-scoped monitoring on PulsedMedia seedboxes." >&2
	echo "Please run as a non-root seedbox user." >&2
	exit 1
fi

# Validate PulsedMedia Environment
PMSS_CONF="${HOME}/.config/pmss-user.json"
if [ ! -f "$PMSS_CONF" ]; then
	echo "Error: PulsedMedia user configuration not found: ${PMSS_CONF} does not exist." >&2
	echo "pmtop is only designed for PulsedMedia seedboxes." >&2
	exit 1
fi

QUOTA_FILE="${HOME}/.quota"
if [ ! -f "$QUOTA_FILE" ]; then
	echo "Error: PulsedMedia quota file not found: ${QUOTA_FILE} does not exist." >&2
	echo "pmtop requires disk quota reporting to function properly." >&2
	exit 1
fi

if ! grep -q '"ramMiB"' "$PMSS_CONF" 2>/dev/null; then
	echo "Error: Invalid PulsedMedia configuration: 'ramMiB' field missing in ${PMSS_CONF}." >&2
	exit 1
fi

if ! grep -q '"cpuQuotaPercent"' "$PMSS_CONF" 2>/dev/null; then
	echo "Error: Invalid PulsedMedia configuration: 'cpuQuotaPercent' field missing in ${PMSS_CONF}." >&2
	exit 1
fi

# Extract quota summary
RAM_MIB=$(grep -o '"ramMiB"[[:space:]]*:[[:space:]]*[0-9]*' "$PMSS_CONF" | grep -o '[0-9]*$' || echo "unknown")
CPU_PCT=$(grep -o '"cpuQuotaPercent"[[:space:]]*:[[:space:]]*"[0-9]*"' "$PMSS_CONF" | grep -o '[0-9]*' | tail -n 1 || echo "unknown")
USER_NAME="$(whoami 2>/dev/null || echo "$USER")"

echo "=================================================="
echo " Detected PulsedMedia Seedbox Environment:"
echo "   User:      ${USER_NAME} (UID: ${UID_NUM})"
echo "   RAM Quota: ${RAM_MIB} MiB"
echo "   CPU Quota: ${CPU_PCT}%"
echo "=================================================="

BINDIR="${HOME}/bin"
mkdir -p "$BINDIR"

INSTALLED=0
ARCH="$(uname -m)"

# Fast Path: Install prebuilt static binary if on x86_64
if [ "$ARCH" = "x86_64" ]; then
	RELEASE_URL="https://github.com/heyotw/pmtop/releases/download/v1.4.7-pm1/pmtop-x86_64-linux"
	echo "Fetching prebuilt static binary for x86_64..."
	TMPBIN="$(mktemp "${BINDIR}/.pmtop.XXXXXX")"
	if curl -fsSL -o "$TMPBIN" "$RELEASE_URL" 2>/dev/null && chmod +x "$TMPBIN" && "$TMPBIN" --version >/dev/null 2>&1; then
		mv -f "$TMPBIN" "${BINDIR}/pmtop"
		INSTALLED=1
		echo "Prebuilt binary verified."
	else
		rm -f "$TMPBIN"
		echo "Prebuilt binary download failed or skipped. Falling back to build from source..."
	fi
fi

# Fallback Path: Compile from source
if [ "$INSTALLED" -eq 0 ]; then
	if ! command -v make >/dev/null 2>&1; then
		echo "Error: 'make' not found. Please ensure build tools are installed." >&2
		exit 1
	fi

	if ! command -v g++ >/dev/null 2>&1 && ! command -v clang++ >/dev/null 2>&1; then
		echo "Error: C++20 compiler ('g++' or 'clang++') not found." >&2
		exit 1
	fi

	CLEANUP_BUILD=0
	if [ -f "./Makefile" ] && [ -d "./src" ]; then
		SRCDIR="$(pwd)"
	else
		SRCDIR="$(mktemp -d /tmp/pmtop-build.XXXXXX)"
		CLEANUP_BUILD=1
		echo "Fetching latest pmtop source..."
		git clone --depth 1 https://github.com/heyotw/pmtop.git "$SRCDIR"
	fi

	echo "Building pmtop from source..."
	NPROC="$(nproc 2>/dev/null || echo 2)"
	(cd "$SRCDIR" && make -j"${NPROC}" STATIC=true GPU_SUPPORT=false)

	cp -f "${SRCDIR}/bin/pmtop" "${BINDIR}/pmtop"
	chmod 755 "${BINDIR}/pmtop"

	if [ "$CLEANUP_BUILD" -eq 1 ]; then
		rm -rf "$SRCDIR"
	fi
fi

# Symlink btop -> pmtop
ln -sf pmtop "${BINDIR}/btop"

# Ensure ~/.config/pmtop exists with default config
CONFIGDIR="${HOME}/.config/pmtop"
mkdir -p "$CONFIGDIR"
if [ ! -f "${CONFIGDIR}/pmtop.conf" ]; then
	"${BINDIR}/pmtop" --default-config > "${CONFIGDIR}/pmtop.conf" 2>/dev/null || true
fi

# Ensure ~/bin is in PATH and persistent across sessions
export PATH="${BINDIR}:${PATH}"

# PulsedMedia uses ~/.bashrc.user for user environment customizations
if [ -w "${HOME}/.bashrc.user" ] || [ ! -e "${HOME}/.bashrc.user" ]; then
	if ! grep -q 'HOME/bin' "${HOME}/.bashrc.user" 2>/dev/null; then
		echo 'export PATH="$HOME/bin:$PATH"' >> "${HOME}/.bashrc.user"
	fi
fi

if [ -w "${HOME}/.bashrc" ] && ! grep -q 'HOME/bin' "${HOME}/.bashrc" 2>/dev/null; then
	echo 'export PATH="$HOME/bin:$PATH"' >> "${HOME}/.bashrc"
fi

if [ -w "${HOME}/.profile" ] && ! grep -q 'HOME/bin' "${HOME}/.profile" 2>/dev/null; then
	echo 'export PATH="$HOME/bin:$PATH"' >> "${HOME}/.profile"
fi

echo ""
echo "=================================================="
echo " pmtop installed successfully to ${BINDIR}/pmtop!"
echo " Symlinked: ${BINDIR}/btop -> pmtop"
echo " Version:   $("${BINDIR}/pmtop" --version 2>/dev/null || echo "1.4.7")"
echo "=================================================="
echo "Run 'pmtop' or 'btop' to launch."
