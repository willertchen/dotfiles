#!/bin/sh
# Claude Code status line — Catppuccin Mocha / Hack Nerd Font Mono / cmux (truecolor)
input=$(cat)

# ── Catppuccin Mocha（24-bit 前景色）──
fg() { printf '\033[38;2;%d;%d;%dm' "$1" "$2" "$3"; }
C_MAUVE=$(fg 203 166 247)     # #cba6f7 model
C_BLUE=$(fg 137 180 250)      # #89b4fa 個人帳號
C_PEACH=$(fg 250 179 135)     # #fab387 公司帳號
C_GREEN=$(fg 166 227 161)     # #a6e3a1 ≥50%
C_YELLOW=$(fg 249 226 175)    # #f9e2af 21–49%
C_RED=$(fg 243 139 168)       # #f38ba8 ≤20%
C_SURFACE2=$(fg 88 91 112)    # #585b70 進度條空格
C_OVERLAY0=$(fg 108 112 134)  # #6c7086 分隔線
C_OVERLAY1=$(fg 127 132 156)  # #7f849c 花費
BOLD=$(printf '\033[1m')
RST=$(printf '\033[0m')

# ── Nerd Font 圖示（UTF-8 八進位位元組；/bin/sh = bash 3.2 不支援 \u）──
ICON_USER=$(printf '\357\200\207')   # U+F007 nf-fa-user
ICON_WORK=$(printf '\357\202\261')   # U+F0B1 nf-fa-briefcase
ICON_CTX=$(printf '\357\213\233')    # U+F2DB nf-fa-microchip
ICON_CLOCK=$(printf '\357\200\227')  # U+F017 nf-fa-clock
ICON_COST=$(printf '\357\205\225')   # U+F155 nf-fa-dollar

case "$CLAUDE_CONFIG_DIR" in
  *claude-work*) acct="$C_PEACH$ICON_WORK WORK$RST" ;;
  *)             acct="$C_BLUE$ICON_USER ME$RST" ;;
esac

# ── 一次 jq 取全部欄位（@sh 保證 eval 安全）──
eval "$(printf '%s' "$input" | jq -r '
  @sh "model=\(.model.display_name // "")",
  @sh "ctx_remain=\(.context_window.remaining_percentage // "")",
  @sh "five_h_used=\(.rate_limits.five_hour.used_percentage // "")",
  @sh "seven_d_used=\(.rate_limits.seven_day.used_percentage // "")",
  @sh "cost=\(.cost.total_cost_usd // "")"
' 2>/dev/null)"

color_by_remain() {
  if [ "$1" -le 20 ]; then printf '%s' "$C_RED"
  elif [ "$1" -le 49 ]; then printf '%s' "$C_YELLOW"
  else printf '%s' "$C_GREEN"; fi
}

# 10 格進度條：已填用門檻色，空格用 surface2
mini_bar() {
  p=$1; [ "$p" -gt 100 ] && p=100; [ "$p" -lt 0 ] && p=0
  filled=$((p * 10 / 100)); i=0
  while [ $i -lt $filled ]; do printf '━'; i=$((i + 1)); done
  printf '%s' "$C_SURFACE2"
  while [ $i -lt 10 ]; do printf '━'; i=$((i + 1)); done
}

SEP="$C_OVERLAY0 │ $RST"
parts="$acct"

[ -n "$model" ] && parts="$parts $BOLD$C_MAUVE$model$RST"

if [ -n "$ctx_remain" ]; then
  val=$(printf '%.0f' "$ctx_remain")
  c=$(color_by_remain "$val")
  parts="$parts$SEP$c$ICON_CTX $(mini_bar "$val")$c $val%$RST"
fi

for w in 5h 7d; do
  if [ "$w" = 5h ]; then used=$five_h_used; else used=$seven_d_used; fi
  [ -n "$used" ] || continue
  val=$((100 - $(printf '%.0f' "$used")))
  parts="$parts$SEP$(color_by_remain "$val")$ICON_CLOCK $w:$val%$RST"
done

if [ -n "$cost" ]; then
  cost_fmt=$(printf '%.2f' "$cost")
  [ "$cost_fmt" != "0.00" ] && parts="$parts$SEP$C_OVERLAY1$ICON_COST $cost_fmt$RST"
fi

printf '%s' "$parts"
