#Author: Joshua Jones, highly.creative.pseudonym@gmail.com
#Version: 1.0, 2016-01-18

""" gauss(X) = exp(-((X-m)/s)²/2)/(s√2π)

    X     Array or number
    m     Mean (optional, default m = 0)
    s     Standard deviation (optional, default s = 1)
"""
gauss{T}(x::AbstractArray{T}; m=0.0::Float64, s=1.0::Float64) = exp(-0.5.*((x.-m)./s).^2)./(s*sqrt(2*π))
gauss(x::Number; m=0.0::Float64, s=1::Float64) = exp(-0.5*((x-m)/s)^2)/(s*sqrt(2*π))

""" **G** = gdm(N, t; T=Float64, c=false, F="gauss")
Form normalized NxN ground distance matrix **G** for inter-bin movement costs. Used in
quadratic-χ histogram distance computations [1]; type "?HistUtils.qchd" for details.

      INPUTS
      N   Number of bins. (Integer)
      t   Threshold distance, in bins, above which material cannot be moved.
           This doesn't need to be an integer.
      c   Circular boundary (Bool). For periodic data, set c=true.
      F   Bin distance function descriptor; used to construct **G**. (String)
          F val     Description
          "eye"     Identity matrix
          "lin"     G[i,j] = 1-|i-j|/t                   |i-j| < t
                    G[i,j] = 0                           |i-j| ≥ t
          "gauss"   G[i,j] ~ exp(-((j-i)/σ)²/2)/(σ√2π)   |i-j| ≤ t
                    G[i,j] = 0                           |i-j| > t
                    (σ = t/3 is hard-coded)

References:

[1]   Pele, O. & Werman, M., 2010. The quadratic-chi histogram distance family,
in Computer Vision—EECV 2010, pp. 749–762, eds Daniilidis, K., Maragos, P. & Paragios,
N., Springer.

"""
function gdm(N::Int, t::Int; T=Float64, c=false::Bool, F="gauss"::String)
  if F == "eye"
    G = eye(T, N, N)
  elseif F == "lin"
    if c
      G = eye(T, N, N)
      A = copy(G)
      for a = 1:1:t-1
        G .+= (circshift(A,[0 -a]).+circshift(A,[0 a])).*((t-a)/t)
      end
    else
      G = zeros(T, N, N)
      for a = 1:1:N
        for b = max(1,a-t+1):1:min(N,a+t-1)
          G[a,b] = 1-(abs(a-b)/t)
        end
      end
    end
  else
    G = zeros(T, N, N)
    if c
      g = circshift(cat(1,gauss(-t:1:t, s=t/3),zeros(T, N-2*t-1)),-t)'
      g = g./maximum(g)
      for a = 1:1:N
        G[a,:] = circshift(g,[0 a-1])
      end
    else
      for a = 1:1:N
        b1 = max(1, a-t+1)
        b2 = min(N, a+t-1)
        g = gauss(b1:1:b2, s=t/3)
        G[b1:b2,a] = g./maximum(g)
      end
    end
  end
  return G
end

""" *D* = qchd(**H**, **G**)

Compute quadratic-χ histogram distances between all column pairs in **H** [1].
For an N x K matrix **H**, *D* is a vector with K(K-1)/2 elements, arranged
[D(1,2), D(1,3), ... D(1,K), D(2,3), ... D(2,K), ... D(K-1,K)]

      INPUTS
      H   Histograms, arranged in columns. Normalization isn't necessary;
          the function renormalizes to ∑_n H[:,n] = 0.5.
      G   Ground distance matrix. Type "?HistUtils.gdm" for details.

References:

[1]   Pele, O. & Werman, M., 2010. The quadratic-chi histogram distance family,
in Computer Vision—EECV 2010, pp. 749–762, eds Daniilidis, K., Maragos, P. & Paragios,
N., Springer.

"""
#Author: Joshua Jones, highly.creative.pseudonym@gmail.com
#Version: 1.0, 2016-01-18
function qchd(H::Array{Float64,2}, G::Array{Float64,2})
  dtype = eltype(H)
  minimum(H) < 0.0 && error("Negative values in histogram!")
  H = H./(2.0.*sum(H,1))
  H[find(H.<eps(dtype))] = eps(dtype)
  K = size(H,2)
  D = zeros(dtype, round(Int, 0.5*K*(K-1.0)))
  i0 = 0
  for k = 1:1:K-1
    i1 = i0+K-k
    h0 = repmat(H[:,k], 1, K-k)
    h1 = H[:,k+1:K]
    Z = sqrt((h0 + h1)'*G)
    Z[find(Z.<eps(dtype))] = 1.0
    Z = (h0 - h1)'./Z
    D[i0+1:i1] = sqrt(max(eps(dtype),sum((Z*G).*Z,2)'))
    i0 = i1
  end
  return max(D,0.0)
end

""" *D* = chi2d(**H**)

Compute χ² histogram distances[1] between all column pairs in **H**.
For an N x K matrix **H**, *D* is a vector with K(K-1)/2 elements, arranged
[D(1,2), D(1,3), ... D(1,K), D(2,3), ... D(2,K), ... D(K-1,K)]

      INPUT
      H   Histograms arranged in columns. Normalization isn't necessary;
          the function renormalizes to ∑_n H[:,n] = 0.5.

References:

[1]   Snedecor, G.W. & Cochran, W.G., 1967. Statistical Methods, 6th ed., Iowa
State University Press.

"""
function chi2d{T}(H::Array{T,2})
  K = size(H,2)
  minimum(H) < 0.0 && error("Negative values in histogram!")
  H ./= sum(H,1)
  H[find(H.<eps(T))] = eps(T)
  D = zeros(T, round(Int, 0.5*K*(K-1.0)))
  i0 = 0
  for k = 1:1:K-1
    i1 = i0+K-k
    h0 = repmat(H[:,k], 1, K-k)
    h1 = H[:,k+1:K]
    D[i0+1:i1] = 0.5*sum((h0-h1).^2 ./ (h0+h1),1)
    i0 = i1
  end
  return D
end
