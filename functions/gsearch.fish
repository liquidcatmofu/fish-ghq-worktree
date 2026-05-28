function gsearch --description 'Search GitHub repositories by keyword and ghq get'
    argparse 'h/help' -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: gsearch <query>"
        echo ""
        echo "Search GitHub repositories by keyword and clone via ghq."
        echo ""
        echo "Arguments:"
        echo "  query  Search keyword(s) to pass to 'gh search repos'"
        echo ""
        echo "Options:"
        echo "  -h, --help  Show this help message"
        return 0
    end

    if test (count $argv) -lt 1
        echo "Usage: gsearch <query>"
        return 1
    end

    set -l repo (gh search repos $argv --limit 100 | fzf --reverse --height 60% \
        --preview 'gh repo view (echo {1} | awk "{print \$1}") | bat -l md --color=always --style=plain')

    if test -n "$repo"
        set -l repo_name (echo "$repo" | awk '{print $1}')
        ghq get $repo_name
        read -l -P "cd into $repo_name? [Y/n] " answer
        if test -z "$answer" -o "$answer" = Y -o "$answer" = y
            cd (ghq list -p --exact $repo_name)
        end
    end
end
