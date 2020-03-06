function fread_note!(S::GphysData, N::Array{Int64,1}, method::String, fmt::String, filestr::String, opts::String)
  src_str = string(timestamp(), " ¦ +source ¦ ", method, "(S, \"", fmt, "\", \"", filestr, "\", ", opts, ")" )
  for i in N
    push!(S.notes[i], src_str)
  end
  return nothing
end

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

proc_note!(S::GphysData, nn::Array{Int64, 1}, method::String, desc::String) = note!(S, nn, string("processing ¦ ", method, " ¦ ", desc))

proc_note!(S::GphysData, i::Int64, method::String, desc::String) = note!(S, i, string("processing ¦ ", method, " ¦ ", desc))

proc_note!(C::GphysChannel, method::String, desc::String) = note!(C, string("processing ¦ ", method, " ¦ ", desc))
