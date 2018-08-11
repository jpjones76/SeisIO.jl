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

function get_ts_data(method_in::Function, sstr::String, ts::Real, L::Real; v=v::Int64)
    S = SeisData()
    c = 1
    S = method_in(sstr, s=ts, t=ts-L, v=v)
    while isempty(S)
        S = method_in(sstr, s=ts, t=ts-L, v=1)
        remove_low_gain!(S)

        # Check to see if S is empty
        if isempty(S)
            c += 1
            if c < 10
                @warn("Decrementing start time and retrying. If problem persists, check time zone settings.")
                ts -= 3600
            else
                error("Too many retries, exit with error. Check that network is configured.")
            end
        end
    end
    sync!(S)
    sync_test!(S)
    return S
end
