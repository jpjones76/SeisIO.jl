@doc """
    merge!(S::SeisData, U::SeisData[, prune_only=true])

Merge channels of two SeisData structures.

    merge!(S::SeisData[, prune_only=true])

"Flatten" a SeisData structure by merging channels with identical properties.

If `prune_only=true`, the only action taken is deletion of empty and duplicate
channels; `merge!(S, U, prune_only=true)` is identical to an in-place `S+U`.
""" merge!
function merge!(S::Y; v::Integer=KW.v, purge_only::Bool=false) where Y<:GphysData
  # Required preprocessing
  prune!(S)

  # Initialize variables
  ID    = getfield(S, :id)
  NAME  = getfield(S, :name)
  LOC   = getfield(S, :loc)
  FS    = getfield(S, :fs)
  GAIN  = getfield(S, :gain)
  RESP  = getfield(S, :resp)
  UNITS = getfield(S, :units)
  SRC   = getfield(S, :src)
  MISC  = getfield(S, :misc)
  NOTES = getfield(S, :notes)
  T     = getfield(S, :t)
  X     = getfield(S, :x)

  UID = unique(getfield(S, :id))
  cnt = 0
  note_head = string(SeisIO.timestamp(), " ¦ ")
  to_delete = Array{Int64,1}(undef, 0)
  while cnt < length(UID)
    cnt = cnt + 1
    id = getindex(UID, cnt)
    GRP = findall(S.id.==id)
    SUBGRPS = get_subgroups(LOC, FS, RESP, UNITS, GRP)

    for subgrp in SUBGRPS
      dup_check!(subgrp, to_delete, T, X)
      (purge_only == true) && continue

      N     = length(subgrp)
      i1    = getindex(subgrp, 1)
      fs    = getindex(FS, i1)
      if fs == 0.0
        Ω = merge_non_ts!(S, subgrp)
        append!(to_delete, subgrp[subgrp.!=Ω])
        continue
      end
      Δ     = round(Int64, sμ/fs)
      W, Ω  = get_merge_w(Δ, subgrp, T, X)
      rest  = subgrp[subgrp.!=Ω]

      # GAIN, MISC, NAME, NOTES, SRC ==========================================
      gain  = getindex(GAIN, Ω)
      notes = getindex(NOTES, Ω)
      misc  = getindex(MISC, Ω)
      for i in rest
        scalefac = gain / getindex(GAIN, i)
        if scalefac != 1.0
          rmul!(getindex(X, i), scalefac)
          GAIN[i] = gain            # added 2020-12-03, in case merge breaks
        end
        if getindex(SRC, i) != getindex(SRC, Ω)
          push!(notes, string(note_head, "+source ¦ ", getindex(SRC, i)))
        end
        if getindex(NAME, i) != getindex(NAME, Ω)
          push!(notes, string(note_head, "alt name ¦ ", getindex(NAME, i)))
        end
        append!(notes, getindex(NOTES, i))
        merge!(misc, getindex(MISC, i))
      end
      sort!(notes)

      # Extra fields ==========================================================
      merge_ext!(S, Ω, rest)

      # T,X ===================================================================
      T_Ω, X_Ω = segment_merge(Δ, Ω, W, X)
      setindex!(X, X_Ω, Ω)
      setindex!(T, T_Ω, Ω)

      # Document it
      proc_note!(S, Ω, "merge!", string("combined channels ",
                 repr(subgrp), " (N = ", N, ") into :t, :x"))
      append!(to_delete, rest)
    end
    # Done with SUBGRPS
  end
  deleteat!(S, to_delete)
  sort!(S)
  return nothing
end

# The following must be the same (or unset) to merge:
# :loc
# :resp
# :fs         cannot be unset; not a nullable array
# :units

# The following are easily dealt with:
# :gain       can be translated with no trouble
# :misc       can call merge! method for dictionaries
# :notes      append and sort
# :name       not important, can log extra names to :notes
# :src        use most recent, log extras to :notes

function merge!(C::T1, D::T2) where {T1<:GphysChannel, T2<:GphysChannel}

  # Identical structures or empty D
  ((C == D) || isempty(D.x) || isempty(D.t)) && return nothing

  # empty C
  if (isempty(C.x) || isempty(C.t))
    ff = (T1 == T2) ? fieldnames(T1) : SeisIO.datafields
    for f in ff
      setfield!(C, f, deepcopy(getfield(D, f)))
    end
    return nothing
  end

  # partial match or exit
  m = cmatch_p!(C, D)
  (m == false) && (@warn("Critical field mismatch! Not merged!"); return nothing)

  # auto-convert T2 to T1
  if T2 != T1
    D = convert(T1, D)
  end

  note_head = string(SeisIO.timestamp(), " ¦ ")
  ttest = (endtime(C.t, C.fs) > endtime(D.t, D.fs))
  ω = ttest ? C : D
  α = ttest ? D : C

  # at this point, (:fs, :gain, :loc, :resp, :units) are known to match
  # this is stricter than merge!, which allows gain mismatches within S

  # MISC, NAME, NOTES, SRC ================================================
  if ω.src != α.src
    push!(ω.notes, string(note_head, "+source ¦ ", α.src))
  end
  if ω.name != α.name
    push!(ω.notes, string(note_head, "alt name ¦ ", α.name))
  end

  append!(C.notes, D.notes)
  sort!(C.notes)
  if ttest
    merge!(C.misc, D.misc)
  else
    C.misc = merge(D.misc, C.misc)
  end

  # Extra fields ==========================================================
  merge_ext!(ω, α)

  # T,X ===================================================================
  if C.fs == 0.0
    merge_non_ts!(C, D)
    return nothing
  end

  # Proceed only for time-series data
  subgrp = ttest ? [1, 2] : [2, 1]
  T = [ω.t, α.t]
  X = Array{FloatArray, 1}(undef, 2)
  X[1] = ω.x
  X[2] = α.x
  dup_check!(subgrp, Int64[], T, X)
  N = length(subgrp)

  # At this point, N == 1 means the same data at the same times; nothing to do
  (N == 1) && return nothing

  # on to time windows
  fs          = C.fs
  Δ           = round(Int64, sμ/fs)
  W, Ω        = get_merge_w(Δ, subgrp, T, X)
  TΩ, XΩ      = segment_merge(Δ, Ω, W, X)
  C.t = TΩ
  C.x = XΩ
  proc_note!(C, "merge!", string("combined data from a structure of type $T2"))
  return nothing
end
