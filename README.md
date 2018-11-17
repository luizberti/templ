# TEMPL
TEMPL is a tiny, dependency free _(aside from Bash 4.4+)_, templating
engine that can do simple or complex string replacement. Think of it
as a regex-free alternative to replacing configuration stubs and
placeholders with `sed`.

TEMPL can also be a building block for more complex things in different
workflows. You can parse a CSV with `awk` and let TEMPL fill in the forms
for you, or you can build a static site generator for hardcore POSIX
bloggers. It's up to your imagination.


## Examples
**Fill configuration files from environment variables**
```bash
$ ls /etc/spark-conf
core-site.xml.in    yarn-site.xml.in    spark-defaults.conf.in
$ DESTROYSRC=1 templ $(SPARK=foo env | grep -E 'SPARK|HADOOP') /etc/spark-conf
```

**Automate Emails!**
```bash
$ cat sorry.txt.in
Subject: Can't go...
I'm so sorry I can't make it to your party {{NAME}}! I told {{LIE}} I'd go to his...

$ cat contacts.tsv
Joe     joe@a.com
Jon     jon@b.com
Vic     vic@c.com

$ LIES="$(join -j 42 -o {1,2}.1 contacts.tsv{,} | awk '$1 != $2 {print $1, $2}')"

$ LIES="$(sort -u -k1,1 <<< "$LIES" | join -j 1 - contacts.tsv)"

$ echo "$LIES"
Joe Jon joe@a.com
Jon Joe jon@b.com
Vic Joe vic@c.com

$ xargs -n 3 sh -c 'cat sorry.txt | templ NAME=$0 LIE=$1 - | sendmail $2' <<< "$LIES"
Subject: Can't go...
I'm so sorry I can't make it to your party Joe! I told Jon I'd go to his...
SENT
Subject: Can't go...
I'm so sorry I can't make it to your party Jon! I told Joe I'd go to his...
SENT
Subject: Can't go...
I'm so sorry I can't make it to your party Vic! I told Joe I'd go to his...
SENT
```

