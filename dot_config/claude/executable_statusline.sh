#!/bin/sh
# Claude Code status line — Catppuccin Mocha / Hack Nerd Font Mono / cmux (truecolor)
input=$(cat)

# ── Catppuccin Mocha（24-bit 前景色）──
fg() { printf '\033[38;2;%d;%d;%dm' "$1" "$2" "$3"; }
C_TEAL=$(fg 148 226 213)      # #94e2d5 repo
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
ICON_REPO=$(printf '\357\220\201')   # U+F401 nf-oct-repo
ICON_USER=$(printf '\357\200\207')   # U+F007 nf-fa-user
ICON_WORK=$(printf '\357\202\261')   # U+F0B1 nf-fa-briefcase
ICON_CTX=$(printf '\357\213\233')    # U+F2DB nf-fa-microchip
ICON_CLOCK=$(printf '\357\200\227')  # U+F017 nf-fa-clock
ICON_COST=$(printf '\357\205\225')   # U+F155 nf-fa-dollar

# 帳號：依實際登入帳號的組織類型判斷（Team/Enterprise = WORK）
# 讀不到登入資訊時，退回依 CLAUDE_CONFIG_DIR 判斷
acct_file="${CLAUDE_CONFIG_DIR:+$CLAUDE_CONFIG_DIR/.claude.json}"
org_type=$(jq -r '.oauthAccount.organizationType // empty' "${acct_file:-$HOME/.claude.json}" 2>/dev/null)
case "$org_type" in
  claude_team|claude_enterprise) is_work=1 ;;
  ?*)                            is_work=0 ;;
  *) case "$CLAUDE_CONFIG_DIR" in *claude-work*) is_work=1 ;; *) is_work=0 ;; esac ;;
esac
if [ "$is_work" = 1 ]; then acct="$C_PEACH$ICON_WORK WORK$RST"
else acct="$C_BLUE$ICON_USER ME$RST"; fi

# ── 一次 jq 取全部欄位（@sh 保證 eval 安全）──
eval "$(printf '%s' "$input" | jq -r '
  @sh "repo=\(.workspace.repo.name // "")",
  @sh "cur_dir=\(.workspace.current_dir // .cwd // "")",
  @sh "model=\(.model.display_name // "")",
  @sh "ctx_remain=\(.context_window.remaining_percentage // "")",
  @sh "five_h_used=\(.rate_limits.five_hour.used_percentage // "")",
  @sh "seven_d_used=\(.rate_limits.seven_day.used_percentage // "")",
  @sh "five_h_reset=\(.rate_limits.five_hour.resets_at // "")",
  @sh "seven_d_reset=\(.rate_limits.seven_day.resets_at // "")",
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

# 倒數時間：2h13m / 45m（已過期則不輸出）
countdown() {
  s=$1; [ "$s" -gt 0 ] || return 0
  h=$((s / 3600)); m=$((s % 3600 / 60))
  if [ "$h" -gt 0 ]; then printf '%dh%02dm' "$h" "$m"; else printf '%dm' "$m"; fi
}

SEP="$C_OVERLAY0 │ $RST"
parts="$acct"

# repo 名稱：優先用 origin remote 解析出的名稱，沒有 origin 時退回 git 根目錄名稱
if [ -z "$repo" ] && [ -n "$cur_dir" ]; then
  top=$(git -C "$cur_dir" rev-parse --show-toplevel 2>/dev/null) && repo=${top##*/}
fi
[ -n "$repo" ] && parts="$C_TEAL$ICON_REPO $repo$RST$SEP$parts"

[ -n "$model" ] && parts="$parts $BOLD$C_MAUVE$model$RST"

if [ -n "$ctx_remain" ]; then
  val=$(printf '%.0f' "$ctx_remain")
  c=$(color_by_remain "$val")
  parts="$parts$SEP$c$ICON_CTX $(mini_bar "$val")$c $val%$RST"
fi

# 重置時間：5h 顯示倒數（2h13m），7d 顯示星期與 24h 時間（Wed 12:00）
now=$(date +%s)
for w in 5h 7d; do
  if [ "$w" = 5h ]; then used=$five_h_used; reset=$five_h_reset
  else used=$seven_d_used; reset=$seven_d_reset; fi
  [ -n "$used" ] || continue
  val=$(printf '%.0f' "$used")   # 顯示已用量；顏色仍依剩餘量判斷
  when=""
  if [ -n "$reset" ]; then
    reset=$(printf '%.0f' "$reset")
    if [ "$w" = 5h ]; then when=$(countdown $((reset - now)))
    else when=$(LC_ALL=C date -r "$reset" '+%a %H:%M' 2>/dev/null); fi
  fi
  parts="$parts$SEP$(color_by_remain $((100 - val)))$ICON_CLOCK $w:$val%${when:+ $when}$RST"
done

if [ -n "$cost" ]; then
  cost_fmt=$(printf '%.2f' "$cost")
  [ "$cost_fmt" != "0.00" ] && parts="$parts$SEP$C_OVERLAY1$ICON_COST $cost_fmt$RST"
fi

printf '%s' "$parts"
