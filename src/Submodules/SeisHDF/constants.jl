#=
HDF5 TYPES SUPPORTED
signed and unsigned integers of 8, 16, 32, and 64 bits, Float32, Float64;
Complex versions of these numeric types
Arrays of these numeric types (including complex versions)

 ASCIIString and UTF8String; and Arrays of these two string types.

Note: can't really do String support for interoperability reasons.
=#
const HDF5Type = Union{ Float32, Float64,
                        Complex{Float32}, Complex{Float64},
                        UInt8, UInt16, UInt32, UInt64,
                        Complex{UInt8}, Complex{UInt16},
                        Complex{UInt32}, Complex{UInt64},
                        Int8, Int16, Int32, Int64,
                        Complex{Int8}, Complex{Int16},
                        Complex{Int32}, Complex{Int64} }

const HDF5Array = Union{Array{Float64, N},
                        Array{Float32, N},
                        Array{Complex{Float64}, N},
                        Array{Complex{Float32}, N},
                        Array{UInt8, N},
                        Array{UInt16, N},
                        Array{UInt32, N},
                        Array{UInt64, N},
                        Array{Complex{UInt8}, N},
                        Array{Complex{UInt16}, N},
                        Array{Complex{UInt32}, N},
                        Array{Complex{UInt64}, N},
                        Array{Int8, N},
                        Array{Int16, N},
                        Array{Int32, N},
                        Array{Int64, N},
                        Array{Complex{Int8}, N},
                        Array{Complex{Int16}, N},
                        Array{Complex{Int32}, N},
                        Array{Complex{Int64}, N}} where N

# These are adapted from unix2datetime.(1.0e-9.*[typemin(Int64), typemax(Int64)])
const unset_s = "1677-09-21T00:12:44"
const unset_t = "2262-04-11T23:47:16"
