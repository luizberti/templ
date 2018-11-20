#!/bin/bash -e
usage() {
    test -n "$1" && (
        echo "$@"
        echo usage: $0 KEY=Value TARGET [TARGET ...]
    ) >&2 && exit 1

    local norm=$(tput sgr0)
    local bold=$(tput bold)
    local term=$(tput setaf 003)
    local hint=$(tput setaf 011)
    local note=$(tput setaf 007)
    less -XRF -P 'ISC Licensed' <<EOF
${bold}NAME${norm}
    ${bold}templ${norm} - the simplest templating engine

${bold}SYNOPSIS${norm}
    ${term}$ templ${norm}
    usage: templ KEY=Value TARGET [TARGET ...]

    ${term}$ templ [-h | --help]${norm}
    <prints this help manual page>

    ${term}$ echo '{{KEY}}' | templ KEY=Value ${hint}-  ${note}# this means STDIN in POSIX${norm}
    Value

    ${term}$ echo '${hint}{{{{${term}KEY${hint}}}}}${term}' | ${hint}REPS=4${term} templ KEY=Value -${norm}
    Value

    ${term}$ echo '{{KEY}}' | templ ${hint}"KEY=\$(cat big)"${term} -  ${note}# this can be complex!${norm}
    <the contents of 'big'>

    ${term}$ templ KEY=Value template.yaml.in ${hint}&& ls  ${note}# it only operates on *.in files${norm}
    template.yaml.in    ${hint}template.yaml

    ${term}$ ${hint}VERBOSE=1${term} templ KEY=Value template.yaml.in  ${note}# you can also use DRYRUN=1
    ${hint}template.yaml.in                              ${note}# to simulate execution

    ${term}$ ${hint}DESTROYSRC=1${term} templ KEY=Value template.yaml.in ${hint}&& ls  ${note}# removes templates
    ${hint}template.yaml                                          ${note}# after conversion!

${bold}DESCRIPTION${norm}
    This tool was written to aid the deployment of template assets in
    environments where you wouldn't want to install dependencies. The only
    requirement this has is Bash 4.4 or higher.

    It's a very simple tool, which makes it very handy, but also means it
    has several limitations. If it doesn't suit your use case in particular
    you might have to search for more robust alternatives. If you need
    POSIX compliance, take a look at M4(1).

${bold}AUTHORS${norm}
    Created by ${bold}Luiz Berti${norm}           ${bold}https://berti.me
                                    ${bold}https://github.com/luizberti
    Hosted on ${bold}GitHub${norm}                ${bold}https://github.com/luizberti/templ

${bold}LICENSING${norm}
    Copyright (c) 2018 Luiz Berti <luizberti@users.noreply.github.com>

    Permission to use, copy, modify, and distribute this software for any
    purpose with or without fee is hereby granted, provided that the above
    copyright notice and this permission notice appear in all copies.

    THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
    WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
    MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
    ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
    WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
    ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
    OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
EOF
    exit
}


# ARGUMENT PARSING
##################

[[ "$1" =~ ^(-h|--help)$ ]] && usage  # PRINTS MAN PAGE
SEQN="$(seq 1 ${REPS:-2})"  || usage  'invalid REPS'

TARGETS="$(for arg in "$@"; do
    test "${arg#*=}" != "$arg" && continue
    test "$arg" != - && find "$arg" -name '*.in' -type f || echo -
done)" && test -n "$TARGETS" || usage 'no targets were given!'
for arg in "$@"; do shift; test "${arg#*=}" != "$arg" && set -- "$@" "$arg"; done  # PRUNE ARGV

test "$DRYRUN" = 1 && tr -s / / <<< "$TARGETS" | xargs -n1 echo >&2 && exit        # DRYRUN


# CORE SECTION
##############

fill() {
    local str="$(cat)"

    for arg in "$@"; do
        local sub="${LHS:=$(printf '{%.0s' $SEQN)}${arg%%=*}${RHS:=$(printf '}%.0s' $SEQN)}"
        local val="${arg#*=}"

        str="${str//"$sub"/$val}"
    done

    cat <<< "$str"
}

for target in $TARGETS; do
    test "$VERBOSE" = 1 && test $target != - && echo $target | tr -s / / >&2

    if [ "$target" = - ]; then
        fill "$@"
    else
        cat $target | fill "$@" > ${target%.in}

        # PRESERVE OWNERSHIP AND PERMISSIONS
        chown $(stat -c %u:%g $target 2>/dev/null || stat -f %u:%g $target 2>/dev/null) ${target%.in}
        chmod $(stat -c %a    $target 2>/dev/null || stat -f %p    $target 2>/dev/null) ${target%.in}

        test "$DESTROYSRC" = 1 && rm $target
    fi
done

