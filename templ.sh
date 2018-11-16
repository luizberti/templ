#!/bin/bash -e
usage() {
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
    usage: templ KEY=Value filename ...

    ${term}$ templ [-h | --help]${norm}
    <prints this help manual page>

    ${term}$ echo '{{KEY}}' | templ KEY=Value ${hint}-  ${note}# this means STDIN in POSIX${norm}
    Value

    ${term}$ echo '${hint}{{{{${term}KEY${hint}}}}}${term}' | ${hint}REPS=4${term} templ KEY=Value -${norm}
    Value

    ${term}$ echo '{{KEY}}' | templ ${hint}"KEY=\$(cat big)"${term} -  ${note}# this can be complex!${norm}
    <the contents of 'big'>

    ${term}$ ${hint}VERBOSE=1${term} templ KEY=Value ${hint}template.yaml${norm}
    template.yaml

    ${term}$ ${hint}DRYRUN=1${term} templ KEY=Value template.yaml  ${note}# this only prints the targets${norm}
    template.yaml

    ${term}$ ${hint}BACKUP=1${term} templ KEY=Value template.yaml ${hint}&& ls  ${note}# *.bak is intact!
    template.yaml   template.yaml.bak

${bold}DESCRIPTION${norm}
    This tool was written to aid the deployment of template assets in
    environments where you wouldn't want to install dependencies. The only
    dependency this requires is having any working version of Python in
    your ${bold}\$PATH${norm}.

    It's a very simple tool, which makes it very handy, but also means it
    has several limitations. If it doesn't suit your use case in particular
    you might have to search for more robust alternatives.

${bold}AUTHORS${norm}
    Created by ${bold}Luiz Berti${norm}, and primarily hosted on GitHub at
    ${bold}https://gist.github.com/luizberti/efc3a84e908deedb05307eed1d9b444d

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
    exit $1
}

# EARLY EXIT CONDITIONS
#######################

test -z "$REPS" && REPS=2                                        # SETS DEFAULT REPS
test "$REPS" -ge 0 2> /dev/null || usage 1                       # PRINTS USAGE IF INVALID REPS
test -z "$1" && echo usage: $0 KEY=Value filename ... && exit 1  # PRINTS QUICK GUIDE IF NO ARGS
test "$1" = '--help' || test "$1" = '-h' && usage                # PRINTS HELP IF REQUESTED


# CORE FUNCTIONS
################

replace() {
    KEY="$1" VALUE="$2" python -c "$(cat <<EOF
from os import environ as env
from sys import stdin, stdout
stdout.write(stdin.read().replace(('{'*$REPS)+env['KEY']+('}'*$REPS), env['VALUE']))
EOF
)"
}

fill() {
    test -z "$1" && cat - && return
    local sub="$1" && shift
    replace "$(cut -d = -f1 <<< "$sub")" "$(cut -d = -f2- <<< "$sub")" | fill "$@"
}


# ARGUMENT PARSING
##################

TARGETS="$(for arg in "$@"; do
    test "${arg#*=}" != "$arg" && continue
    test "$arg" != - && find "$arg" -name '*.in' -type f || echo -
done)"
for arg in "$@"; do shift; test "${arg#*=}" != "$arg" && set -- "$@" "$arg"; done  # PRUNE ARGV
test "$DRYRUN" = 1 && tr -s / / <<< "$TARGETS" | xargs -n1 echo 1>&2 && exit       # DRYRUN


# MAIN
######

for target in $TARGETS; do
    test "$VERBOSE" = 1 && test $target != - && echo $target | tr -s / / 1>&2

    test "$target" = - && fill "$@" && continue

    cat $target | fill "$@" > ${target%.in}
    chown $(stat -f '%u:%g' $target) ${target%.in}  # PRESERVE OWNERSHIP
    chmod $(stat -f '%p'    $target) ${target%.in}  # PRESERVE PERMISSIONS

    test "$DESTROYSRC" = 1 && rm $target
done

