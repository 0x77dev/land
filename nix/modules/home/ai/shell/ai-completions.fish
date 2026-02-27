complete -c ai -f
complete -c ai -s n -l new -d "Start new session"
complete -c ai -s m -l model -d "Specify model (provider/model)" -r
complete -c ai -s s -l session -d "Continue specific session" -r
complete -c ai -s a -l agent -d "Agent to use (default: build)" -r
