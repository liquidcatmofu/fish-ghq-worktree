function gget --description 'Search GitHub repositories and ghq get'
    argparse 'h/help' 'c/collaborator' 'o/org' 'a/all' 'e/exclude-owner' -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: gget [options]"
        echo ""
        echo "Search GitHub repositories and clone via ghq."
        echo ""
        echo "Options:"
        echo "  -c, --collaborator    Include repositories you are a collaborator on"
        echo "  -o, --org             Include repositories from your organizations"
        echo "  -a, --all             Include all of the above"
        echo "  -e, --exclude-owner   Exclude your own repositories"
        echo "  -h, --help            Show this help message"
        return 0
    end

    set -l affiliations
    if not set -q _flag_exclude_owner
        set affiliations owner
    end
    if set -q _flag_all
        set affiliations $affiliations collaborator organization_member
    else
        set -q _flag_collaborator; and set affiliations $affiliations collaborator
        set -q _flag_org;          and set affiliations $affiliations organization_member
    end

    if test (count $affiliations) -eq 0
        echo "Error: --exclude-owner requires -c, -o, or -a"
        return 1
    end

    set -l affiliation (string join ',' $affiliations)
    set -l current_user (gh api /user --jq '.login')
    set -l header (printf "[%s]  \\033[36mown\\033[0m  \\033[33morg\\033[0m  \\033[32mcollaborator\\033[0m" $affiliation)

    set -l repo (gh api --paginate "/user/repos?affiliation=$affiliation&per_page=100" \
        | jq -r --arg user "$current_user" \
            '.[] | if .owner.type == "Organization"
                   then "[33m" + .full_name + "[0m"
                   elif .owner.login == $user
                   then "[36m" + .full_name + "[0m"
                   else "[32m" + .full_name + "[0m"
                   end + " │ " + .full_name' \
        | fzf --ansi --reverse --height 60% \
            --delimiter ' │ ' --with-nth 1 \
            --header $header \
            --preview 'gh repo view {2} | bat -l md --color=always --style=plain' \
        | awk -F ' │ ' '{print $2}')

    if test -n "$repo"
        echo "Cloning $repo via ghq..."
        ghq get $repo
        read -l -P "cd into $repo? [Y/n] " answer
        if test -z "$answer" -o "$answer" = Y -o "$answer" = y
            cd (ghq list -p --exact $repo)
        end
    end
end
