# maintains a jump-list of directories you actually use
# old directories eventually fall off the list
# inspired by Joel Schaerer's http://wiki.github.com/joelthelion/autojump
# and something similar i had - but i could never get the dir list right.
#
# INSTALL:
#   source into .bashrc under your '[-z "$PS1" ] || return' line
#   cd around for a while
#
# USE:
#   j [--h[elp]] [--l ] [--r] [regex1 ... regexn]
#     regex1 ... regexn jump to the most used directory matching all masks
#     --l               show the list instead of jumping
#     --r               order by recently used instead of most used
#                       with no args, returns full list (same as j --l)
j() {
 # change jfile if you already have a .j file for something else
 jfile=$HOME/.j
 if [ "$1" = "--add" ]; then
  shift
  # we're in $HOME all the time, let something else get all the good letters
  [ "$*" = "$HOME" ] && return
  awk -v q="$*" -v t="$(date +%s)" -F"|" '
   $2 >= 1 { 
    if( $1 == q ) {
     l[$1] = $2 + 1
     d[$1] = t
     found = 1
    } else {
     l[$1] = $2
     d[$1] = $3
     count += $2
    }
   }
   END {
    if( !found ) l[q] = 1 && d[q] = t
    if( count > 1000 ) {
     for( i in l ) print i "|" 0.9*l[i] "|" d[i] # aging
    } else for( i in l ) print i "|" l[i] "|" d[i]
   }
  ' $jfile 2>/dev/null > $jfile.tmp
  mv -f $jfile.tmp $jfile
 elif [ "$1" = "--h" -o "$1" = "--help" ]; then
  echo "j [--h] [--l ] [--r] [regex1 ... regexn]"
 elif [ "$1" = "" -o "$1" = "--l" ];then
  shift
  [ "$1" = "--r" ] && local r=r
  awk -v q="$*" -v t="$(date +%s)" -F"|" '
   BEGIN {
    if( substr(q,1,3) == "--r" ) {
     split(substr(q,5),a," ")
     f = 3
    } else {
     split(q,a," ")
     f = 2
    }
   }
   {
    for( i in a ) $1 !~ a[i] && $1 = ""
    if( $1 ) if( f == 3 ) { print t - $f "\t" $1 } else print $f "\t" $1
   }
  ' $jfile 2>/dev/null | sort -n$r
 # for completion
 elif [ "$1" = "--complete" -o "$2" = "--complete" ];then
  awk -v q="$2" -F"|" '
   BEGIN {
    if( substr(q,1,5) == "j --r" ) {
     split(substr(q,7),a," ")
    } else split(substr(q,3),a," ")
    for( i in a ) print i, a[i] >> "/home/rupa/aargh"
   }
   { for( i in a ) $1 !~ a[i] && $1 = ""; if( $1 ) print $1 }
  ' $jfile 2>/dev/null
 # if we hit enter on a completion just go there (ugh, this is ugly)
 elif [[ "$*" =~ "/" ]]; then
  x=$*
  x=/${x#*/}
  [ -d "$x" ] && cd "$x"
 else
  # prefer case sensitive
  cd=$(awk -v q="$*" -F"|" '
   BEGIN { 
    if( substr(q,1,3) == "--r" ) {
     split(substr(q,5),a," ")
     f = 3
    } else {
     split(q,a," ")
     f = 2
    }
   }
   { for( i in a ) $1 !~ a[i] && $1 = ""; if( $1 ) { print $f "\t" $1; x = 1 } }
   END {
    if( x ) exit
    close(FILENAME)
    while( getline < FILENAME ) {
     for( i in a ) tolower($1) !~ tolower(a[i]) && $1 = ""
     if( $1 ) print $f "\t" $1
    }
   }
  ' $jfile 2>/dev/null | sort -nr | head -n 1 | cut -f 2)
  [ "$cd" ] && cd "$cd"
 fi
}
# bash completions for j
complete -C 'j --complete "$COMP_LINE"' j
# prepend to PROMPT_COMMAND
PROMPT_COMMAND='j --add "$(pwd -P)";'"$PROMPT_COMMAND"
