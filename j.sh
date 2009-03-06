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
#   j [--h[elp]] [--l] [--r] [--s] [regex1 ... regexn]
#                       with no args, returns full list (same as j --l)
#     regex1 ... regexn jump to the most used directory matching all masks
#     --l               show the list instead of jumping
#     --r               order by recently used instead of most used.
#     --s               shortest matching path
#
# TIPS:
#   Some handy aliases:
#     alias jl='j --l'
#     alias jr='j --r'
#     alias js='j --s'
#
# CREDITS:
#   Joel Schaerer aka joelthelion for autojump
#   Daniel Drucker aka dmd for finding bugs and making me late for lunch
j() {
 # change jfile if you already have a .j file for something else
 local jfile=$HOME/.j
 [ "$1" = "--add" ] && {
  # we're in $HOME all the time, let something else get all the good letters
  [ "$*" = "$HOME" ] && return
  shift
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
  return
 }
 # tab completion
 [ "$1" = "--complete" ] && {
  awk -v q="$2" -F"|" '
   BEGIN { split(substr(q,3),a," ") }
   { 
    if( system("test -d \"" $1 "\"") ) next
    for( i in a ) $1 !~ a[i] && $1 = ""; if( $1 ) print $1
   }
  ' $jfile 2>/dev/null
  return
 }
 local x; local out
 for x do case $x in
  --h*) echo "j [--h[elp]] [--r] [--l] [regex1 ... regexn]"; return;;
  --l)local list=1;;
  --r)local recent=r;;
  --s)local short=1;;
    *)local out="$out $x";;
 esac; shift; done
 set -- $out
 if [ ! $1 -o "$list" ]; then
  [ "$short" ] && return
  awk -v q="$*" -v t="$(date +%s)" -v r="$recent" -F"|" '
   BEGIN { f = 2; split(q,a," "); if( r ) f = 3 }
   {
    if( system("test -d \"" $1 "\"") ) next
    for( i in a ) $1 !~ a[i] && $1 = ""
    if( $1 ) if( f == 3 ) { print t - $f "\t" $1 } else print $f "\t" $1
   }
  ' $jfile 2>/dev/null | sort -n$recent
 # if we hit enter on a completion just go there
 elif [ -d "/${out#*/}" ]; then
  cd "/${out#*/}"
 # prefer case sensitive
 else
  out=$(awk -v q="$*" -v s="$short" -v r="$recent" -F"|" '
   BEGIN { split(q,a," "); if( r ) { f = 3 } else f = 2 }
   { 
    if( system("test -d \"" $1 "\"") ) next
    for( i in a ) $1 !~ a[i] && $1 = ""
    if( $1 ) {
     if( s ) {
      if( length($1) <= length(x) ) {
       x = $1
      } else if( ! x ) x = $1
     } else if( $f >= dx ) { x = $1; dx = $f }
    }
   }
   END {
    if( ! x ) {
     close(FILENAME)
     while( getline < FILENAME ) {
      if( system("test -d \"" $1 "\"") ) continue
      for( i in a ) tolower($1) !~ tolower(a[i]) && $1 = ""
      if( $1 ) {
       if( s ) {
        if( length($1) <= length(x) ) {
         x = $1
        } else if( ! x ) x = $1
       } else if( $f >= dx ) { x = $1; dx = $f }
      }
     }
    }
    if( x ) print x
   }
  ' $jfile)
  [ "$out" ] && cd "$out"
 fi
}
# tab completion for j
complete -C 'j --complete "$COMP_LINE"' j
# populate directory list. avoid clobbering other PROMPT_COMMANDs.
PROMPT_COMMAND='j --add "$(pwd -P)";'"$PROMPT_COMMAND"
