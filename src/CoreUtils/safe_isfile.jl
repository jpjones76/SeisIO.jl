# Adapted from https://github.com/JuliaPackaging/BinaryProvider.jl/commit/08a314a225206a68665c6f730d7c3feeda1ba615

# Temporary hack around https://github.com/JuliaLang/julia/issues/26685
function safe_isfile(path)
    try
        return isfile(path)
    catch err
        if typeof(err) <: Base.IOError && err.code == Base.UV_EINVAL
            return false
        end
        rethrow(err)
    end
end
