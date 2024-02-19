alias ls='ls -la --color'
alias grep='grep -n --color'

function set_python {
    # set alias to python3 if it's not set
    which python > /dev/null
    STDPY=$?
    which python3 > /dev/null
    if [[ ($STDPY == 1) && ($? == 0) ]]; then
        alias python='python3';
    fi
}
set_python

function get_hostname {
    export SHORTNAME=${HOSTNAME%%.*}
}

function git_branch() {
    gitbranch=$(git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/');
}

function user_color {
    id | grep "root" > /dev/null
    REVTAL=$?
    if [[ $REVTAL == 0 ]]; then
        usercolor="[0;31m";
    else
        usercolor="[0;32m";
    fi
}

function settitle () {
    u=${USERNAME}
    h="$u@${HOSTNAME}"
    echo -ne "\e]2;$h\a\e]1;$h\a"
}

inputcolor='[0;37m'
cwdcolor='[0;34m'
host_name='[1;31m'
branchcolor='[0;36m'
user_color
PROMPT_COMMAND='settitle; git_branch; get_hostname; history -a;'
PS1='\n\[\e${cwdcolor}\][${PWD}]\[\e${branchcolor}\]${gitbranch}\n\[\e${usercolor}\][\u]\[\e${host_name}\][${SHORTNAME}]\[\e${inputcolor}\] $ '
export PS1

