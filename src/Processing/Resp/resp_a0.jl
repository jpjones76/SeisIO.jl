export resp_a0!, update_resp_a0!

"""
    resp_a0!(R::Union{PZResp, PZResp64})

Update normalization factor `R.a0` from `R.z`, `R.p`, and `R.f0`.

### See Also
PZResp, PZResp64
"""
function resp_a0!(resp::Union{PZResp, PZResp64})
  T = typeof(resp.a0)
  Z = SeisIO.poly(resp.z)
  P = SeisIO.poly(resp.p)
  s = Complex{T}(2*pi*im*resp.f0)
  setfield!(resp, :a0, one(T)/T(abs(SeisIO.polyval(Z, s)/SeisIO.polyval(P, s))))
  return nothing
end

"""
    update_resp_a0!(S::SeisData)

Call resp_a0! on each response in S with typeof(S.resp[i]) ∈ [PZResp, PZResp64].

### See Also
resp_a0!, PZResp, PZResp64
"""
function update_resp_a0!(S::SeisData)
  for i = 1:S.n
    if typeof(S.resp[i]) == PZResp || typeof(S.resp[i]) == PZResp64
      T = typeof(S.resp[i].a0)
      resp_a0!(S.resp[i])
      if lowercase(S.units[i]) == "m/s" && S.resp[i].a0 > zero(T)
        S.resp[i].a0 *= T(-1.0f0)
      end
    end
  end
  return nothing
end
