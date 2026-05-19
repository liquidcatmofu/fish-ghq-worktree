function gcreate --description 'Create a new GitHub repository and clone via ghq'
    argparse 'h/help' 'p/public' 'P/private' 'd/description=' 'r/readme' \
             'l/license=?' 'g/gitignore=?' 'disable-issues' 'disable-wiki' \
             'H/homepage=' -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: gcreate [options] [name]"
        echo ""
        echo "Create a new GitHub repository and clone via ghq."
        echo ""
        echo "Arguments:"
        echo "  name                     Repository name (prompted if omitted)"
        echo ""
        echo "Options:"
        echo "  -p, --public             Create a public repository"
        echo "  -P, --private            Create a private repository (default)"
        echo "  -d, --description <text> Repository description"
        echo "  -r, --readme             Add a README file"
        echo "  -l, --license [id]       Add a license (opens fzf if id omitted)"
        echo "  -g, --gitignore [tmpl]   Add a .gitignore (opens fzf if template omitted)"
        echo "      --disable-issues     Disable issues"
        echo "      --disable-wiki       Disable wiki"
        echo "  -H, --homepage <url>     Repository homepage URL"
        echo "  -h, --help               Show this help message"
        return 0
    end

    set -l name $argv[1]
    if test -z "$name"
        read -P "Repository name: " name
        if test -z "$name"
            echo "Error: repository name is required"
            return 1
        end
    end

    set -l gh_args

    if set -q _flag_public
        set gh_args $gh_args --public
    else
        set gh_args $gh_args --private
    end

    if set -q _flag_description
        set gh_args $gh_args --description $_flag_description
    end

    if set -q _flag_readme
        set gh_args $gh_args --add-readme
    end

    if set -q _flag_license
        if test -n "$_flag_license"
            set gh_args $gh_args --license $_flag_license
        else
            set -l license (gh api /licenses --jq '.[].spdx_id' \
                | fzf --reverse --height 40% --header 'Select a license')
            test -n "$license"; and set gh_args $gh_args --license $license
        end
    end

    if set -q _flag_gitignore
        if test -n "$_flag_gitignore"
            set gh_args $gh_args --gitignore $_flag_gitignore
        else
            set -l tmpl (gh api /gitignore/templates --jq '.[]' \
                | fzf --reverse --height 40% --header 'Select a .gitignore template')
            test -n "$tmpl"; and set gh_args $gh_args --gitignore $tmpl
        end
    end

    if set -q _flag_disable_issues
        set gh_args $gh_args --disable-issues
    end

    if set -q _flag_disable_wiki
        set gh_args $gh_args --disable-wiki
    end

    if set -q _flag_homepage
        set gh_args $gh_args --homepage $_flag_homepage
    end

    gh repo create $name $gh_args
    or return 1

    set -l current_user (gh api /user --jq '.login')
    set -l full_name "$current_user/$name"

    echo "Cloning $full_name via ghq..."
    ghq get $full_name
    or return 1

    read -P "cd into $full_name? [Y/n] " answer
    if test -z "$answer" -o "$answer" = Y -o "$answer" = y
        cd (ghq list -p --exact $full_name)
    end
end
