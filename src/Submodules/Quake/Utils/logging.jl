function fwrite_note_quake!(C::Union{SeisHdr, SeisSrc}, method::String, fname::String, opts::String)
  wstr = string(timestamp(), " ¦ write ¦ ", method, "(H", opts, ") ¦ wrote to file ", fname)
  push!(C.notes, wstr)
  return nothing
end
