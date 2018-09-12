#!/bin/sh
##############################################################################
#
# Copyright 2015 spf-tools team (see AUTHORS)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#     Unless required by applicable law or agreed to in writing, software
#     distributed under the License is distributed on an "AS IS" BASIS,
#     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#     See the License for the specific language governing permissions and
#     limitations under the License.
#
##############################################################################

a="/$0"; a=${a%/*}; a=${a:-.}; a=${a#/}/; BINDIR=$(cd $a; pwd)
export PATH=$BINDIR/../include:$PATH
tmp=$(mktemp /tmp/spf-test-unit-XXXXXXXXX)
trap "rm $tmp*" EXIT
. $BINDIR/../include/despf.inc.sh
export LC_ALL=C
export LANG=C

testexpect() {
  IN=0
  test "x$1" = "x-n" && { shift; > $tmp-out; } || cat > $tmp-out
  EXPRET=$1
  shift

  echo .. Testing $* ...
  set +e
  eval "$@" > $tmp-real
  RETURN=$?
  set -e
  test -s $tmp-out && { sort $tmp-real | diff -u $tmp-out -; }
  test $EXPRET -eq $RETURN
  echo .... OK
}

testexpect 0 get_txt spf.jasan.tk <<EOF
v=spf1 include:spf1.jasan.tk ~all
EOF

testexpect 0 "get_ns jasan.tk | sort" <<EOF
chris.ns.cloudflare.com.
dawn.ns.cloudflare.com.
EOF

#testexpect 0 findns one.jasan.tk <<EOF
#ns1.he.net.
#EOF

testexpect -n 1 findns orig.non-existent.nonnon

cat > $tmp <<EOF
1.2.3.4
fec0::1
EOF
testexpect 0 "cat $tmp | printip" <<EOF
ip4:1.2.3.4
ip6:fec0::1
EOF

cat > $tmp <<EOF
1.2.3.4
test
fec0::1
EOF
testexpect 0 "cat $tmp | printip" <<EOF
ip4:1.2.3.4
ip6:fec0::1
EOF

cat > $tmp <<EOF
-1.2.3.4
+1.2.3.5
?1.2.3.6
~1.2.3.7
EOF
testexpect 0 "cat $tmp | printip" <<EOF
-ip4:1.2.3.4
?ip4:1.2.3.6
ip4:1.2.3.5
~ip4:1.2.3.7
EOF

testexpect 0 dea both.jasan.tk <<EOF
ip4:1.2.3.4
ip6:fec0::1
EOF

testexpect 0 dea cname.jasan.tk <<EOF
ip4:1.2.3.4
ip6:fec0::1
EOF

testexpect 0 dea cname.jasan.tk 24 <<EOF
ip4:1.2.3.4/24
ip6:fec0::1/24
EOF

testexpect 0 demx mx.jasan.tk <<EOF
ip4:5.6.7.8
ip6:56:78::1
EOF

testexpect 0 demx mx.jasan.tk 24 <<EOF
ip4:5.6.7.8/24
ip6:56:78::1/24
EOF

testexpect 0 getamx both-spf.jasan.tk a:both.jasan.tk <<EOF
ip4:1.2.3.4
ip6:fec0::1
EOF

testexpect 0 parsepf spf.jasan.tk <<EOF
v=spf1 include:spf1.jasan.tk ~all
EOF

# This tests the correct process of iteration
# between different NS servers if one is not
# responding
testexpect 0 parsepf morens.jasan.tk <<EOF
v=spf1 include:spf1.jasan.tk ~all
EOF

testexpect -n 1 parsepf mail.jasan.tk

testexpect -n 1 isincidrange.sh 74.86.241.250 199.122.123.192 32

testexpect -n 0 isincidrange.sh 192.168.5.1 192.168.0.0 16

testexpect -n 1 checkval4 a.1.1.2
testexpect -n 1 checkval4 290.1.1.0
testexpect -n 1 checkval4 123.197.5
testexpect -n 0 checkval4 192.168.0.1
testexpect -n 0 checkval4 192.168.0.1 24
testexpect -n 0 checkval4 192.168.0.1 32
testexpect -n 1 checkval4 192.168.0.1 33

testexpect -n 1 checkval6 aaa::aab::aac
testexpect -n 1 checkval6 aaq::aab
testexpect -n 1 checkval6 aaaaa::aab
testexpect -n 0 checkval6 ::1
testexpect -n 0 checkval6 ::1 64
testexpect -n 1 checkval6 ::1 129

testexpect -n 1 expand6 1:1
testexpect -n 1 expand6 1:1:1:1:1:1:1:1:1
testexpect 0 expand6 ::1 <<EOF
0000:0000:0000:0000:0000:0000:0000:0001
EOF

testexpect -n 0 numlesseq 25 25
testexpect -n 1 numlesseq 26 25
