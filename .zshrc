# NOTE: ========================================== EXPORTS ==========================================
[[ $- == *i* ]] || return
export ZSH="$HOME/.oh-my-zsh"
export ZSH_THEME="kali-like"

export DISABLE_UNTRACKED_FILES_DIRTY="true"

# NOTE: ========================================== PLUGINS ==========================================

plugins=(git)

# NOTE: ========================================== SOURCES ==========================================

if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
fi

# NOTE: ========================================== PROMPT ==========================================
autoload -Uz add-zsh-hook
typeset -g _SSH_PROMPT_STATE=-1

_ssh_prompt_sync() {
    local remote=0
    if [[ -n ${TMUX:-} ]]; then
        [[ "$(tmux display-message -p '#{@ssh_remote}' 2>/dev/null)" == 1 ]] && remote=1
    elif [[ -n ${SSH_CONNECTION:-}${SSH_CLIENT:-}${SSH_TTY:-} ]]; then
        remote=1
    fi
    [[ $remote == $_SSH_PROMPT_STATE ]] && return
    _SSH_PROMPT_STATE=$remote

    if [[ -n ${TMUX:-} ]]; then
        local _v _line
        if (( remote )); then
            for _v in SSH_CONNECTION SSH_CLIENT SSH_TTY; do
                _line=$(tmux show-environment "$_v" 2>/dev/null)
                [[ $_line == "$_v="* ]] && export "$_v=${_line#$_v=}"
            done
        else
            unset SSH_CONNECTION SSH_CLIENT SSH_TTY
        fi
    fi
    if (( remote )); then
        FGPROMPT_USER=208       # user@host  and  the > symbol
        FGPROMPT_ROOT=208
        FRAMEPROMPT_USER=208    # ┌─ ─ └─ ( ) -[ ] frame
        FRAMEPROMPT_ROOT=208
    else
        FGPROMPT_USER=196
        FGPROMPT_ROOT=196
        FRAMEPROMPT_USER=196
        FRAMEPROMPT_ROOT=196
    fi
    configure_prompt
}
add-zsh-hook precmd _ssh_prompt_sync

TRAPWINCH() { _ssh_prompt_sync; zle && zle reset-prompt }

TRAPUSR2() { _ssh_prompt_sync; zle && zle reset-prompt }

# NOTE: ========================================== ALIASES ==========================================

if (( $+commands[eza] )); then
  alias l='eza -lh --icons=auto'
  alias ld='eza -lhD --icons=auto'
  alias ll='eza -lha --icons=auto --sort=name --color=always --group-directories-first'
  alias ls='eza --color=auto'
  alias lsa='eza -lah'
  alias lt='eza --icons=auto --tree'
else
  alias l='ls -lh'
  alias ld='ls -ld */'
  alias ll='ls -lah'
  alias lsa='ls -lah'
  alias lt='find . -print'
fi
alias la='ls -lAh'

v() {
  _load_nvm
  command nvim "$@"
}

(( $+commands[mcat] )) && alias cat='mcat'
alias cc="clear"
alias vim=nvim


# NOTE: ========================================== COLORS ==========================================

if (( $+commands[dircolors] )); then
    eval "$(dircolors -b ${${(f)"$([[ -r ~/.dircolors ]] && echo ~/.dircolors)"}} 2>/dev/null)"
elif (( $+commands[gdircolors] )); then
    eval "$(gdircolors -b 2>/dev/null)"
fi

LS_COLORS="${LS_COLORS:+$LS_COLORS:}\
rs=0:\
di=1;38;5;39:\
ln=1;38;5;51:\
mh=00:\
pi=40;38;5;220:\
so=1;38;5;207:\
do=1;38;5;207:\
bd=40;38;5;220;01:\
cd=40;38;5;220;01:\
or=48;5;196;38;5;231;01:\
mi=48;5;196;38;5;231;01:\
su=38;5;231;48;5;196:\
sg=38;5;16;48;5;220:\
ca=00:\
tw=38;5;16;48;5;154:\
ow=1;38;5;39;48;5;235:\
st=38;5;231;48;5;39:\
ex=1;38;5;154:\
*.tar=1;38;5;196:*.tgz=1;38;5;196:*.zip=1;38;5;196:*.gz=1;38;5;196:*.bz2=1;38;5;196:\
*.xz=1;38;5;196:*.zst=1;38;5;196:*.7z=1;38;5;196:*.rar=1;38;5;196:*.deb=1;38;5;196:*.rpm=1;38;5;196:\
*.jpg=1;38;5;207:*.jpeg=1;38;5;207:*.png=1;38;5;207:*.gif=1;38;5;207:*.webp=1;38;5;207:*.svg=1;38;5;207:\
*.mp4=1;38;5;141:*.mkv=1;38;5;141:*.mov=1;38;5;141:*.mp3=1;38;5;141:*.flac=1;38;5;141:*.wav=1;38;5;141:\
*.md=1;38;5;220:*.txt=38;5;250:*.pdf=1;38;5;220:\
*.json=38;5;178:*.yaml=38;5;178:*.yml=38;5;178:*.toml=38;5;178:*.ini=38;5;178:*.conf=38;5;178:\
*.go=38;5;81:*.rs=38;5;209:*.py=38;5;114:*.ts=38;5;75:*.js=38;5;185:*.sh=1;38;5;154:*.zsh=1;38;5;154:\
*.sql=38;5;176:Dockerfile=38;5;81:Makefile=38;5;81:\
"

for _ext in old orig bak swp swo tmp dpkg-old dpkg-new rpmnew rpmorig rpmsave pacsave pacnew; do
    LS_COLORS="$LS_COLORS*.$_ext=02;03;38;5;243:"
done
unset _ext
export LS_COLORS

