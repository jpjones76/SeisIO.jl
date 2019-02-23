#using Test
#using Compat
function remove_low_gain!(S::SeisData)
    # Remove low-gain seismic data channels
    i_low = findall([occursin(r".EL?", S.id[i]) for i=1:S.n])
    if !isempty(i_low)
        for k = length(i_low):-1:1
            @warn(join(["Low-gain, low-fs channel removed: ", S.id[i_low[k]]]))
            S -= S.id[i_low[k]]
        end
    end
    return
end

# Test that data are time synched correctly within a SeisData structure
function sync_test!(S::SeisData)
    local L = [length(S.x[i])/S.fs[i] for i = 1:S.n]
    local t = [S.t[i][1,2] for i = 1:S.n]
    @assert(maximum(L) - minimum(L) ≤ maximum(2.0./S.fs))
    @assert(maximum(t) - minimum(t) ≤ maximum(2.0./S.fs))
    return nothing
end
