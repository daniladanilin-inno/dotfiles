#!/bin/sh
# fzf picker over tmux sessions, bound to C-s in ~/.tmux.conf.
#   enter   switch to the highlighted session
#   tab     mark / unmark (multi-select)
#   ctrl-x  kill the marked sessions
#   ctrl-a  kill every session except the one you are in
# The current session is never killed; kills ask for confirmation.

current=$(tmux display-message -p '#S')

confirm() {
	printf 'kill:\n'
	printf '%s\n' "$1" | sed 's/^/  /'
	printf 'confirm? [y/N] '
	read -r ans
	case "$ans" in
	y | Y) return 0 ;;
	*) return 1 ;;
	esac
}

# stdin: one session name per line
kill_list() {
	while IFS= read -r s; do
		[ -n "$s" ] || continue
		if [ "$s" = "$current" ]; then
			printf 'skipped current session: %s\n' "$s"
			continue
		fi
		tmux kill-session -t "=$s"
	done
}

while :; do
	out=$(tmux list-sessions -F '#S' | fzf \
		--multi \
		--prompt 'session> ' \
		--header 'enter switch | tab mark | ctrl-x kill marked | ctrl-a kill all others' \
		--preview 'tmux capturep -ep -t {}' \
		--expect=ctrl-x,ctrl-a) || exit 0

	key=$(printf '%s\n' "$out" | sed -n 1p)
	sel=$(printf '%s\n' "$out" | sed -n '2,$p')
	[ -n "$sel" ] || continue

	case "$key" in
	ctrl-a)
		targets=$(tmux list-sessions -F '#S' | grep -vxF "$current")
		if [ -z "$targets" ]; then
			printf 'no other sessions\n'
			sleep 1
			continue
		fi
		confirm "$targets" || continue
		printf '%s\n' "$targets" | kill_list
		;;
	ctrl-x)
		confirm "$sel" || continue
		printf '%s\n' "$sel" | kill_list
		;;
	*)
		tmux switch-client -t "=$(printf '%s\n' "$sel" | sed -n 1p)"
		exit 0
		;;
	esac
done
