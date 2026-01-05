#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: start-labs <box_name> <ip> [--force]"
  echo "Example: start-labs request-baskets 10.129.229.26"
  exit 1
}

force=0
args=()
for a in "$@"; do
  case "$a" in
    --force) force=1 ;;
    -h|--help) usage ;;
    *) args+=("$a") ;;
  esac
done

BOX="${args[0]:-}"
IP="${args[1]:-}"

[[ -z "$BOX" ]] && read -r -p "Box name: " BOX
[[ -z "$IP"  ]] && read -r -p "IP address: " IP

BOX_DIR="$(echo "$BOX" | tr ' ' '_' | tr -cd '[:alnum:]_-')"
BASE="$HOME/Labs/Boxes/$BOX_DIR"

if [[ -e "$BASE" && "$force" -ne 1 ]]; then
  echo "Folder already exists: $BASE"
  echo "Re-run with --force to reuse it."
  exit 2
fi

mkdir -p "$BASE"/{loot,scans,screenshots,notes}

# env file you can source in your shell
cat > "$BASE/target.env" <<ENV
export BOX="$BOX_DIR"
export IP="$IP"
export OUT="$BASE"
ENV

touch "$BASE/notes/notes.md"

SCANS="$BASE/scans"
ALL_OUT="$SCANS/nmap_all_tcp"
TGT_OUT="$SCANS/nmap_targeted"
PORTS_TXT="$SCANS/open_tcp_ports.txt"
SUMMARY_TXT="$SCANS/summary.txt"

echo "[*] Created lab folder: $BASE"
echo "[*] Scans folder:       $SCANS"

if ! command -v nmap >/dev/null 2>&1; then
  echo "[!] nmap not found; skipping scans."
  exit 0
fi

echo "[*] Running full TCP scan (all ports)..."
if sudo -n true 2>/dev/null; then
  sudo nmap -p- -sS --min-rate 1000 -T4 "$IP" -oA "$ALL_OUT" || true
else
  nmap -p- -sT --min-rate 1000 -T4 "$IP" -oA "$ALL_OUT" || true
fi

# Extract open ports from the grepable output
ports_csv="$(awk -F'[/ ]+' '/\/tcp[[:space:]]+open/ {print $1}' "${ALL_OUT}.gnmap" | paste -sd, - || true)"

: > "$PORTS_TXT"
if [[ -n "${ports_csv}" ]]; then
  # one port per line (useful for tools/loops)
  echo "$ports_csv" | tr ',' '\n' | sort -n > "$PORTS_TXT"
  echo "[*] Open TCP ports saved: $PORTS_TXT"
  echo "[*] Running targeted service scan..."
  if sudo -n true 2>/dev/null; then
    sudo nmap -p "$ports_csv" -sC -sV "$IP" -oA "$TGT_OUT" || true
  else
    nmap -p "$ports_csv" -sC -sV "$IP" -oA "$TGT_OUT" || true
  fi
else
  echo "[!] No open TCP ports parsed from ${ALL_OUT}.gnmap"
fi

# Human-friendly summary in scans/
{
  echo "Box: $BOX_DIR"
  echo "IP:  $IP"
  echo
  echo "Open TCP ports:"
  if [[ -s "$PORTS_TXT" ]]; then
    sed 's/^/  - /' "$PORTS_TXT"
  else
    echo "  (none found / scan failed)"
  fi
  echo
  echo "Scan artifacts:"
  echo "  - ${ALL_OUT}.nmap / .gnmap / .xml"
  echo "  - ${TGT_OUT}.nmap / .gnmap / .xml"
} > "$SUMMARY_TXT"

echo "[*] Summary written: $SUMMARY_TXT"
echo
echo "[*] Next:"
echo "    source \"$BASE/target.env\""
echo "    cd \"$BASE\""
