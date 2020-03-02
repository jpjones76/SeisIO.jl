function fread_note!(S::GphysData, N::Array{Int64,1}, method::String, fmt::String, filestr::String, opts::String)
  src_str = string(timestamp(), " ¦ +source ¦ ", method, "(S, \"", fmt, "\", \"", filestr, "\", ", opts, ")" )
  for i in N
    push!(S.notes[i], src_str)
  end
  return nothing
end

# what is this?
#
# function mread_note!(S::GphysData, N::Array{Int64,1}, method::String, fmt::String, files::Array{String, 1}, opts::String)
#   for fname in files
#     note!(S, N, string( "+meta ¦ read_meta!(S, ", fmt, ", ", fname, ", ",
#                           "msr=", msr,  ", ",
#                           "s=\"", s,  "\", ",
#                           "t=\"", t,  "\", ",
#                           "units=", units, ", ",
#                           "v=", KW.v, ")" ) )
#   end
#   return nothing
# end

# Five arguments: S, N, method, fname, opts
function fwrite_note!(S::GphysData, i::Int64, method::String, fname::String, opts::String)
  wstr = string(timestamp(), " ¦ write ¦ ", method, "(S", opts, ") ¦ wrote to file ", fname)
  push!(S.notes[i], wstr)
  return nothing
end

function fwrite_note!(C::GphysChannel, method::String, fname::String, opts::String)
  wstr = string(timestamp(), " ¦ write ¦ ", method, "(C", opts, ") ¦ wrote to file ", fname)
  push!(C.notes, wstr)
  return nothing
end
