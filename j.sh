# jump-list of directories
# source into .bashrc
# j [--l] [mask1] ... [maskn]
j() {
 jfile=$HOME/.j
 if [ "$1" = "--add" ]; then
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
 elif [ "$1" == "--l" ];then
  shift
  awk -v r="$*" -F"|" '
   BEGIN { split(r,a," ") }
   { for( o in a ) if( $1 !~ a[o] ) $1 = ""; if( $1 ) print $2 "\t" $1 }
  ' $jfile | sort -nr
 else
  cd=$(awk -v r="$*" -F"|" '
   BEGIN { split(r,a," ") }
   { for( o in a ) if( $1 !~ a[o] ) $1 = ""; if( $1 ) print $2 "\t" $1 }
  ' $jfile | sort -nr | head -n 1 | cut -f 2)
  [ "$cd" ] && cd "$cd"
 fi
}
PROMPT_COMMAND='j --add "$(pwd -P)";'"$PROMPT_COMMAND"