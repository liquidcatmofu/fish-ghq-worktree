# 依存する外部コマンドのチェック（親切な設計）
set -l deps ghq fzf git gh eza bat jq
for dep in $deps
    if not command -v $dep >/dev/null
        echo "Warning: fish-ghq-worktree requires '$dep' to be installed."
    end
end

# Abbreviations
abbr -a gwl 'git worktree list'
abbr -a gwr 'git worktree remove'
abbr -a gwp 'git worktree prune'