# jump-list of directories
# source into .bashrc
# use: j [mask1] ... [maskn]
j() {
 jfile=$HOME/.j
 [ "$1" = "--add" ] && {
  shift
  awk -v d="$*" -v mx=1000 -F"|" '
   $2 >= 1 { 
    if( $1 == d ) { l[$1] = $2 + 1; x = 1 } else l[$1] = $2
    y += $2
   }
   END {
    if( !x ) l[d] = 1
    if( y > mx ) {
     for( i in l ) print i "|" l[i]*(0.9*mx/y)
    } else for( i in l ) print i "|" l[i]
   }
  ' $jfile 2>/dev/null > $jfile.tmp
  mv $jfile.tmp $jfile
  return
 }
 local IFS='
'
 set -- $(awk -v r="$*" -F"|" '
  BEGIN { split(r,a," ") }
  { for( o in a ) if( $1 !~ a[o] ) $1 = ""; if( $1 ) print $2 "\t" $1 }
 ' $jfile | sort -nr | cut --complement -f 1)
 if [ $# -eq 0 ]; then
  return
 elif [ $# -eq 1 ]; then
  cd "$1"
 else
  for x in "$@"; do
   echo $x
  done | nl -n ln
  echo -n "Number: "
  read C
  [ "$C" = "0" -o -z "$C" ] && return
  eval D="\${$C}" 2>/dev/null
  [ "$D" ] && cd "$D"
 fi
}
PROMPT_COMMAND='j --add "$(pwd -P)";'"$PROMPT_COMMAND"
