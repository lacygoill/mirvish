vim9script noclear

# Do *not* use `:setf`.{{{
#
# If you ask  for the contents of  a directory whose name ends  with `.vim`, the
# path to the `fex` buffer will probably end with `.vim` too.
# As a result, the buffer will be detected as a Vim buffer.
# We need to make sure that the filetype will be correctly reset.
#}}}
au BufRead,BufNewFile /tmp/*/fex* set filetype=fex
