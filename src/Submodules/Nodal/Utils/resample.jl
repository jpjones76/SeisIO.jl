function nodal_resample(x::AbstractArray{T,2}, fs_new::Float64, fs_old::Float64) where T <: AbstractFloat
    r = fs_new/fs_old
    Nrows, Ncols = size(x)
  
    ei = ceil(Int64, Nrows * r)
  
    # resize x if we're upsampling
    if (r > 1.0)
      x = vcat(x,zeros(eltype(x),ei-Nrows,Ncols))
    end
  
    # this op copies each column because of DSP type-instability
    for i = 1:Ncols
        x[1:ei,i] = resample(x[1:Nrows,i], r)
    end
  
    # resize S.x if we downsampled
    if fs_new < fs_old
        x = x[1:ei,:]
    end
    
    return x
  end

  function resample!(N::NodalData, f0::Float64)
    all(N.fs .> 0.0) || error("Can't resample non-timeseries data!")
    all(N.fs .== f0) && return nothing
    @assert f0 > 0.0
    proc_str = string("resample!(N, fs=",
                repr("text/plain", f0, context=:compact=>true), ")")
    N.data = nodal_resample(N.data,f0,N.fs[1])
    nx_out = size(N.data,1)
    refresh_x!(N)
    desc_str = string("resampled from ", N.fs[1], " to ", f0, "Hz")
    for i = 1:N.n
      proc_note!(N, i, proc_str, desc_str)
      N.fs[i] = f0
      N.t[i][2] = nx_out
    end
    return nothing
  end

  function resample(N::NodalData, f0::Float64)
    U = deepcopy(N)
    resample!(U, f0)
    return U
  end