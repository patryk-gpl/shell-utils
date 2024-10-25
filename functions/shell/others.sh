shell_find_function_alias_names() {
    local keyword="$1"
    local shell_type

    colored_grep() {
        grep --color=auto "$@"
    }

    if [ -n "$ZSH_VERSION" ]; then
        shell_type="zsh"
    elif [ -n "$BASH_VERSION" ]; then
        shell_type="bash"
    else
        echo "Unsupported shell. Only Bash and Zsh are supported." >&2
        return 1
    fi

    list_functions() {
        if [ "$shell_type" = "zsh" ]; then
            # shellcheck disable=SC2296,SC2086
            print -l ${(k)functions}
        else
            declare -F | awk '{print $3}'
        fi
    }

    list_aliases() {
        if [ "$shell_type" = "zsh" ]; then
            alias | sed -E 's/^([^=]+)=.*/\1/'
        else
            alias | sed -E "s/alias ([^=]+)=.*/\1/"
        fi
    }
    list_functions | colored_grep -E "$keyword"
    echo "Functions matching '$keyword':"
    list_functions | grep -E "$keyword"
    list_aliases | colored_grep -E "$keyword"
    echo -e "\nAliases matching '$keyword':"
    list_aliases | grep -E "$keyword"
}
