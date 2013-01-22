#
#===============================================================================
#
#          FILE:  bookmarks.sh
#
#         USAGE:  Add the following line to ~/.bash :
#                   source PATH_TO_FILE/bookmarks.sh
#
#   DESCRIPTION:  DIRECTORY BOOKMARKS FOR BASH
#
#  REQUIREMENTS: Bash 4.0+ (associative arrays)
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#===============================================================================

[ ${BASH_VERSINFO[0]} -lt 4 ] && return 1       # script needs Bash 4.0+

#===============================================================================
#  GLOBAL DECLARATIONS
#===============================================================================
if [ -z "${!BBM_*}"  ] ; then
  declare -r BBM_Version='1.6'                        # script version
  declare    BBM_BOOKMARKFILE="$HOME/.bookmarks.data" # default bookmark file
  declare    BBM_MC_HOTLISTFILE="$HOME/.mc/hotlist"   # default bookmark file
  declare -r BBM_Script="BOOKMARKS FOR BASH"          # the name of this script
  declare    BBM_EXPORT_TO_VARIABLES='no'             # export bookmarks to vars
fi
declare -A BBM_BOOKMARK=()                      # bookmark list
declare -A BBM_TIMESTAMP=()                     # timestamp list
declare -A BBM_MC_HOTLIST=()                    # MC hotlist
declare -a BBM_MC_HOTLIST_ORDER=()              # MC hotlist

