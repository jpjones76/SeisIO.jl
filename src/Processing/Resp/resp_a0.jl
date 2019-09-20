export resp_a0!

@doc """
    resp_a0!(R::Union{PZResp, PZResp64})

Update normalization factor `R.a0` from `R.z`, `R.p`, and `R.f0`.

    resp_a0!(S::GphysData)

Call resp_a0! on each response in S with typeof(S.resp[i]) ∈ [PZResp, PZResp64].

### See Also
PZResp, PZResp64
""" resp_a0!
function resp_a0!(resp::Union{PZResp, PZResp64})
  T = typeof(resp.a0)
  Z = SeisIO.poly(resp.z)
  P = SeisIO.poly(resp.p)
  s = Complex{T}(2*pi*im*resp.f0)
  setfield!(resp, :a0, one(T)/T(abs(SeisIO.polyval(Z, s)/SeisIO.polyval(P, s))))
  return nothing
end

function fix_a0!(R::Union{PZResp, PZResp64}, units::String)
  Y = typeof(R)
  (Y in [PZResp, PZResp64]) || return
  T = typeof(R.a0)
  resp_a0!(R)
  if lowercase(units) == "m/s" && R.a0 > zero(T)
    R.a0 *= T(-1.0f0)
  end
  return nothing
end

function resp_a0!(S::GphysData)
  for i = 1:S.n
    R = getindex(S.resp, i)
    Y = typeof(R)
    if Y in [PZResp, PZResp64]
      fix_a0!(R, S.units[i])
    elseif Y == MultiStageResp
      for R in getfield(R, :stage)
        if typeof(R) in [PZResp, PZResp64]
          fix_a0!(R, S.units[i])
        end
      end
    end
  end
  return nothing
end