export EZA_COLORS="\
ur=38;5;154:uw=38;5;196:ux=38;5;154:ue=38;5;154:\
gr=38;5;154:gw=38;5;196:gx=38;5;154:\
tr=38;5;154:tw=38;5;196:tx=38;5;154:\
su=38;5;220:sf=38;5;220:xa=38;5;240:\
sn=38;5;154:sb=38;5;154:\
uu=1;38;5;39:un=38;5;244:gu=38;5;39:gn=38;5;244:\
da=38;5;244:hd=1;4;38;5;196:\
gm=38;5;220:ga=38;5;154:gd=38;5;196:gv=38;5;207:\
"

zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'

export LESS_TERMCAP_mb=$'\e[1;38;5;196m'   # begin blink
export LESS_TERMCAP_md=$'\e[1;38;5;51m'    # begin bold        (headings)
export LESS_TERMCAP_me=$'\e[0m'            # reset bold/blink
export LESS_TERMCAP_so=$'\e[1;38;5;16;48;5;220m'  # begin standout (search / status bar)
export LESS_TERMCAP_se=$'\e[0m'            # reset standout
export LESS_TERMCAP_us=$'\e[1;4;38;5;154m' # begin underline    (options, args)
export LESS_TERMCAP_ue=$'\e[0m'            # reset underline
export GROFF_NO_SGR=1                      # make groff emit the escapes less can color

# NOTE: ========================================== FUNCS ==========================================

pullall(){
    git branch -r \
      | grep -v '\->' \
      | sed "s,\x1B\[[0-9;]*[a-zA-Z],,g" \
      | while read remote; do \
          git branch --track "${remote#origin/}" "$remote"; \
        done
    git fetch --all
    git pull --all
}

# NOTE: ========================================== KEYBINDS ==========================================
bindkey -e

# Ctrl-h  ->  move cursor one char LEFT.
#             Overrides default `backward-delete-char`; Backspace (^?) still deletes.
bindkey '^H' backward-char

# Ctrl-l  ->  move cursor one char RIGHT.
#             Overrides default `clear-screen`; use the `cc` alias (or `clear`) to clear.
bindkey '^L' forward-char

# Opt-h   ->  jump one WORD left  (Ghostty sends ESC+h = ^[h when macos-option-as-alt is on).
bindkey '^[h' backward-word

# Opt-l   ->  jump one WORD right (Ghostty sends ESC+l = ^[l).
#             Side effect: shadows the default `down-case-word`.
bindkey '^[l' forward-word

# NOTE: Cmd-d and Cmd-b don't need bindkey entries here — Ghostty rewrites them to Ctrl-D / Ctrl-W,
#       which zsh's emacs map already handles:
#         Ctrl-D -> delete-char-or-list (delete forward, EOF on empty line)
#         Ctrl-W -> backward-kill-word  (delete previous word)

# NOTE: ========================================== THROTTLE HELPER ==========================================
zmodload zsh/datetime 2>/dev/null
_throttle() {
  local now=$EPOCHREALTIME last=${(P)1:-0}
  (( now - last >= $2 )) || return 1
  typeset -g $1=$now
  return 0
}

# NOTE: ========================================== TERM RESET ==========================================
_reset_term_modes() {
  _throttle _RTM_LAST 0.1 || return
  printf '\e[?1000l\e[?1002l\e[?1003l\e[?1005l\e[?1006l\e[?1015l\e[?25h'
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd _reset_term_modes

# NOTE: ========================================== CTRL-C REDRAW ==========================================
TRAPINT() {
  zle && _throttle _SIGINT_LAST 0.15 && zle reset-prompt
  return $(( 128 + $1 ))   # preserve the conventional 130 exit status for an interrupt
}

# NOTE: ========================================== TMUX ==========================================
if [[ -z ${TMUX:-} ]] && (( $+commands[tmux_sessions] )); then
  tmux_sessions a 1
fi

# NOTE: ========================================== NVM (lazy) ==========================================
# Real nvm.sh is only sourced on first call to nvm/node/npm/npx/yarn/pnpm.
_load_nvm() {
  unset -f nvm node npm npx yarn pnpm 2>/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
}
nvm()  { _load_nvm; nvm  "$@"; }
node() { _load_nvm; node "$@"; }
npm()  { _load_nvm; npm  "$@"; }
npx()  { _load_nvm; npx  "$@"; }
yarn() { _load_nvm; yarn "$@"; }
pnpm() { _load_nvm; pnpm "$@"; }

# NOTE: ========================================== BUN ==========================================
[[ -s "$BUN_INSTALL/_bun" ]] && source "$BUN_INSTALL/_bun"

# NOTE: ========================================== SDKMAN (lazy) ==========================================
_load_sdkman() {
  unset -f sdk java javac gradle mvn kotlin kotlinc scala 2>/dev/null
  [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
}
sdk()     { _load_sdkman; sdk     "$@"; }
java()    { _load_sdkman; java    "$@"; }
javac()   { _load_sdkman; javac   "$@"; }
gradle()  { _load_sdkman; gradle  "$@"; }
mvn()     { _load_sdkman; mvn     "$@"; }
kotlin()  { _load_sdkman; kotlin  "$@"; }
kotlinc() { _load_sdkman; kotlinc "$@"; }
scala()   { _load_sdkman; scala   "$@"; }

# NOTE: ========================================== BREW ==========================================
# Linuxbrew on Linux, /opt/homebrew on Apple Silicon, /usr/local on Intel macs.
for _brew in /home/linuxbrew/.linuxbrew/bin/brew /opt/homebrew/bin/brew /usr/local/bin/brew; do
  [[ -x "$_brew" ]] && { eval "$("$_brew" shellenv)"; break; }
done
unset _brew

