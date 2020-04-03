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
**Substituting from STDIN**
```bash
$ echo 'Hi, my name is {{FIRST}} {{LAST}}' | templ FIRST=John LAST=Doe -
Hi, my name is John Doe
```

**Substitute big files, no need to worry about escaping them for `templ`**
```bash
$ echo 'big.txt: {{CONTENTS}}' | templ CONTENTS="$(curl https://norvig.com/big.txt)" -
big.txt: The Project Gutenberg EBook of The Adventures of Sherlock Holmes
by Sir Arthur Conan Doyle
...
```

**Using template files**
```bash
# NOTE Templates should end with `.in`
$ ls /etc/spark-conf
core-site.xml.in    yarn-site.xml.in    spark-defaults.conf.in

# NOTE This is injecting `SPARK` and `HADOOP` related env vars into the template
$ DESTROYSRC=1 templ $(SPARK=foo env | grep -E 'SPARK|HADOOP') /etc/spark-conf

# NOTE The DELETESRC variable removed the original templates after substitution
$ ls /etc/spark-conf
core-site.xml       yarn-site.xml       spark-defaults.conf
```

**Configurable delimiters and delimiter sequence lengths**
```bash
# NOTE The SEQN env variable configures how many delimiters to use for the substitution
$echo '{{{{FIRST}}}} {{LAST}}' | SEQN=4 templ FIRST=John LAST=Doe -
Hi, my name is John {{LAST}}

# NOTE The LHS and RHS env vars respectively set the left and right delimiter characters
$ echo '%%FOO%%' | LHS='%' RHS='%' templ FOO=bar -
bar
```
