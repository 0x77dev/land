argparse --stop-nonopt 'n/new' 'm/model=' 's/session=' 'a/agent=' -- $argv
or return

set -l flags
set -a flags --model (set -q _flag_model; and echo $_flag_model; or echo "furnace/zai-org/GLM-5")
set -a flags --variant instant
set -a flags --thinking
set -q _flag_agent; and set -a flags --agent $_flag_agent

if set -q _flag_new
    set -e __ai_session_id
else if set -q _flag_session
    set -a flags --session $_flag_session
else if set -q __ai_session_id
    set -a flags --session $__ai_session_id --continue
end

opencode run $flags $argv
set -l run_status $status

if test $run_status -eq 0
    set -g __ai_session_id (opencode session list --format json 2>/dev/null | jq -r --arg d (pwd) '[.[] | select(.directory == $d)] | sort_by(-.updated) | first | .id // empty')
end
