export mseis!

function SeisData(U...)
  S = SeisData()
  for i = 1:length(U)
    Y = getindex(U,i)
    if typeof(Y) == SeisChannel
      push!(S, Y)
    elseif typeof(Y) <: GphysChannel
        push!(S, convert(SeisChannel, Y))
    elseif typeof(Y) == SeisData
      append!(S, Y)
    elseif typeof(Y) <: GphysData
      append!(S, convert(SeisData, Y))
    elseif typeof(Y) == SeisEvent
      append!(S, convert(SeisData, getfield(Y, :data)))
    else
      @warn(string("Tried to join incompatible type into SeisData at arg ", i, "; skipped."))
    end
  end
  return S
end

"""
    mseis!(S::SeisData, U...)

Merge multiple SeisData structures at once. The first argument (merge target)
must be a SeisData structure. Subsequent structures can be any type T <: Union{GphysData, GphysChannel, SeisEvent}.

    mseis!(C::GphysChannel, U...)

Merge all channels in U that match channel C into object C. To be merged, a
channel must match on fields `:id`, `:fs`, `:loc`, `:resp`, `:units`.

See also: `merge!`
"""
function mseis!(S1::SeisData, S...)
  U = Union{GphysData, GphysChannel, SeisEvent}
  L = Int64(length(S))
  (L == 0) && return
  (typeof(S1) == SeisData) || error("Target must be type SeisData!")
  for i in 1:L
    T = typeof(getindex(S, i))
    if (T <: U) == false
      @warn(string("Object of incompatible type passed to mseis! at ", i+1, "; skipped!"))
      continue
    end
    if T == SeisData
      append!(S1, getindex(S, i))
    elseif T == EventTraceData
      append!(S1, convert(SeisData, getindex(S, i)))
    elseif T == SeisChannel
      append!(S1, SeisData(getindex(S, i)))
    elseif T == EventChannel
      append!(S1, SeisData(convert(SeisChannel, getindex(S, i))))
    elseif T == SeisEvent
      append!(S1, convert(SeisData, getfield(getindex(S, i), :data)))
    end
  end
  merge!(S1)
  return S1
end

function mseis!(C::Y, S...) where Y<:GphysChannel
  U = Union{GphysData, GphysChannel, SeisEvent}
  for i in 1:length(S)
    X = S[i]
    T = typeof(X)

    # Only merge compatible types
    if (T <: U) == false
      @warn(string("Object of incompatible type passed to mchan at ", i+1, "; skipped!"))
      continue
    end

    # Only call merge_chan on channels with matching ID
    if T <: GphysChannel
      if channel_match(C, X, use_gain=false)
        merge!(C, X)
      end
    elseif T <: GphysData
      ID = getfield(X, :id)
      for i in 1:X.n
        D = getindex(X, i)
        if channel_match(C, D, use_gain=false)
          merge!(C, D)
        end
      end
    elseif T == SeisEvent
      X = X.data
      for i in 1:X.n
        D = getindex(X, i)
        if channel_match(C, D, use_gain=false)
          merge!(C, D)
        end
      end
    end
  end
  return nothing
end