#===============================================================================
#  FUNCTION DEFINITIONS
#===============================================================================

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  _bookmarks_support
#   DESCRIPTION:  Read bookmark file and MC hotlist.
#    PARAMETERS:  [writefile|readfile]
#-------------------------------------------------------------------------------
_bookmarks_support ()
{
  declare    bm
  #-----------------------------------------------------------------------------
  #  write bookmark file
  #-----------------------------------------------------------------------------
  if [ "$1" = "writefile" ] ; then

    if [ -e "$BBM_BOOKMARKFILE" ] ; then        # make a backup file
      mv "$BBM_BOOKMARKFILE" "$BBM_BOOKMARKFILE"~
    fi
    for bm in ${!BBM_BOOKMARK[*]}; do           # write bookmarks
      printf "\"%s\" \"%s\" \"%s\"\n" \
             $bm "${BBM_TIMESTAMP[$bm]}" "${BBM_BOOKMARK[$bm]}"
    done > "$BBM_BOOKMARKFILE"
    return 0

  #-----------------------------------------------------------------------------
  #  read bookmark file
  #-----------------------------------------------------------------------------
  elif [ "$1" = "readfile" ] ; then

    BBM_BOOKMARK=()
    BBM_TIMESTAMP=()
    if [ -r "$BBM_BOOKMARKFILE" ] ; then
      while read ; do
        # regular bookmark entry: "bookmark" "timestamp" "path"
        if [[ "$REPLY" =~ ^\"(.+)\"\ \"(.+)\"\ \"(.+)\" ]] ; then       #"
            # directory
            BBM_BOOKMARK[${BASH_REMATCH[1]}]="${BASH_REMATCH[3]}"
            # timestamp
            BBM_TIMESTAMP["${BASH_REMATCH[1]}"]="${BASH_REMATCH[2]}"
        fi
        # delete entry: <deleted> "bookmark"
        if [[ "$REPLY" =~ ^\<deleted\>\ \"(.+)\" ]] ; then
            unset -v BBM_BOOKMARK["${BASH_REMATCH[1]}"]       # remove bookmark
            unset -v BBM_TIMESTAMP["${BASH_REMATCH[1]}"]      # remove timestamp
        fi
      done < "$BBM_BOOKMARKFILE"
      _bookmarks_support writefile              # write cleaned version
    else
      touch "$BBM_BOOKMARKFILE"                 # create a new bookmark file
    fi
    return 0

  #-----------------------------------------------------------------------------
  #  MC hotlist
  #-----------------------------------------------------------------------------
  elif [ "$1" = "mc_hotlist" ] ; then
    if [ -r "$BBM_MC_HOTLISTFILE" ] ; then
      BBM_MC_HOTLIST=()                         # MC hotlist
      BBM_MC_HOTLIST_ORDER=()                   # MC hotlist
      #-------------------------------------------------------------------------
      #  read Midnight Commander hotlist; format:
      #  ENTRY "...." URL "..."
      #-------------------------------------------------------------------------
      while read ; do
        if [[ "$REPLY" =~ ENTRY\ \"(.+)\"\ URL\ \"(.+)\" ]] ; then
          entry="${BASH_REMATCH[1]}"
          url="${BASH_REMATCH[2]}"
          BBM_MC_HOTLIST["${entry}"]="${url}"
          BBM_MC_HOTLIST_ORDER+=( "${entry}" )
        fi
      done < "$BBM_MC_HOTLISTFILE"
      return 0
    else
      printf "%s\n" \
        "No Midnight Commander directory hotlist file '$BBM_MC_HOTLISTFILE'"
      return 1
    fi

  fi

} # ----------  end of function _bookmarks_support  ----------

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  _bookmarks_export_all_to_variables
#   DESCRIPTION:  Export bookmarks to shell variables.
#    PARAMETERS:  ---
#-------------------------------------------------------------------------------
_bookmarks_export_all_to_variables ()
{
  declare bm
  for bm in "${!BBM_BOOKMARK[@]}"; do
    _bookmarks_export_to_variable "${bm}"
  done
} # ----------  end of function _bookmarks_export_all_to_variables  ----------

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  _bookmarks_export_to_variable
#   DESCRIPTION:  Export a bookmark to a shell variable.
#                 Do not overwrite an existing variable.
#    PARAMETERS:  bookmark [verbose]
#-------------------------------------------------------------------------------
_bookmarks_export_to_variable ()
{
  declare bm="$1"
  if [ -z "${BBM_BOOKMARK[$bm]}" ] ; then
    if [ -n "$2" ] ; then
      echo "$BBM_Script : '$bm' is not a bookmark"
    fi
    return 1
  fi

  declare list1='${!'${1}'*}'
  eval list1=$list1
  if [ -z "$list1" ] ; then
    eval "${bm}=\"${BBM_BOOKMARK[$bm]}\""
    eval "export ${bm}=\"${BBM_BOOKMARK[$bm]}\""
    [ -n "$2" ] && echo "$BBM_Script : exported '$bm=${BBM_BOOKMARK[$bm]}'"
  else
    list1=" ${list1} "
    declare list2="${list1/ ${1} / }"
    if [ ${#list1} -ne ${#list2} ] ; then       # don't overwrite existing var
      read -p "overwrite existing variable '$bm' (y/n) " -i 'y' answer 
      if [ "$answer" != 'y' ] ; then
        return 0
      fi
    fi
    eval "${bm}=\"${BBM_BOOKMARK[$bm]}\""
    eval "export ${bm}=\"${BBM_BOOKMARK[$bm]}\""
    [ -n "$2" ] && echo "$BBM_Script : exported '$bm=${BBM_BOOKMARK[$bm]}'"
  fi
  return 0
} # ----------  end of function _bookmarks_export_to_variable  ----------

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  _bookmarks_completion
#   DESCRIPTION:  List of bookmarks beginning with $1.
#    PARAMETERS:  ---
#-------------------------------------------------------------------------------
_bookmarks_completion ()
{
  declare bm cur
  COMPREPLY=()
  cur=${COMP_WORDS[COMP_CWORD]}
  for bm in "${!BBM_BOOKMARK[@]}"; do
    if [[ "$bm" =~ ^$cur ]] ; then        # match the beginning of the parameter
      COMPREPLY+=( "$bm" )
    fi
  done
} # ----------  end of function _bookmarks_completion  ----------

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  _hotlist_completion
#   DESCRIPTION:  List of hotlist entries beginning with $1.
#    PARAMETERS:  ---
#-------------------------------------------------------------------------------
_hotlist_completion ()
{
  declare bm cur
  if [ -r "$BBM_MC_HOTLISTFILE" ] ; then

    COMPREPLY=()
    cur=${COMP_WORDS[COMP_CWORD]}
    for bm in "${!BBM_MC_HOTLIST[@]}"; do
      if [[ "$bm" =~ ^$cur ]] ; then      # match the beginning of the parameter
        COMPREPLY+=( "${bm// /\\ }" )     # quote spaces
      fi
    done
  fi
} # ----------  end of function _hotlist_completion  ----------

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  b
#   DESCRIPTION:  Bookmark a directory.
#                 A relative path will be converted to an absolute path.
#    PARAMETERS:  [ shortcut [directory] ]
#-------------------------------------------------------------------------------
b ()
{
  declare bm="${1:-$PWD}"
  declare dir="${2:-$PWD}"
  [ "${dir:0:1}" != '/' ] && dir="$PWD/${dir}"
  if [ -n "${BBM_BOOKMARK[$bm]}" ] ; then
    read -p "$BBM_Script : overwrite existing bookmark '$bm' = '${BBM_BOOKMARK[$bm]}'  [n/y] "
    [ "$REPLY" != 'y' ] && return
  fi
  BBM_BOOKMARK[$bm]="$dir"
  BBM_TIMESTAMP[$bm]=$( date "+%F %H:%M:%S" )
  printf "\"%s\" \"%s\" \"%s\"\n" "$bm" "${BBM_TIMESTAMP[$bm]}"\
    "${BBM_BOOKMARK[$bm]}" >> "$BBM_BOOKMARKFILE"
  #
  echo "$BBM_Script : bookmark (added/changed)    '$bm' = '${BBM_BOOKMARK[$bm]}'"
  if [ $BBM_EXPORT_TO_VARIABLES = 'yes' ] ; then
    _bookmarks_export_to_variable "$bm"
  fi
} # ----------  end of function b  ----------

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  bm
#   DESCRIPTION:  resolve bookmark
#                 Usage in a Bash command : `bm bookmark` 
#    PARAMETERS:  bookmark
#       RETURNS:  resolved bookmark
#-------------------------------------------------------------------------------
bm ()
{
  if [ -n "$1" ] && [ -n "${BBM_BOOKMARK[$1]}" ] ; then
    echo "${BBM_BOOKMARK[$1]}"
  else
    echo "$BBM_Script : '$1' is not a bookmark"  >&2
  fi
} # ----------  end of function bm  ----------

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  bl
#   DESCRIPTION:  Display all bookmarks or a selection of bookmarks.
#    PARAMETERS:  [-d] [-t] [regex]
#-------------------------------------------------------------------------------
bl ()
{
  declare -a bookmarksorted=()                  # bookmarks, sorted reverse
  declare -a selection=()                       # selection (regex)
  declare    regex bm IFSsave
  declare    showtime='no'                      # show no timestamps
  declare    sortdictionary='no'                # sort order access time
  declare    option
  declare    OPTIND OPTARG                      # do not modify global variables
  declare -r OPTIONSTRING=':dt'                 # ':' no error messages
  declare -i max=10

  #-----------------------------------------------------------------------------
  #  process options
  #-----------------------------------------------------------------------------
  while getopts $OPTIONSTRING option ; do
    case $option in
      d)  sortdictionary='yes'
        ;;
      t)  showtime='yes'
        ;;
    esac    # --- end of case ---
  done
  shift $((OPTIND-1))                           # shift past options

  regex="${1:-.*}"                              # default regex: everything

  #-----------------------------------------------------------------------------
  #  sort bookmarks
  #-----------------------------------------------------------------------------
  if [ $sortdictionary = 'yes' ] ; then
    #---------------------------------------------------------------------------
    #  dictionary order
    #---------------------------------------------------------------------------
    IFSsave="$IFS"
    IFS=$'\n'                                   # sort needs lines
    bm=$( echo  "${!BBM_BOOKMARK[*]}" | sort )
    bookmarksorted=( $bm )
    IFS="$IFSsave"
  else
    #---------------------------------------------------------------------------
    #  most recently accessed bookmarks first (default)
    #---------------------------------------------------------------------------
    declare    now ts
    now=$( date "+%F %H:%M:%S" )
    now=${now//[- :]/}                          # remove non-digits

    IFSsave="$IFS"
    IFS=$'\n'                                   # sort needs lines
    bookmarksorted=( $(
      for bm in "${!BBM_TIMESTAMP[@]}"; do
        ts=${BBM_TIMESTAMP[$bm]}
        ts=${ts//[- :]/}                        # remove non-digits
        printf "%d %s\n" $((now-ts)) "$bm"
      done | sort -n
    ) )
    IFS="$IFSsave"

    for bm in ${!bookmarksorted[@]}; do
      [[ "${bookmarksorted[bm]}" =~ ^[[:digit:]]+\ (.*) ]]
      bookmarksorted[bm]="${BASH_REMATCH[1]}"
    done

  fi

  #-----------------------------------------------------------------------------
  #  select bookmarks by regular expression
  #-----------------------------------------------------------------------------
  for bm in "${bookmarksorted[@]}"; do
    if [[ "$bm" =~ ^$regex$ ]] ; then
      selection+=( "$bm" )
    fi
  done

  #-----------------------------------------------------------------------------
  #  find length of longest bookmark
  #-----------------------------------------------------------------------------
  if [ ${#selection[@]} -gt 0 ] ; then
    max=${#selection[0]}
    for bm in "${selection[@]}"; do
      if [ ${#bm} -gt $max ] ; then
        max=${#bm}
      fi
    done
  fi

  #-----------------------------------------------------------------------------
  #  print the list
  #-----------------------------------------------------------------------------
  if [ $showtime = 'no' ] ; then
    printf "  %-${max}s  %s   ( %d/%d entries )\n" "BOOKMARK" "DIRECTORY" \
      ${#selection[@]}  ${#BBM_BOOKMARK[@]}
    printf "%s"   "----------------------------------------"
    printf "%s\n" "----------------------------------------"
    for bm in "${selection[@]}"; do
      printf "  %-${max}s  '%s'\n" "$bm" "${BBM_BOOKMARK[$bm]}"
    done
  else
    printf "  %-19s  %-${max}s  %s   ( %d/%d entries )\n" \
      "LAST ACCESS" "BOOKMARK" "DIRECTORY" ${#selection[@]}  ${#BBM_BOOKMARK[@]}
    printf "%s"   "----------------------------------------"
    printf "%s\n" "----------------------------------------"
    for bm in "${selection[@]}"; do
      printf "  %s  %-${max}s  '%s'\n" \
      "${BBM_TIMESTAMP[$bm]:0:19}" "$bm" "${BBM_BOOKMARK[$bm]}"
    done
  fi
  printf "\n"

} # ----------  end of function bl  ----------

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  g
#   DESCRIPTION:  Go to a bookmark or to the home directory.
#                 For bookmarks used by 'cd' the access time is recorded.
#    PARAMETERS:  [bookmark]
#-------------------------------------------------------------------------------
g ()
{
  case $# in
    0)  cd "$HOME"
      ;;

    *)
      if [ -n "${BBM_BOOKMARK[$1]}" ] ; then
        BBM_TIMESTAMP[$1]=$( date "+%F %H:%M:%S" )
        printf "\"%s\" \"%s\" \"%s\"\n" "$1" "${BBM_TIMESTAMP[$1]}" \
        "${BBM_BOOKMARK[$1]}" >> "$BBM_BOOKMARKFILE"
        cd "${BBM_BOOKMARK[$1]}"
      else
        printf "No bookmark '%s'. Still in '%s'.\n" "${1}" "$PWD"
      fi
      ;;

  esac    # --- end of case ---
} # ----------  end of function g  ----------

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  p
#   DESCRIPTION:  Push bookmark onto dir stack.
#    PARAMETERS:  [bookmark]
#-------------------------------------------------------------------------------
p ()
{
  [ $# -eq 0 ] && return
  if [ -n "${BBM_BOOKMARK[$1]}" ] ; then
    BBM_TIMESTAMP[$1]=$( date "+%F %H:%M:%S" )
    printf "\"%s\" \"%s\" \"%s\"\n" "$1" "${BBM_TIMESTAMP[$1]}" \
    "${BBM_BOOKMARK[$1]}" >> "$BBM_BOOKMARKFILE"
    pushd "${BBM_BOOKMARK[$1]}" > /dev/null && dirs -p
  else
    printf "Bookmark '$1' does not exist. Still in '$PWD'.\n"
  fi
} # ----------  end of function p  ----------

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  r
#   DESCRIPTION:  Remove a saved bookmark.
#    PARAMETERS:  [bookmark|regex]
#-------------------------------------------------------------------------------
r ()
{
  declare    regex="${1:-.*}"                   # default regex: everything
  declare -i bmarks=${#BBM_BOOKMARK[@]}
  declare -a selection=()
  declare    bm
  #-----------------------------------------------------------------------------
  #  select bookmarks by regular expression
  #-----------------------------------------------------------------------------
  for bm in "${!BBM_BOOKMARK[@]}"; do
    if [[ $bm =~ ^${regex}$ ]] ; then             # always match complete words
      selection+=( "$bm" )
    fi
  done

  if [ ${#selection[@]} -eq 0 ] ; then
    printf "\nNo bookmark selected. Regex expanded to '%s'.\n" "$regex"
    printf "%s\n" "Try again with regex quoted?"
    return
  fi

  printf " %d/%d bookmarks selected:\n" ${#selection[@]} $bmarks
  for bm in "${selection[@]}"; do
    printf "   %-8s   '%s'\n" "$bm" "${BBM_BOOKMARK[$bm]}"
  done

  read  -p 'Delete selection [n/y]:'
  [ "$REPLY" != 'y' ] && return
  for bm in "${selection[@]}"; do
    unset -v BBM_BOOKMARK["$bm"]                              # remove bookmark
    unset -v BBM_TIMESTAMP["$bm"]                             # remove timestamp
    printf "<deleted> \"%s\"\n" "$bm" >> "$BBM_BOOKMARKFILE"  # mark as deleted
  done

  printf " %d bookmark(s) deleted\n" $(( bmarks - ${#BBM_BOOKMARK[@]} ))
} # ----------  end of function r  ----------

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  hl
#   DESCRIPTION:  Display the Midnight Commander hotlist.
#    PARAMETERS:  [-d] [regex]
#-------------------------------------------------------------------------------
hl ()
{
  if [ -r "$BBM_MC_HOTLISTFILE" ] ; then
    declare -a bookmarksorted=()                # bookmarks, sorted reverse
    declare -a selection=()                     # selection (regex)
    declare    regex bm IFSsave
    declare    sortdictionary='no'              # sort order access time
    declare    option
    declare    OPTIND OPTARG                    # do not modify global variables
    declare -r OPTIONSTRING=':d'                # ':' no error messages
    declare -i max=10

    #---------------------------------------------------------------------------
    #  process options
    #---------------------------------------------------------------------------
    while getopts $OPTIONSTRING option ; do
      case $option in
        d)  sortdictionary='yes'
          ;;
      esac                                      # --- end of case ---
    done
    shift $((OPTIND-1))                         # shift past options

    regex="${1:-.*}"                            # default regex: everything

    #---------------------------------------------------------------------------
    #  sort bookmarks
    #---------------------------------------------------------------------------
    if [ $sortdictionary = 'yes' ] ; then
      #-------------------------------------------------------------------------
      #  dictionary order
      #-------------------------------------------------------------------------
      IFSsave="$IFS"
      IFS=$'\n'                                 # sort needs lines
      bm=$( echo  "${!BBM_MC_HOTLIST[*]}" | sort )
      bookmarksorted=( $bm )
      IFS="$IFSsave"
    else
      #-------------------------------------------------------------------------
      #  Midnight Commander sort order
      #-------------------------------------------------------------------------
      bookmarksorted=( "${BBM_MC_HOTLIST_ORDER[@]}" )
    fi

    #---------------------------------------------------------------------------
    #  select bookmarks by regular expression
    #---------------------------------------------------------------------------
    for bm in "${bookmarksorted[@]}"; do
      if [[ "$bm" =~ ^$regex$ ]] ; then
        selection+=( "$bm" )
      fi
    done

    #---------------------------------------------------------------------------
    #  find length of longest bookmark
    #---------------------------------------------------------------------------
    if [ ${#selection[@]} -gt 0 ] ; then
      max=${#selection[0]}
      for bm in "${selection[@]}"; do
        if [ ${#bm} -gt $max ] ; then
          max=${#bm}
        fi
      done
    fi

    #---------------------------------------------------------------------------
    #  print the list
    #---------------------------------------------------------------------------
    printf "\n ===== Midnight Commander directory hotlist =====\n"
    printf "\n  %-${max}s %s  ( %d/%d entries )\n"\
      "BOOKMARK"  "DIRECTORY"  ${#selection[@]} ${#BBM_MC_HOTLIST[@]}
    printf "%s"   " ---------------------------------------"
    printf "%s\n" "----------------------------------------"
    for bm in "${selection[@]}"; do
      printf "  %-${max}s '%s'\n"  "$bm" "${BBM_MC_HOTLIST[$bm]}"
    done
    printf "\n"
  else
    printf "Midnight Commander hotlist '$BBM_MC_HOTLISTFILE' not available.\n"
  fi
} # ----------  end of function hl  ----------

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  gh
#   DESCRIPTION:  Go to a Midnight Commander hotlist entry or to the home
#                 directory. Use ssh for a SHell filesystem link.
#    PARAMETERS:  [bookmark]
#-------------------------------------------------------------------------------
gh ()
{
  case $# in
    0)  cd "$HOME"
      ;;

    *)
      if [ -r "$BBM_MC_HOTLISTFILE" ] ; then
        if [ -n "${BBM_MC_HOTLIST[$1]}" ] ; then
          declare target="${BBM_MC_HOTLIST[$1]}"
          if [[ "$target" =~ ^/#sh:([^/]+) ]] ; then
            ssh "${BASH_REMATCH[1]}"
          else
            cd "$target"
          fi
        else
          printf "No bookmark '%s'. Still in '%s'.\n" "${1}" "$PWD"
        fi
      else
        printf "Midnight Commander hotlist '$BBM_MC_HOTLISTFILE' not available.\n"
      fi
      ;;

  esac    # --- end of case ---

} # ----------  end of function gh  ----------

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  bookmarks
#   DESCRIPTION:  bookmarks help / change bookmark file
#    PARAMETERS:  [-h] [-b file]
#-------------------------------------------------------------------------------
bookmarks ()
{
  declare usage="
  DIRECTORY BOOKMARKS FOR BASH (version $BBM_Version)

  b  [bookmark [dir]]      : bookmark a directory
                               <no option>   bookmark the current directory
                               bookmark      use bookmark for current directory
                               bookmark dir  use bookmark for given directory
  bl [-d][-t][regex]       : show the bookmark list (tab compl.)
                               -d            dictionary order
                               -t            show time stamps
                               regex         list bookmarks matching regex
  bm bookmark              : resolve a bookmark (tab compl.)
  g  [bookmark]            : go to a bookmark or named directory (tab compl.)
                               <no option>   go to the home directory
                               bookmark      go to the bookmarked directory
  p  [bookmark]            : push bookmark / directory onto dir stack (tab compl.)
                               bookmark      pushd bookmarked directory
  r  [bookmark|regex]      : remove a saved bookmark(s) (tab compl.)
                               bookmark      remove bookmark
                               regex         remove bookmarks matching regex

  gh [bookmark]            : go to a Midnight Commander hotlist entry (tab compl.)
                             use ssh for a SHell filesystem link
                               <no option>   go to the home directory
                               bookmark      go to the bookmarked directory
  hl [-d][regex]           : Midnight Commander directory hotlist (tab compl.)
                               -d            dictionary order
                               regex         list bookmarks matching regex

  bookmarks [-h]           : this help message
  bookmarks  -b bmfile     : use bookmark file bmfile
  bookmarks  -i            : import Midnight Commander hotlist
  bookmarks  -r [bash|mc]  : reread Bash/MC bookmark file
  bookmarks  -v            : display the version of this script
  bookmarks  -e [bookmark] : export a shell variable from every bookmark
                           : export a shell variable from given bookmark

  The actual bookmark file is '$BBM_BOOKMARKFILE'.
  Reguluar expressions are explained in  manual regex(7).
  "

  declare    option
  declare    OPTIND OPTARG                      # do not modify global variables
  declare -r OPTIONSTRING=':hvb:eir'
  declare    bm timestamp
  declare -i count=0

  if [ $# -eq 0 ] ; then
    printf "%s\n" "$usage"
    return 0
  fi

  #-----------------------------------------------------------------------------
  #  process options
  #-----------------------------------------------------------------------------
  while getopts $OPTIONSTRING option ; do
    case $option in

      b)  BBM_BOOKMARKFILE="$OPTARG"            # read a bookmark file
        _bookmarks_support readfile
        return 0
        ;;

        #-------------------------------------------------------------------------------
        #  export bookmarks to variables
        #-------------------------------------------------------------------------------
        e) if [ -n "$2" ] ; then
            _bookmarks_export_to_variable "$2" 'verbose'
          else
            BBM_EXPORT_TO_VARIABLES='yes'
            _bookmarks_export_all_to_variables
          fi
          return 0
      ;;

      h)  printf "%s\n" "$usage"                # print usage message
        return 0
        ;;

      v)  printf "%s version %s\n" "$BBM_Script" "$BBM_Version"
        return 0
        ;;

        #-----------------------------------------------------------------------
        #  import the Midnight Commander directory hotlist
        #-----------------------------------------------------------------------
      i)
        _bookmarks_support mc_hotlist           # renew the hotlist

        declare bm1 directory
        declare now=$( date "+%F %H:%M:%S" )

        for bm in "${!BBM_MC_HOTLIST[@]}"; do

          # look for duplicate bookmark
          if [ -n "${BBM_BOOKMARK[$bm]}" ] ; then
            read -p "overwrite bookmark '$bm' = '${BBM_BOOKMARK[$bm]}'  [n/y] "
            [ -z "$REPLY" -o "$REPLY" != 'y' ] && continue
          fi

          # look for duplicate target
          directory=''
          for bm1 in "${!BBM_BOOKMARK[@]}"; do
            if [ "${BBM_BOOKMARK[$bm1]}" == "${BBM_MC_HOTLIST[$bm]}" ] ; then
              directory="${BBM_BOOKMARK[$bm1]}"
              echo "'$directory'"
              break
            fi
          done
          if [ -n "${directory}" ] ; then
            read -p "MC bookmark '$bm' and bookmark '$bm1' have the same target '$directory'. Overwrite [n/y] :"
            [ -z "$REPLY" -o "$REPLY" != 'y' ] && continue
          fi

          # add entry
          BBM_BOOKMARK[$bm]="${BBM_MC_HOTLIST[$bm]}"
          BBM_TIMESTAMP[$bm]="$now"
          ((count++))
        done
        _bookmarks_support writefile            # save imports
        printf "%d bookmarks added\n" ${count}
        return 0
        ;;

        #-----------------------------------------------------------------------
        #  reread bookmark files
        #-----------------------------------------------------------------------
      r)
        if [ -z "$2" ] ; then
          echo "usage: bookmarks [bash|mc]"
          return 1
        fi
        case "$2" in
          bash)
            _bookmarks_support readfile         # reread actual bookmark file
            [ $? -eq 0 ] && printf "Bookmark file '%s' read.\n" "$BBM_BOOKMARKFILE"
            ;;

          mc)
            _bookmarks_support mc_hotlist       # renew the MC directory hotlist
            [ $? -eq 0 ] && printf "MC dir hotlist '%s' read.\n" "$BBM_MC_HOTLISTFILE"
            ;;

          *) echo "option -r : wrong argument"
            return 1
            ;;

        esac    # --- end of case ---
        ;;

    esac    # --- end of case ---
  done
  shift $((OPTIND-1))                           # shift past options

  return 0
} # ----------  end of function bookmarks  ----------

#===============================================================================
#  MAIN SCRIPT
#===============================================================================
_bookmarks_support readfile                     # read the bookmark file
if [ -r "$BBM_MC_HOTLISTFILE" ] ; then
_bookmarks_support mc_hotlist                   # renew the MC directory hotlist
fi

complete -F _bookmarks_completion bl            # tab completion command bm
complete -F _bookmarks_completion bm            # tab completion command bm
complete -F _bookmarks_completion g             # tab completion command g
complete -F _bookmarks_completion p             # tab completion command p
complete -F _bookmarks_completion r             # tab completion command r

complete -F _hotlist_completion   gh            # mc : tab completion command gh
complete -F _hotlist_completion   hl            # mc : tab completion command gh

