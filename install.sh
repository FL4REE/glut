#!/usr/bin/env bash
# glut installer: turns a fresh CachyOS (or Arch with CachyOS repos) into this
# exact desktop. Safe to re-run; existing configs are moved to a backup folder.
#
#   git clone https://github.com/FL4REE/glut ~/glut && ~/glut/install.sh
#
# Options (environment variables):
#   GLUT_SKIP_WALLPAPERS=1   don't download the wallpaper pack (~500 MB)
#   GLUT_SKIP_WHISPER=1      don't download the speech-to-text model (~550 MB)
#   GLUT_SKIP_SDDM=1         keep your current login screen
#   GLUT_PRIVATE_REPO=owner/repo   private overlay to clone and run (default: FL4REE/glut-private,
#                                  silently skipped if your gh login has no access)

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
BIN_DIR="$HOME/.local/bin"
BACKUP_DIR="$HOME/.glut-backup-$(date +%Y%m%d-%H%M%S)"
SRC_DIR="$HOME/.local/src/glut"            # third-party sources (plugins, themes)
RELEASES="https://github.com/FL4REE/glut/releases/download"
export GLUT_BACKUP_DIR="$BACKUP_DIR"

log()  { printf '\033[1;32m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$1"; }
pkgs() { grep -vE '^\s*(#|$)' "$1" | sed 's/[[:space:]]*#.*//'; }

[ "$(id -u)" -ne 0 ] || { echo "Run as your normal user, not root." >&2; exit 1; }
command -v pacman >/dev/null || { echo "pacman not found: glut needs CachyOS/Arch." >&2; exit 1; }

# --------------------------------------------------------------------------
# 1. Packages
# A full upgrade first: installing single packages on a stale system is a
# partial upgrade and can break paru (libalpm soname bump).
log "Full system upgrade"
sudo pacman -Syu --noconfirm

# paru from source: CachyOS ships its own libalpm soname, paru-bin breaks on it.
if ! command -v paru >/dev/null; then
  log "Building paru (AUR helper) from source"
  sudo pacman -S --needed --noconfirm base-devel git rustup
  rustup default stable
  tmp="$(mktemp -d)"
  git clone https://aur.archlinux.org/paru.git "$tmp/paru"
  (cd "$tmp/paru" && makepkg -si --noconfirm)
  rm -rf "$tmp"
fi

log "Installing repo packages (packages/pacman.txt)"
mapfile -t list < <(pkgs "$REPO_DIR/packages/pacman.txt")
sudo pacman -S --needed --noconfirm "${list[@]}"

log "Installing AUR packages (packages/aur.txt)"
mapfile -t list < <(pkgs "$REPO_DIR/packages/aur.txt")
paru -S --needed --noconfirm "${list[@]}"

if [ -s "$REPO_DIR/packages/flatpak.txt" ] && command -v flatpak >/dev/null; then
  log "Installing Flatpaks (packages/flatpak.txt)"
  mapfile -t list < <(pkgs "$REPO_DIR/packages/flatpak.txt")
  sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  sudo flatpak install -y --noninteractive flathub "${list[@]}" || warn "Some Flatpaks failed"
fi

# Drivers and microcode are detected for *this* machine instead of copied.
log "Detecting hardware drivers (chwd -a)"
sudo chwd -a || warn "chwd -a failed, check drivers manually (chwd --list)"

# Show asterisks while typing the sudo password
if [ ! -f /etc/sudoers.d/pwfeedback ]; then
  tmp="$(mktemp)"; echo "Defaults pwfeedback" > "$tmp"
  sudo visudo -cf "$tmp" >/dev/null && sudo install -m 0440 "$tmp" /etc/sudoers.d/pwfeedback
  rm -f "$tmp"
fi

# --------------------------------------------------------------------------
# 2. Configs: symlinked into the repo, so `git pull` updates them in place.
link() {
  local src="$1" dst="$2"
  [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ] && return 0
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    mkdir -p "$BACKUP_DIR"
    warn "Backing up $dst -> $BACKUP_DIR/"
    mv "$dst" "$BACKUP_DIR/"
  fi
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
}

log "Linking configs"
for d in hypr dms ghostty fish nvim shelly theme-switcher app pokefetch; do
  link "$REPO_DIR/config/$d" "$CONFIG_DIR/$d"
done
link "$CONFIG_DIR/dms" "$CONFIG_DIR/DankMaterialShell"   # older DMS path
link "$REPO_DIR/config/starship/starship.toml" "$CONFIG_DIR/starship.toml"
link "$REPO_DIR/home/zshrc" "$HOME/.zshrc"

# DMS stores absolute paths; rewrite them for this user.
if [ "$HOME" != "/home/erik" ]; then
  sed -i "s|/home/erik|$HOME|g" "$REPO_DIR"/config/dms/*.json
fi

log "Linking glut tools into $BIN_DIR"
mkdir -p "$BIN_DIR"
for tool in "$REPO_DIR"/bin/*; do
  ln -sf "$tool" "$BIN_DIR/$(basename "$tool")"
done
"$BIN_DIR/plugin-store" --install-desktop >/dev/null || true   # app menu entry

# --------------------------------------------------------------------------
# 3. DMS plugins
clone() {   # clone <url> <dir> [commit]
  if [ -d "$2/.git" ]; then git -C "$2" fetch -q; else git clone -q "$1" "$2"; fi
  if [ -n "${3:-}" ]; then git -C "$2" checkout -q "$3"; else git -C "$2" pull -q --ff-only || true; fi
}

log "Installing DMS plugins"
PLUGINS="$CONFIG_DIR/dms/plugins"
mkdir -p "$PLUGINS" "$SRC_DIR"
for p in "$REPO_DIR"/projects/*; do               # own plugins, from this repo
  link "$p" "$PLUGINS/$(basename "$p")"
done
# Third-party plugins: exactly the versions recorded in config/dms/plugins.lock.json
# (the Plugin Store and `dms plugins lock` keep it current).
dms plugins restore "$REPO_DIR/config/dms/plugins.lock.json" || warn "dms plugins restore failed"

# --------------------------------------------------------------------------
# 4. Themes: themectl + 136 palettes + wallpaper pack
log "Installing themectl (theme-switcher)"
clone https://github.com/FL4REE/theme-switcher "$SRC_DIR/theme-switcher"
"$SRC_DIR/theme-switcher/install.sh" || warn "theme-switcher install failed"

THEMES="$HOME/.local/share/theme-switcher/themes"
log "Installing themes into $THEMES"
mkdir -p "$THEMES"
cp -rn "$REPO_DIR"/themes/. "$THEMES"/

if [ -z "${GLUT_SKIP_WALLPAPERS:-}" ]; then
  log "Downloading wallpaper pack (~500 MB)"
  if curl -fL --progress-bar "$RELEASES/wallpapers-v1/wallpapers.tar" | tar -x -C "$THEMES"; then
    :
  else
    warn "Wallpaper download failed; re-run later or set GLUT_SKIP_WALLPAPERS=1"
  fi
fi

current=$(sed -n 's|.*"customThemeFile": *".*/ts-\([^/]*\)/theme.json".*|\1|p' "$CONFIG_DIR/dms/settings.json")
if [ -n "$current" ] && command -v themectl >/dev/null; then
  themectl apply "$current" >/dev/null 2>&1 \
    || warn "Run 'themectl apply $current' once you are logged into Hyprland"
fi

# pokefetch: Pokemon fetch in every new Fish shell. themectl picks the
# Pokemon whose sprite colors match the current theme.
log "Installing pokefetch"
clone https://github.com/Yanzz231/PokeFetch "$SRC_DIR/PokeFetch" 77e4bf5
PF_VENV="$HOME/.local/share/pokefetch/venv"
[ -d "$PF_VENV" ] || python3 -m venv "$PF_VENV"
"$PF_VENV/bin/pip" install --quiet -e "$SRC_DIR/PokeFetch" || warn "pokefetch install failed"
ln -sf "$PF_VENV/bin/pokefetch" "$BIN_DIR/pokefetch"

# --------------------------------------------------------------------------
# 5. Login screen: sddm-astronaut-theme with the Gargantua variant
if [ -z "${GLUT_SKIP_SDDM:-}" ]; then
  log "Login screen (SDDM, Gargantua)"
  T=/usr/share/sddm/themes/sddm-astronaut-theme
  [ -d "$T" ] || sudo git clone -q https://github.com/Keyitdev/sddm-astronaut-theme "$T"
  sudo pacman -S --needed --noconfirm qt6-svg qt6-virtualkeyboard qt6-multimedia-ffmpeg
  sudo mkdir -p /etc/sddm.conf.d
  printf '[Theme]\nCurrent=sddm-astronaut-theme\n' | sudo tee /etc/sddm.conf.d/theme.conf >/dev/null
  clone https://github.com/FL4REE/sddm-gargantua "$SRC_DIR/sddm-gargantua"
  "$SRC_DIR/sddm-gargantua/install.sh" >/dev/null || warn "Gargantua theme install failed"
  sudo systemctl enable sddm.service
fi

# --------------------------------------------------------------------------
# 6. Services
log "Enabling user services"
mkdir -p "$CONFIG_DIR/systemd/user"
cp "$REPO_DIR"/systemd/*.service "$REPO_DIR"/systemd/*.timer "$REPO_DIR"/systemd/*.target \
  "$CONFIG_DIR/systemd/user/"
systemctl --user daemon-reload
systemctl --user enable dms.service || warn "dms.service: starts with your first Hyprland login"
systemctl --user enable dankcalendar.service || true
# Daily snapshot of configs + packages back into the repo (commit + push).
# Only on the owner's machines; on a fork enable it yourself once your clone
# points at your own remote: systemctl --user enable --now pkgsync.timer
PRIVATE_REPO="${GLUT_PRIVATE_REPO:-FL4REE/glut-private}"
HAS_PRIVATE=0
command -v gh >/dev/null && gh repo view "$PRIVATE_REPO" >/dev/null 2>&1 && HAS_PRIVATE=1
if [ "$HAS_PRIVATE" = 1 ]; then
  systemctl --user enable --now pkgsync.timer || warn "pkgsync.timer could not be enabled"
fi

# --------------------------------------------------------------------------
# 7. Offline speech-to-text model for `diktat` (SUPER+ALT+D)
MODEL="$HOME/.local/share/whisper/ggml-large-v3-turbo-q5_0.bin"
if [ -z "${GLUT_SKIP_WHISPER:-}" ] && [ ! -f "$MODEL" ]; then
  log "Downloading Whisper model (~550 MB)"
  mkdir -p "$(dirname "$MODEL")"
  curl -fL --progress-bar -o "$MODEL.part" \
    "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo-q5_0.bin" \
    && mv "$MODEL.part" "$MODEL" \
    || warn "Whisper model download failed; diktat works once it is there"
fi

# --------------------------------------------------------------------------
# 8. Private overlay (personal stuff that is not part of the public repo)
if [ "$HAS_PRIVATE" = 1 ]; then
  log "Private overlay: $PRIVATE_REPO"
  dir="$HOME/Projekte/$(basename "$PRIVATE_REPO")"
  [ -d "$dir/.git" ] || gh repo clone "$PRIVATE_REPO" "$dir" -- -q
  "$dir/install.sh"
fi

# --------------------------------------------------------------------------
log "Done. Reboot, pick Hyprland on the login screen, and you are home."
[ -d "$BACKUP_DIR" ] && warn "Your previous configs are in $BACKUP_DIR"
exit 0
