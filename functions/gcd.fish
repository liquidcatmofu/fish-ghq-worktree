function gcd --description 'Search ghq repositories with icon-based view'
    argparse 'h/help' -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: gcd"
        echo ""
        echo "Search and move to a ghq-managed repository using fzf."
        echo "Domains are replaced with Nerd Font icons for compact display."
        echo ""
        echo "Options:"
        echo "  -h, --help  Show this help message"
        return 0
    end

    set -l selected (ghq list | awk -F/ '
        BEGIN {
            CYAN = "\033[36m";
            GRAY = "\033[90m";
            RESET = "\033[0m";
        }
        {
            # ドメインをNerd Fontアイコンに変換
            icon = ($1 == "github.com" ? " " : "󰊤 ");
            
            # ユーザー名/リポジトリ名の部分を抽出
            path = "";
            for (i=2; i<=NF; i++) {
                path = (path == "" ? $i : path "/" $i);
            }
            
            # アイコンはグレー、パスはシアンで表示
            printf "%s%s %s%s%-30s%s │ %s\n", GRAY, icon, RESET, CYAN, path, RESET, $0
        }' | fzf --ansi --reverse --height 50% --delimiter ' │ ' --with-nth 1 \
            --preview 'ghq list -p --exact {2} | xargs eza --tree --level 2 --icons --color=always' \
            | awk -F ' │ ' '{print $2}')

    if test -n "$selected"
        cd (ghq list -p --exact "$selected")
    end
end
