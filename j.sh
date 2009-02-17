# maintains a jump-list of directories you actually use
# old directories eventually fall off the list
# inspired by http://wiki.github.com/joelthelion/autojump
# and something similar i had - but i could never get the dir list right.
#
# INSTALL:
#   source into .bashrc under your '[-z "$PS1" ] || return' line
#   cd around for a while
#
# USE:
#   j [--l] [regex1 ... regexn]
#     regex1 ... regexn jump to the most used directory matching all masks
#     --l               show the list instead of jumping
j() {
 # change jfile if you already have a .j file for something else
 jfile=$HOME/.j
 if [ "$1" = "--add" ]; then
  shift
  # we're in $HOME all the time, let something else get all the good letters
  [ "$*" = "$HOME" ] && return
  awk -v q="$*" -v mx=1000 -F"|" '
   $2 >= 1 { 
    if( $1 == q ) { l[$1] = $2 + 1; x = 1 } else l[$1] = $2
    y += $2
   }
   END {
    x || l[q] = 1
    if( y > mx ) {
     for( i in l ) print i "|" l[i]*(0.9*mx/y) # aging
    } else for( i in l ) print i "|" l[i]
   }
  ' $jfile 2>/dev/null > $jfile.tmp
  mv $jfile.tmp $jfile
 elif [ "$1" = "--l" ];then
  shift
  awk -v q="$*" -F"|" '
   BEGIN { split(q,a," ") }
   { for( o in a ) $1 !~ a[o] && $1 = ""; if( $1 ) print $2 "\t" $1 }
  ' $jfile | sort -n
 # for completion
 elif [ "$1" = "--complete" ];then
  awk -v q="$3" -F"|" '
   BEGIN { split(q,a," ") }
   { for( o in a ) $1 !~ a[o] && $1 = ""; if( $1 ) print $1 }
  ' $jfile
 # if we hit enter on a completion just go there
 elif [ "${1:0:1}" = "/" -a -d "$*" ]; then
  cd "$*"
 else
  # prefer case sensitive
  cd=$(awk -v q="$*" -F"|" '
   BEGIN { split(q,a," ") }
   { for( o in a ) $1 !~ a[o] && $1 = ""; if( $1 ) { print $2 "\t" $1; x = 1 } }
   END {
    if( x ) exit
    close(FILENAME)
    while( getline < FILENAME ) {
     for( o in a ) tolower($1) !~ tolower(a[o]) && $1 = ""
     if( $1 ) print $2 "\t" $1
    }
   }
  ' $jfile | sort -nr | head -n 1 | cut -f 2)
  [ "$cd" ] && cd "$cd"
 fi
}
# prepend to PROMPT_COMMAND
PROMPT_COMMAND='j --add "$(pwd -P)";'"$PROMPT_COMMAND"
# bash completions for j
complete -o dirnames -o filenames -C "j --complete" j