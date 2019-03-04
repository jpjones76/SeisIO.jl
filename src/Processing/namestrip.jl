export namestrip, namestrip!

#= Strips chars below 0x20 plus these:
# "Filenames" => ['<', '>', ':', '\"', '/', '\\', '|', '?', '*', '^', '$', '@',
                  '~', '\x7f']
# "SEED" => ['.', '\x7f']  # the period is the SEED field separator
# "HTML" => ['"', '', '&', ';', '<', '>' , '©', '\x7f']
# Markdown => ['!', '#', '(', ')', '*', '+', '-', '.', '[', '\\', ']', '_', '`', '{', '}']
# "Safe" => ['!', '"', '#', '\$', '%', '&', '\'', '*', '.', '/', ':', ';', '<',
             '>', '?', '@', '\\', '^', '{', '|', '}', '~', '©', '\x7f']
# "Julia" => ['\$', '\\', '\x7f']
# "Strict" => [' ', '!', '"', '#', '$', '%', '&', '\'', '(', ')', '*', '+', ',',
              '-', '.', '/', ':', ';', '<', '=', '>', '?', '@', '\\', '^', '{',
              '|', '}', '~', '\x7f']
=#

"""
    namestrip(s::String; convention::String="File")

Remove bad characters from S. Specify one of the following conventions:

* "File" => ['<', '>', ':', '\"', '/', '\\', '|', '?', '*', '^', '\$', '@', '~', '\x7f']
* "HTML" => ['"', '', '&', ';', '<', '>' , '©', '\x7f']
* "Julia" => ['\$', '\\', '\x7f']
* "Markdown" => ['!', '#', '(', ')', '*', '+', '-', '.', '[', '\\', ']', '_', '`', '{', '}']
* "SEED" => ['.', '\x7f']
* "Strict" => [' ', '!', '"', '#', '\$', '%', '&', '\'', '(', ')', '*', '+', ',', '-', '.', '/', ':', ';', '<', '=', '>', '?', '@', '\\', '^', '{', '|', '}', '~', '\x7f']

"""
function namestrip(str::String, convention::String="File")
  chars = UInt8.(codeunits(str))
  deleteat!(chars, chars.<0x20)   # strip non-printing ASCII
  if haskey(bad_chars, convention)
    deleteat!(chars, [c in bad_chars[convention] for c in chars])
  else
    warn("Invalid bad character list; only removed 0x00-0x20.")
  end
  return String(chars)
end
namestrip!(S::SeisData) = (for (i,name) in enumerate(S.name); s = namestrip(name); S.name[i]=s; end)
