#!/bin/bash -e
usage() {
    test -n "$1" && (
        echo "$@"
        echo usage: $0
    ) >&2 && exit 1

    local norm=$(tput sgr0)
    local bold=$(tput bold)
    local term=$(tput setaf 003)
    local hint=$(tput setaf 011)
    local note=$(tput setaf 007)
    less -XRF -P 'ISC Licensed' <<EOF
${bold}NAME${norm}
    ${bold}templ-map${norm} - completion maps for templ

${bold}SYNOPSIS${norm}
    ${term}$ templ-map${norm}
    usage: templ-map

${bold}DESCRIPTION${norm}
    While templ is an excelent tool, there sometimes might be too much
    boilerplate if you want to substitute many possible values. This tool
    was created to aid users of templ that have several substitutions to map.

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
RAWMAP="$1"; shift


# CORE SECTION
##############

if [[ "$RAWMAP" == --env ]]; then
    for var in $(compgen -v); do map+=("$var=${!var}"); done
elif [[ "$RAWMAP" == --kv=* ]]; then
    while read -r var; do map+=("$var"); done <<< "${RAWMAP#*=}"
elif [[ "$RAWMAP" == --csv=* ]]; then
    while read -r var; do map+=("${var%%,*}=${var#*,}"); done <<< "${RAWMAP#*=}"
elif [[ "$RAWMAP" == --tsv=* ]]; then
    while read -r var; do map+=("$var"); done <<< "$(awk '{print $1 "=" $2}' <<< "${RAWMAP#*=}")"
elif [[ "$RAWMAP" == --json=* ]]; then
    hash jq 2> /dev/null || usage 'please install jq to use json mappings'

    MAP="${RAWMAP#*=}"
    for key in $(jq -rc 'keys[]' <<< "$MAP"); do map+=("$key=$(jq -rc ".$key" <<< "$MAP")"); done
else
    usage 'not a valid mapping'
fi

templ "${map[@]}" "$@"

