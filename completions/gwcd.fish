complete -c gwcd -f -a "(git worktree list | while read -l line
    set -l fields (string split -n ' ' -- \$line)
    set -l wt_path \$fields[1]
    set -l dirname (string split '/' -- \$wt_path)[-1]
    set -l subparts (string split '+' -- \$dirname)
    if test (count \$subparts) -gt 1
        string replace -a '%' '/' -- \$subparts[2]
    else if test (count \$fields) -ge 3
        string trim -c '[]' -- \$fields[3]
    end
end)"
