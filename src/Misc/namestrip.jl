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

const bad_chars = Dict{String,Array{UInt8,1}}(
  "File" => [0x22, 0x24, 0x2a, 0x2f, 0x3a, 0x3c, 0x3e, 0x3f, 0x40, 0x5c,
                 0x5e, 0x7c, 0x7e, 0x7f],
  "HTML" => [0x22, 0x26, 0x27, 0x3b, 0x3c, 0x3e, 0xa9, 0x7f],
  "Julia" => [0x24, 0x5c, 0x7f],
  "Markdown" => [0x21, 0x23, 0x28, 0x29, 0x2a, 0x2b, 0x2d, 0x2e, 0x5b, 0x5c, 0x5d, 0x5f, 0x60, 0x7b, 0x7d],
  "SEED" => [0x2e, 0x7f],
  "Strict" => [0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a,
               0x2b, 0x2c, 0x2d, 0x2e, 0x2f, 0x3a, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f,
               0x40, 0x5b, 0x5c, 0x5d, 0x5e, 0x60, 0x7b, 0x7c, 0x7d, 0x7e, 0x7f]
)
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
