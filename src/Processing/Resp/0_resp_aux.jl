# =====================================================================
function update_ff!(ff::Array{Complex{Float32},1},
                    zp::Union{PZResp, PZResp64},
                    f::Array{Float32,1})
  Z = zp.z
  P = zp.p

  i = 0
  γ = 0.0f0
  g = 0.0f0
  d = zero(Complex{Float32})
  ϵ = eps(Float32)^2

  @inbounds while i < length(f)
    i = i + 1
    cf = im*f[i]
    n = 1.0f0
    for z in Z
      n *= cf-z
    end
    for p in P
      d = conj(cf-p)
      n *= d
      n /= max(ϵ, abs2(d))
    end
    g = abs2(n)
    if g > γ
      γ = g
    end
    setindex!(ff, n, i)
  end

  rmul!(ff, zp.a0)

  return sqrt(γ)*zp.a0
end

# frequencies in radians/s from -pi*fs to pi*fs
function fill_f!(f::Array{Float32,1}, fs::Float32, N2::Int64)
  N = div(N2, 2)
  fn = Float32(pi*fs)
  df = fn/Float32(N)
  f[:] .= 0:N2-1
  for i = N+2:N2
    f[i] -= N2
  end
  rmul!(f, df)
  return f
end


function update_resp!(f::AbstractArray,
                      ff_old::AbstractArray,
                      ff_new::AbstractArray,
                      N2::Int64,
                      fs::Float32,
                      resp_old::Union{PZResp, PZResp64},
                      resp_new::Union{PZResp, PZResp64},
                      wl::Float32)

  fill_f!(f, fs, N2)
  update_ff!(ff_new, resp_new, f)
  γ = update_ff!(ff_old, resp_old, f)

  # allows manual watermarking for ill-behaved translations with scaling isssues
  wm = γ * wl
  for i = 1:N2
    setindex!(ff_new, (ff_new[i]*conj(ff_old[i])) / (abs2(ff_old[i]) + wm), i)
  end

  return nothing
end

function update_resp_vecs!( Xw::Array{Complex{Float32},1},
                            f::Array{Float32,1},
                            ff_old::Array{Complex{Float32},1},
                            ff_new::Array{Complex{Float32},1},
                            N2::Int64 )
  resize!(Xw, N2)
  resize!(f, N2)
  resize!(ff_old, N2)
  resize!(ff_new, N2)
  xfl = reinterpret(Float32, Xw)
  xre = view(xfl, 1:2:2*N2-1)
  return xfl, xre
end

function update_resp_vecs!( Xw::Array{Complex{Float32},1},
                            f::Array{Float32,1},
                            ff::Array{Complex{Float32},1},
                            N2::Int64 )
  resize!(Xw, N2)
  resize!(f, N2)
  resize!(ff, N2)
  xfl = reinterpret(Float32, Xw)
  xre = view(xfl, 1:2:2*N2-1)
  return xfl, xre
end
