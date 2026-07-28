set -l subcommand run

if test (count $argv) -gt 0
    switch $argv[1]
        case -h --help help new chat history text models
            set subcommand $argv[1]
            set -e argv[1]
    end
end

if contains -- $subcommand -h --help help
    printf '%s\n' \
        'Usage: ai [prompt...]' \
        '       ai new [prompt...]' \
        '       ai chat [prompt...]' \
        '       ai history' \
        '       ai text [prompt...]' \
        '       ai models [query]' \
        '' \
        'A context-aware Pi coding assistant with composable stdin and stdout.' \
        '' \
        'Commands:' \
        '  new      Start a new saved conversation' \
        '  chat     Continue the current project conversation interactively' \
        '  history  Select a saved conversation to resume' \
        '  text     Generate stateless text without tools' \
        '  models   List available Pi models' \
        '' \
        'All other options are passed directly to Pi.'
    return
end

set -l context_root (command git -C (pwd) rev-parse --show-toplevel 2>/dev/null)
or set context_root (pwd -P)

if not set -q __ai_context_root; or test "$__ai_context_root" != "$context_root"
    command lean-ctx index status >/dev/null 2>&1
    or command lean-ctx bootstrap --json >/dev/null 2>&1
    or return

    command lean-ctx index build "$context_root" >/dev/null 2>&1 &
    disown $last_pid
    command lean-ctx session load >/dev/null 2>&1
    set -g __ai_context_root $context_root
end

switch $subcommand
    case new
        if test (count $argv) -eq 0; and isatty stdin; and isatty stdout
            command pi
        else
            command pi --print $argv
        end
    case chat
        command pi --continue $argv
    case history
        command pi --resume $argv
    case text
        command pi --print --no-session --no-tools $argv
    case models
        command pi --list-models $argv
    case run
        if test (count $argv) -eq 0; and isatty stdin; and isatty stdout
            command pi --continue
        else
            command pi --print --continue $argv
        end
end
set -l run_status $status

if test $run_status -eq 0
    command lean-ctx session save >/dev/null 2>&1
end

return $run_status
