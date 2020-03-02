function hdr_hash(S::SeisData, i::Int64)
  h = hash(zero(UInt64))
  for f in (:id, :name, :loc, :fs, :gain, :resp, :units)
    h = hash(getfield(S, f)[i], h)
  end
  return h
end

function track_hdr!(S::GphysData, hashes::Array{UInt64, 1}, fmt::String, fname::String, opts::String)
  to_track = Array{Int64, 1}(undef, 0)

  # Add new channels
  L = length(hashes)
  if S.n > L
    append!(hashes, zeros(UInt64, S.n-L))
  end

  # Check existing channels
  for i in 1:S.n
    if hdr_hash(S, i) != hashes[i]
      push!(to_track, i)
    end
  end

  # note new meta source in to_track
  note!(S, to_track, string( "+meta ¦ read_meta!(S, \"",
                            fmt, "\", \"",
                            fname, "\", ",
                            opts) )
  return nothing
end
