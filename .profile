# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bins if they exist
profile_path_prepend_once() {
    [ -d "$1" ] || return
    profile_path_prepend_target="$1"
    profile_path_prepend_old="$PATH"
    PATH=
    while [ -n "$profile_path_prepend_old" ]; do
        profile_path_prepend_entry="${profile_path_prepend_old%%:*}"
        if [ "$profile_path_prepend_old" = "$profile_path_prepend_entry" ]; then
            profile_path_prepend_old=
        else
            profile_path_prepend_old="${profile_path_prepend_old#*:}"
        fi
        [ "$profile_path_prepend_entry" = "$profile_path_prepend_target" ] && continue
        PATH="${PATH:+$PATH:}$profile_path_prepend_entry"
    done
    PATH="$profile_path_prepend_target${PATH:+:$PATH}"
}
profile_path_prepend_once "$HOME/bin"
profile_path_prepend_once "$HOME/.cargo/bin"
profile_path_prepend_once "$HOME/.local/bin"
export PATH
. "$HOME/.cargo/env"
. "$HOME/.atuin/bin/env"

. "$HOME/.atuin/bin/env"
