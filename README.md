BOOKMARKS FOR THE BASH
------------------------------------------------------------------------------

The file bookmarks.sh provides a bookmark management system for the Bash
version 4.0+.  To use it add the following line to   '~/.bash' and start a new
shell:

 source <PATH_TO_FILE>/bookmarks.sh

The automatically generated default bookmark file is '~/.bookmarks.data'.

The following commands are now available (if there are no conflicts with
previously defined commands with the same name):

  b  [bookmark [dir]]      :  bookmark a directory
                                <no option>   bookmark the current directory
                                bookmark      use bookmark for current directory
                                bookmark dir  use bookmark for given directory
  bl [-d][-t][regex]       :  show the bookmark list (tab compl.)
                                -d           dictionary order
                                -t           show time stamps
                                regex        list bookmarks matching regex
  bm bookmark              : resolve a bookmark (tab compl.)
  g  [bookmark]            :  go to a bookmark or named directory (tab compl.)
                                <no option>   go to the home directory
                                bookmark      go to the bookmarked directory
  p  [bookmark]            :  push bookmark / directory onto dir stack (tab compl.)
                                bookmark     pushd bookmarked directory
  r  [bookmark|regex]      :  remove a saved bookmark(s) (tab compl.)
                                bookmark     remove bookmark
                                regex        remove bookmarks matching regex

  gh [bookmark]            :  go to a Midnight Commander hotlist entry (tab compl.)
                              use ssh for a SHell filesystem link
                                <no option>   go to the home directory
                                bookmark      go to the bookmarked directory
  hl [-d][regex]           :  Midnight Commander directory hotlist (tab compl.)
                                -d           dictionary order
                                regex        list bookmarks matching regex

  bookmarks [-h]           :  this help message
  bookmarks  -b bmfile     :  use bookmark file bmfile
  bookmarks  -i            :  import Midnight Commander hotlist
  bookmarks  -r [bash|mc]  :  reread Bash/MC bookmark file
  bookmarks  -v            :  display the version of this script
  bookmarks  -e [bookmark] : export a shell variable from every bookmark
                           : export a shell variable from given bookmark

REGEX
-----
The commands bl, r, and hl can take a regular expression to specify a pattern.
The regular expression flavor used is described im the manual regex(7). Keep in
mind that command line parameters will be subjected to parameter expansion. In
doubt the regex has to be quoted. The regex supplied will be evaluated between
the two anchors ^ and $ (beginning of the line/end of the line).  A few
examples for the r-command:

  r  test2             remove bookmark 'test2'
  r  "a.*"             all bookmarks starting with 'a'
  r  ".*[0-9]$"        all bookmarks ending with a digit
  r  ...               all bookmarks with length 3
  r  ".*a.*"           all bookmarks with one or more 'a' in its name
  r  ".*x{2,}.*"       all bookmarks with 2 or more consecutive letters 'x'

SHELL VARIABLES
---------------
The command 

 bookmark -e 

exports a shell variable from every existing and new bookmark.  Add this line
to ~/.bashrc to use this feature permanently. For the bookmark

 vm                   '/home/vmware.shared-folders'

the variable vm will be exported. An already existing variable will not be
overwritten. The variable can be used with shell commands, e.g.

 diff ./file $vm/file

To export only one variable use e.g.

 bookmark -e vm

RESOLVE A BOOKMARK
------------------
To occasionally resolve a bookmark without exporting a variable use bm:

 diff ./file `bm vm`/file

CREDIT
------
This work was inspired by bashDirB by Ira Chayut (http://www.dirb.info/bashDirB).
This is a fork of Dr. Fritz Mehner (fgm)'s work http://lug.fh-swf.de/shell/

