function gwapr --description 'Select a pull request and add its branch as a git worktree'
    argparse 'h/help' -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: gwapr"
        echo ""
        echo "Select an open pull request and create a git worktree for its branch."
        echo ""
        echo "Options:"
        echo "  -h, --help  Show this help message"
        return 0
    end

    set -l branch (gh pr list --json number,title,headRefName,author \
        | jq -r '.[] | "[36m#\(.number)[0m  \(.title) [90m(@\(.author.login))[0m │ \(.headRefName) │ \(.number)"' \
        | fzf --ansi --reverse --height 60% \
            --delimiter ' │ ' --with-nth 1 \
            --header 'Select a pull request' \
            --preview 'gh pr view {3}' \
        | awk -F ' │ ' '{print $2}')

    test -z "$branch"; and return 0

    set -l base_dir (basename (pwd) | string split -m 1 "+")[1]
    set -l branch_dirname (string replace -a '/' '%' $branch)
    set -l target_path "../$base_dir+$branch_dirname"

    git fetch origin $branch 2>/dev/null

    if git rev-parse --verify $branch >/dev/null 2>&1
        git worktree add $target_path $branch
    else if git rev-parse --verify origin/$branch >/dev/null 2>&1
        git worktree add --track -b $branch $target_path origin/$branch
    else
        echo "Error: branch '$branch' not found locally or in origin"
        return 1
    end

    cd $target_path
end
