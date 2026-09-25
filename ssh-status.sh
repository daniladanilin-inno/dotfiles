#!/bin/sh
# Colour each tmux session's status line by how that session is being viewed:
#   remote (a client attached to it came in over ssh) -> orange, matching the zsh prompt override
#   local  (every client attached to it is on this box) -> the default cyan
#
# Per SESSION, not per server: status-style is a session option, so a local client on session 3
# keeps its cyan bar even while a remote client is looking at session 1. It cannot be made per
# CLIENT -- two clients attached to the same session necessarily share one bar.
#
# tmux exposes no "is this client remote" format variable, so each client's process ancestry is
# walked looking for an sshd. OpenSSH >= 9.8 renames the per-connection process to sshd-session.
#
# Driven by the client-attached / client-detached / client-session-changed hooks in ~/.tmux.conf.

LOCAL_STYLE="fg=cyan,bold"
REMOTE_STYLE="fg=colour208,bold"

# 0 (true) if the given pid has an sshd anywhere in its ancestry.
is_remote_pid() {
    p=$1
    hops=0
    # Guard the walk with a hop limit: a ps that returns junk must not spin forever.
    while [ -n "$p" ] && [ "$p" -gt 1 ] && [ "$hops" -lt 32 ]; do
        # Normalise before matching: Linux prints a bare "sshd-session", but macOS prints the
        # full argv[0] -- "sshd-session: user@notty" -- and some systems print an absolute path.
        comm=$(ps -o comm= -p "$p" 2>/dev/null)
        comm=${comm#"${comm%%[![:space:]]*}"}   # drop leading whitespace
        comm=${comm%% *}                        # "sshd-session: user@notty" -> "sshd-session:"
        comm=${comm##*/}                        # "/usr/sbin/sshd"           -> "sshd"
        comm=${comm%:}                          # "sshd-session:"            -> "sshd-session"
        case $comm in
            sshd|sshd-session) return 0 ;;
        esac
        p=$(ps -o ppid= -p "$p" 2>/dev/null | tr -d ' ')
        hops=$((hops + 1))
    done
    return 1
}

tmux list-sessions -F '#{session_name}' 2>/dev/null | while IFS= read -r session; do
    # A parked session (F12) owns its own status style until it is unparked; leave it alone.
    [ "$(tmux show -t "$session" -v key-table 2>/dev/null)" = "off" ] && continue

    style=$LOCAL_STYLE
    for pid in $(tmux list-clients -t "$session" -F '#{client_pid}' 2>/dev/null); do
        if is_remote_pid "$pid"; then
            style=$REMOTE_STYLE
            break
        fi
    done
    tmux set -t "$session" status-style "$style"

    # Publish the answer as a session option so the shells inside can read it cheaply; the
    # _ssh_prompt_sync hook in .zshrc picks it up.
    [ "$style" = "$REMOTE_STYLE" ] && flag=1 || flag=0
    if [ "$(tmux show -t "$session" -v @ssh_remote 2>/dev/null)" != "$flag" ]; then
        tmux set -t "$session" @ssh_remote "$flag"

        # Nudge the panes so a prompt sitting idle repaints immediately -- otherwise closing an
        # ssh connection leaves the last drawn prompt orange until you press Enter.
        #
        # SIGWINCH, never SIGUSR2. WINCH is ignored by default, so a shell without the matching
        # trap, or any other process sitting in a pane, is completely unharmed. USR2 terminates
        # by default and killed exactly those processes when it was tried here.
        for pane_pid in $(tmux list-panes -s -t "$session" -F '#{pane_pid}' 2>/dev/null); do
            kill -WINCH "$pane_pid" 2>/dev/null
        done
    fi
done
