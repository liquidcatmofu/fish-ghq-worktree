complete -c gwa -f -a "(git branch --all --format='%(refname:short)' | string replace -r '^origin/' '' | sort -u)"
