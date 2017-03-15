"""
  `seisfscan(fstr::String, id::String, s=t0, t=t1)`

Scan index of SeisIO files matching string `fstr` for data from channel `id` between `t0` and `t1`. Times should be ∈ Union{Real,DateTime,String}.

See also: `parsetimewin`
"""
function seisfscan(fstr::String, ids::Array{String,1}; s=(-62167219200)::Real, t=253402257599::Real)
  J = length(ids)

  D = Dict{String,Array{String,1}}()
  files = SeisIO.ls(fstr)
  isempty(files) && return D
  F = length(files)

  (d0,d1) = parsetimewin(s,t)
  s = d2u(Dates.DateTime(d0))
  t = d2u(Dates.DateTime(d1))
  ts = round(Int64, min(s,t)*1000000)
  te = round(Int64, max(s,t)*1000000)

  # Each ID gets a key, whose value is an array of files that match the key
  for id in ids
    D[id] = Array{String,1}()
  end

  # number_of_files (F) x number_of_ids (J) where each entry is array(num_of_records_in_file)

  K = Array{BitArray{1}}(J)
  [K[j] = falses(1) for j = 1:J]
  for f = 1:1:F
    # Open the file
    io = open(files[f], "r")
    seek(io, position(seekend(io))-24)
    (x,y,z) = read(io, Int64, 3)
    seek(io, x)

    # Get list of IDs in each record
    ID = split(String(read(io, UInt8, y-x)), '\n', keep=true)
    L = length(ID)
    N = zeros(Int64, L)
    [K[j] = falses(L) for j = 1:J]
    M = zeros(Int64, L, J)

    # Loop over each record's IDs to check for matches
    for i = 1:1:L
      fids = split(ID[i], '\0', keep=true)
      N[i] = length(fids)
      for (j,id) in enumerate(ids)
        n = findfirst(fids.==id)
        if n > 0
          M[i,j] = n
          K[j][i] = true
        end
      end
    end
    if (s > -62167219200|| t < 253402257599) && maximum([maximum(K[j]) for j = 1:1:J]) == true

      # Loop over each record to check start time
      for i = 1:1:L
        for j = 1:length(ids)
          if M[i,j] > 0
            seek(io, y + 8*(M[i,j]-1))
            if read(io, Int64) > te
              K[j][i] = false
              M[i,j] = 0
            end
          end
        end
        y += 8*N[i]
      end

      # Loop over each record to check end time
      tf = maximum([maximum(K[j]) for j = 1:1:J])
      if tf == true
        for i = 1:1:L
          for j = 1:length(ids)
            if M[i,j] > 0
              seek(io, z + 8*(M[i,j]-1))
              (ts > read(io, Int64)) && (K[j][i] = false)
            end
          end
          z += 8*N[i]
        end
      end
    end
    close(io)

    # For all K[f,j] : maximum(K[f,j][i]) == true, append the filename and indices to D[id]
    for (j, id) in enumerate(ids)
      if maximum(K[j]) == true
        push!(D[id], files[f] * "," * strip(string(find(K[j].==true)),[']','[']))
      end
    end
  end

  return D
end
