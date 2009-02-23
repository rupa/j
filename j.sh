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
#   j [--l] [regex1 ... regexn]
#     regex1 ... regexn jump to the most used directory matching all masks
#     --l               show the list instead of jumping
#                       with no args, returns full list
j() {
 # change jfile if you already have a .j file for something else
 local jfile=$HOME/.j
 if [ "$1" = "--add" ]; then
  shift
  # we're in $HOME all the time, let something else get all the good letters
  [ "$*" = "$HOME" ] && return
  awk -v q="$*" -F"|" '
   $2 >= 1 { 
    if( $1 == q ) { l[$1] = $2 + 1; found = 1 } else l[$1] = $2
    count += $2
   }
   END {
    found || l[q] = 1
    if( count > 1000 ) {
     for( i in l ) print i "|" 0.9*l[i] # aging
    } else for( i in l ) print i "|" l[i]
   }
  ' $jfile 2>/dev/null > $jfile.tmp
  mv -f $jfile.tmp $jfile
 elif [ "$1" = "" -o "$1" = "--l" ];then
  shift
  awk -v q="$*" -F"|" '
   BEGIN { split(q,a," ") }
   { for( i in a ) $1 !~ a[i] && $1 = ""; if( $1 ) print $2 "\t" $1 }
  ' $jfile 2>/dev/null | sort -n
 # for completion
 elif [ "$1" = "--complete" ];then
  awk -v q="$2" -F"|" '
   BEGIN { split(substr(q,3),a," ") }
   { for( i in a ) $1 !~ a[i] && $1 = ""; if( $1 ) print $1 }
  ' $jfile 2>/dev/null
 # if we hit enter on a completion just go there (ugh, this is ugly)
 elif [[ "$*" =~ "/" ]]; then
  local x=$*; x=/${x#*/}; [ -d "$x" ] && cd "$x"
 else
  # prefer case sensitive
  local cd=$(awk -v q="$*" -F"|" '
   BEGIN { split(q,a," ") }
   { for( i in a ) $1 !~ a[i] && $1 = ""; if( $1 ) { print $2 "\t" $1; x = 1 } }
   END {
    if( x ) exit
    close(FILENAME)
    while( getline < FILENAME ) {
     for( i in a ) tolower($1) !~ tolower(a[i]) && $1 = ""
     if( $1 ) print $2 "\t" $1
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
