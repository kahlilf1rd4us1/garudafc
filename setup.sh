#!/bin/bash
# ============================================================
#  GarudaFC Setup Script
#  Jalankan sekali: bash setup.sh
#  Setelah ini semua berjalan otomatis via GitHub Actions
# ============================================================

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'
BOLD='\033[1m'

echo ""
echo -e "${CYAN}${BOLD}╔══════════════════════════════════════╗${NC}"
echo -e "${CYAN}${BOLD}║     ⚽  GarudaFC Setup Wizard  ⚽     ║${NC}"
echo -e "${CYAN}${BOLD}╚══════════════════════════════════════╝${NC}"
echo ""

# ── 1. Cek git tersedia ──────────────────────────────────────
if ! command -v git &> /dev/null; then
  echo -e "${RED}✗ Git tidak ditemukan. Install dulu: sudo apt install git${NC}"
  exit 1
fi

# ── 2. Input dari user ────────────────────────────────────────
echo -e "${YELLOW}Masukkan informasi GitHub kamu:${NC}"
echo ""

read -p "  GitHub username  : " GH_USER
read -s -p "  Personal Access Token (PAT): " GH_TOKEN
echo ""
read -p "  Nama repo (sudah ada di GitHub): " GH_REPO

echo ""
echo -e "${CYAN}Menggunakan: https://github.com/${GH_USER}/${GH_REPO}${NC}"
echo ""

# ── 3. Cek repo sudah ada di GitHub ──────────────────────────
echo -e "📦 Memeriksa repo GitHub..."

CHECK_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: token ${GH_TOKEN}" \
  "https://api.github.com/repos/${GH_USER}/${GH_REPO}")

if [ "$CHECK_STATUS" = "200" ]; then
  echo -e "${GREEN}   ✓ Repo ditemukan!${NC}"
else
  echo -e "${RED}   ✗ Repo tidak ditemukan (status: $CHECK_STATUS)${NC}"
  echo -e "${YELLOW}   Pastikan repo sudah dibuat di https://github.com/new${NC}"
  exit 1
fi

# ── 4. Setup git & push ───────────────────────────────────────
echo -e "🚀 Push ke GitHub..."

REMOTE_URL="https://${GH_USER}:${GH_TOKEN}@github.com/${GH_USER}/${GH_REPO}.git"

cd "$(dirname "$0")"

# Hapus remote lama jika ada
git remote remove origin 2>/dev/null || true
git remote add origin "$REMOTE_URL"

git add -A
git diff --cached --quiet || git commit -m "🤖 Auto-setup: GarudaFC portal sepak bola"

git branch -M main
git push -u origin main --force

echo -e "${GREEN}   ✓ Push berhasil!${NC}"

# ── 5. Aktifkan GitHub Pages via API ─────────────────────────
echo -e "🌐 Mengaktifkan GitHub Pages..."

sleep 2

PG_STATUS=$(curl -s -o /tmp/pages_response.json -w "%{http_code}" \
  -X POST \
  -H "Authorization: token ${GH_TOKEN}" \
  -H "Accept: application/vnd.github.v3+json" \
  -d '{"source":{"branch":"main","path":"/"}}' \
  "https://api.github.com/repos/${GH_USER}/${GH_REPO}/pages")

if [ "$PG_STATUS" = "201" ] || [ "$PG_STATUS" = "409" ]; then
  echo -e "${GREEN}   ✓ GitHub Pages aktif!${NC}"
else
  echo -e "${YELLOW}   ⚠ Aktifkan manual: Settings → Pages → Branch: main → Save${NC}"
fi

# ── 6. Aktifkan workflow permissions via API ──────────────────
echo -e "⚙️  Mengatur workflow permissions..."

curl -s -o /dev/null \
  -X PUT \
  -H "Authorization: token ${GH_TOKEN}" \
  -H "Accept: application/vnd.github.v3+json" \
  -d '{"default_workflow_permissions":"write","can_approve_pull_request_reviews":false}' \
  "https://api.github.com/repos/${GH_USER}/${GH_REPO}/actions/permissions/workflow"

echo -e "${GREEN}   ✓ Permissions diatur!${NC}"

# ── 7. Trigger workflow pertama kali ─────────────────────────
echo -e "🔄 Menjalankan update berita pertama kali..."

sleep 3

WF_STATUS=$(curl -s -o /tmp/wf_response.json -w "%{http_code}" \
  -X POST \
  -H "Authorization: token ${GH_TOKEN}" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/${GH_USER}/${GH_REPO}/actions/workflows/update-news.yml/dispatches" \
  -d '{"ref":"main"}')

if [ "$WF_STATUS" = "204" ]; then
  echo -e "${GREEN}   ✓ Workflow pertama berhasil dijalankan!${NC}"
else
  echo -e "${YELLOW}   ⚠ Trigger manual: repo → Actions → Update Football News → Run workflow${NC}"
fi

# ── Done ──────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║              ✅  SETUP SELESAI!                  ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  🌐 Website  : ${CYAN}https://${GH_USER}.github.io/${GH_REPO}${NC}"
echo -e "  📦 Repo     : ${CYAN}https://github.com/${GH_USER}/${GH_REPO}${NC}"
echo -e "  ⚙️  Actions  : ${CYAN}https://github.com/${GH_USER}/${GH_REPO}/actions${NC}"
echo ""
echo -e "  ⏰ Berita akan diperbarui otomatis setiap ${YELLOW}30 menit${NC}"
echo -e "  📌 Website live dalam ${YELLOW}1-2 menit${NC} setelah ini"
echo ""
echo -e "${YELLOW}  Tidak perlu buka terminal lagi! 🎉${NC}"
echo ""
