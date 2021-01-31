@doc (@doc NodalData)
mutable struct NodalChannel <: GphysChannel
  ox::Float64                         # origin x
  oy::Float64                         # origin y
  oz::Float64                         # origin z
  id::String                          # id
  name::String                        # name
  loc::InstrumentPosition             # loc
  fs::Float64                         # fs
  gain::Float64                       # gain
  resp::InstrumentResponse            # resp
  units::String                       # units
  src::String                         # src
  misc::Dict{String,Any}              # misc
  notes::Array{String,1}              # notes
  t::Array{Int64,2}                   # time
  x::FloatArray                       # data

  function NodalChannel()
    return new(
                default_fs, default_fs, default_fs,
                "",
                "",
                NodalLoc(),
                default_fs,
                default_gain,
                PZResp(),
                "",
                "",
                Dict{String,Any}(),
                Array{String,1}(undef,0),
                Array{Int64,2}(undef,0,2),
                Array{Float32,1}(undef,0)
              )
  end

  function NodalChannel(
            ox::Float64,
            oy::Float64,
            oz::Float64,
            id::String                          , # id
            name::String                        , # name
            loc::InstrumentPosition             , # loc
            fs::Float64                         , # fs
            gain::Float64                       , # gain
            resp::InstrumentResponse            , # resp
            units::String                       , # units
            src::String                         , # src
            misc::Dict{String,Any}              , # misc
            notes::Array{String,1}              , # notes
            t::Array{Int64,2}                   , # time
            x::FloatArray
            )

    return new(ox, oy, oz, id, name, loc, fs, gain, resp, units, src, misc, notes, t, x)
  end
end

function sizeof(S::NodalChannel)
  s = 120
  for f in nodalfields
    v = getfield(S, f)
    s += sizeof(v)
    if f == :notes
      if !isempty(v)
        s += sum([sizeof(j) for j in v])
      end
    elseif f == :misc
      k = collect(keys(v))
      s += sizeof(k) + 64 + sum([sizeof(j) for j in k])
      for p in values(v)
        s += sizeof(p)
        if typeof(p) == Array{String,1}
          s += sum([sizeof(j) for j in p])
        end
      end
    end
  end
  return s
end

function getindex(S::NodalData, j::Int)
  C = NodalChannel()
  [setfield!(C, f, getfield(S,f)[j]) for f in nodalfields]
  C.x = copy(S.data[:,j])
  return C
end

function setindex!(S::NodalData, C::NodalChannel, j::Int)
  [(getfield(S, f))[j] = getfield(C, f) for f in nodalfields]
  S.data[:,j] .= C.x
  S.x[j] = view(S.data, :, j)
  return nothing
end

function isempty(C::NodalChannel)
  q::Bool = C.gain == default_gain
  for f in (:ox, :oy, :oz, :fs)
    q = min(q, getfield(C, f) == default_fs)
    (q == false) && return q
  end
  for f in (:id, :loc, :misc, :name, :notes, :resp, :src, :units, :t, :x)
    q = min(q, isempty(getfield(C, f)))
    (q == false) && return q
  end
  return q
end

function push!(S::NodalData, C::NodalChannel)
 for f in nodalfields
   push!(getfield(S, f), getfield(C, f))
 end
 S.data = hcat(S.data, C.x)
 S.n += 1
 resize!(S.x, S.n+1)
 S.x[S.n] = view(S.data, :, S.n)
 return nothing
end

function write(io::IO, S::NodalChannel)
  write(io, S.ox)                                                     # ox
  write(io, S.oy)                                                     # oy
  write(io, S.oz)                                                     # oz
  write(io, Int64(sizeof(S.id)))
  write(io, S.id)                                                     # id
  write(io, Int64(sizeof(S.name)))
  write(io, S.name)                                                   # name
  write(io, loctyp2code(S.loc))
  write(io, S.loc)                                                    # loc
  write(io, S.fs)                                                     # fs
  write(io, S.gain)                                                   # gain
  write(io, resptyp2code(S.resp))
  write(io, S.resp)                                                   # resp
  write(io, Int64(sizeof(S.units)))
  write(io, S.units)                                                  # units
  write(io, Int64(sizeof(S.src)))
  write(io, S.src)                                                    # src
  write_misc(io, S.misc)                                              # misc
  write_string_vec(io, S.notes)                                       # notes
  write(io, Int64(size(S.t,1)))
  write(io, S.t)                                                      # t
  write(io, typ2code(eltype(S.x)))
  write(io, Int64(length(S.x)))
  write(io, S.x)                                                      # x
  return nothing
end

read(io::IO, ::Type{NodalChannel}) = NodalChannel(
  fastread(io, Float64),                                                # ox
  fastread(io, Float64),                                                # oy
  fastread(io, Float64),                                                # oz
  String(fastread(io, fastread(io, Int64))),                            # id
  String(fastread(io, fastread(io, Int64))),                            # name
  read(io, code2loctyp(fastread(io))),                                  # loc
  fastread(io, Float64),                                                # fs
  fastread(io, Float64),                                                # gain
  read(io, code2resptyp(fastread(io))),                                 # resp
  String(fastread(io, fastread(io, Int64))),                            # units
  String(fastread(io, fastread(io, Int64))),                            # src
  read_misc(io, getfield(BUF, :buf)),                                   # misc
  read_string_vec(io, getfield(BUF, :buf)),                             # notes
  read!(io, Array{Int64, 2}(undef, fastread(io, Int64), 2)),              # t
  read!(io, Array{code2typ(read(io, UInt8)), 1}(undef, read(io, Int64))), # x
  )
