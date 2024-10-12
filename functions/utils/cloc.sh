# cloc_use_vcs
#
# This function runs the `cloc` (Count Lines of Code) command with the `--vcs=git` option.
# It allows you to count lines of code in a Git repository, automatically respecting any .gitignore exclusions.
#
# Usage:
#   cloc_use_vcs [OPTIONS]
#
# Arguments:
#   [OPTIONS] - Any additional options or arguments that you want to pass to the `cloc` command.
#
# Example:
#   cloc_use_vcs --exclude-dir=vendor
#
# Dependencies:
#   This function requires the `cloc` command to be installed and available in your PATH.
#
# Additional Info:
#   cloc now includes a --vcs option for using a version control system to provide a file list.
#   If using --vcs=git, it will automatically respect any .gitignore exclusions.
#   --vcs=<VCS>   Invoke a system call to <VCS> to obtain a list of files to work on.
#                 If <VCS> is 'git', then will invoke 'git ls-files' to get a file list and
#                 'git submodule status' to get a list of submodules whose contents will be ignored.
#                 See also --git which accepts git commit hashes and branch names.
# See also: https://stackoverflow.com/questions/26152014/cloc-ignore-exclude-list-file-clocignore
cloc_use_vcs() {
  cloc --vcs=git "$@"
}
