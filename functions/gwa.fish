function gwa --description 'git worktree add (replaces / with % in dirname)'
    argparse 'h/help' -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: gwa [branch]"
        echo ""
        echo "Create a git worktree, replacing '/' with '%' in directory names."
        echo "If no branch is given, opens fzf to select from existing branches."
        echo ""
        echo "Arguments:"
        echo "  branch  Branch name to create or checkout as a worktree"
        echo ""
        echo "Options:"
        echo "  -h, --help  Show this help message"
        return 0
    end

    set -l branch
    if test (count $argv) -ge 1
        set branch $argv[1]
    else
        set branch (git branch --all --format='%(refname:short)' \
            | string replace -r '^origin/' '' | sort -u \
            | fzf --reverse --height 50% --header 'Select a branch' \
                --preview 'git log --oneline --color=always -15 {}')
        if test -z "$branch"
            return 0
        end
    end
    set -l base_dir (basename (pwd) | string split -m 1 "+" )[1]
    # ディレクトリ名用に / を % に置換（階層が深くならないようにする）
    set -l branch_dirname (string replace -a '/' '%' $branch)
    set -l target_path "../$base_dir+$branch_dirname"

    if git rev-parse --verify $branch >/dev/null 2>&1
        git worktree add $target_path $branch
    else
        git worktree add $target_path -b $branch
    end

    cd $target_path
end
