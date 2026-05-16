function gwcd --description 'Search and switch git worktrees with dynamic coloring'
    argparse 'h/help' -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: gwcd [branch]"
        echo ""
        echo "Search and switch git worktrees with dynamic coloring."
        echo ""
        echo "Arguments:"
        echo "  branch  Branch name to switch to directly (skips fzf)"
        echo ""
        echo "Options:"
        echo "  -h, --help  Show this help message"
        return 0
    end

    if test (count $argv) -ge 1
        set -l branch $argv[1]
        set -l branch_encoded (string replace -a '/' '%' $branch)
        set -l path (git worktree list | awk -v branch="$branch_encoded" -v raw_branch="$branch" '
            {
                path = $1
                n = split(path, parts, "/")
                dirname = parts[n]
                m = split(dirname, subparts, "+")
                if (m > 1 && subparts[2] == branch) { print path; exit }
                ref = $3; gsub(/[\[\]]/, "", ref)
                if (ref == raw_branch) { print path; exit }
            }')
        if test -n "$path"
            cd "$path"
        else
            echo "No worktree found for branch: $branch"
            return 1
        end
        return
    end

    set -l selected (git worktree list | awk '
        BEGIN {
            CYAN = "\033[36m";
            YELLOW = "\033[33m";
            RESET = "\033[0m";
            ICON_MAIN = "󰊢";
            ICON_WT   = "󱂬";
        }
        {
            path = $1;
            n = split(path, parts, "/");
            dirname = parts[n];
            m = split(dirname, subparts, "+");
            if (m > 1) {
                branch = subparts[2];
                gsub("%", "/", branch);
                printf "%s%s  %-25s%s │ %s\n", YELLOW, ICON_WT, branch, RESET, path
            } else {
                branch = ($3 == "" ? "main" : $3);
                gsub(/[\[\]]/, "", branch);
                printf "%s%s  %-25s%s │ %s\n", CYAN, ICON_MAIN, branch, RESET, path
            }
        }' | sort | fzf --ansi --reverse --height 50% --delimiter ' │ ' --with-nth 1 \
            --header 'Type  Branch' \
            --preview 'echo {2} | xargs eza --icons --color=always' \
            | awk -F ' │ ' '{print $2}')

    if test -n "$selected"
        cd "$selected"
    end
end
