T = [deepcopy(s3.t), deepcopy(s4.t)]
p = [1,2]
sr = Int(1000000/s4.fs)

ti = Array{Int64,1}(0)
tv = Array{Int64,1}(0)
n = 0
ll = 0
for k = 1:1:length(p)
  κ = p[k]

  # Push start time if k=1 or a gap exists
  if k == 1
    push!(ti, T[κ][1,1]+n)
    push!(tv, T[κ][1,2])
  else
    δt = T[κ][1,2]-tv[1]-sr*ll
    if δt != 0
      push!(ti, T[κ][1,1]+n)
      push!(tv, δt)
    end
  end

  # All other rows, second column becomes (row_index)*(sample_rate_in_μs) + cumsum(second_column_up_to_and_including_current_row)
  λ = size(T[κ],1)
  if λ > 2
    for ri = 2:1:λ-1
      push!(tv, T[κ][ri,2])
      push!(ti, T[κ][ri,1]+n)
    end
  end
  # println(T[κ])
  ll = T[κ][λ,1]
  n += ll
  # println([ti tv])
end
push!(ti, n)
push!(tv, 0)
