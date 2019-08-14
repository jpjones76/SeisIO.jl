printstyled("  diff_x!, int_x!\n", color=:light_green)

# Check that double-integration and double-differentiation are reversible
T = Float64
for i = 1:100
  fs = rand(T[10, 20, 40, 50, 100])
  δ = one(T)/fs
  N = 10^rand(1:5)
  N2 = div(N,2)
  x = randn(T, N)
  y = deepcopy(x)
  gaps = [1, rand(2:N2), rand(N2+1:N-1), N]

  diff_x!(x, gaps, fs)
  int_x!(x, gaps, δ)
  diff_x!(x, gaps, fs)
  int_x!(x, gaps, δ)
  if isapprox(x,y) == false
    println("test failed (part 1) after i = ", i, " trials (length(x) = ", length(x), ")")
  end
  @test isapprox(x,y)

  diff_x!(x, gaps, fs)
  diff_x!(x, gaps, fs)
  int_x!(x, gaps, δ)
  int_x!(x, gaps, δ)
  if isapprox(x,y) == false
    println("test failed (part 2) after i = ", i, " trials (length(x) = ", length(x), ")")
  end
  @test isapprox(x,y)

  int_x!(x, gaps, δ)
  int_x!(x, gaps, δ)
  diff_x!(x, gaps, fs)
  diff_x!(x, gaps, fs)
  if isapprox(x,y) == false
    println("test failed (part 3) after i = ", i, " trials (length(x) = ", length(x), ")")
  end
  @test isapprox(x,y)
end
