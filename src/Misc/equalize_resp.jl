"""
    equalize_resp!(S::SeisData, resp_new::Array{Complex{Float64},2})

Translate all data in S.x to instrument response resp_new. zeros are in resp[:,1], poles in resp[:,2]. If channel `i` has key `S.misc[i]["hc"]`, this is used as the critical damping constant, else a value of 1.0 is assumed.
"""
function equalize_resp!(S::SeisData, resp_new::Array{Complex{Float64},2};
hc_new=1.0/sqrt(2.0)::Float64, C=Int64[]::Array{Int64,1})
  pp = 2.0*Float64(pi)
  F1 = resp_f(resp_new, hc_new, f, fs)
  if isempty(C)
    C = 1:1:S.n
  end
  for i in C
    if S.resp[i] != resp_new && S.fs[i] > 0.0
      h = haskey(S.misc[i],"hc") ? S.misc[i]["hc"] : 1.0/sqrt(2.0)
      X = S.x[i]
      Nx = length(X)
      N2 = nextpow2(Nx)
      fs = S.fs[i]
      f = [collect(0:N2/2); collect(-N2/2+1:-1)]*fs/N2

      F0 = resp_f(S.resp[i], h, f, fs)  # Old response


      xf = fft([X; zeros(Float64, N2-Nx)])
      rf = F1.*conj(F0)./(F0.*conj(F0).+eps())

      # Changes: x, resp, misc["hc"]
      S.x[i] = real(ifft(xf.*rf))[1:Nx]
      S.resp[i] = resp_new
      S.misc[i]["hc"] = hc_new
    end
  end
  return nothing
end
