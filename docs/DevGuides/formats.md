# **Data Formats Guide and API**
This guide includes API and expectations for data format readers and parsers.

## **Definitions of Terms**
* **Unix epoch** or **epoch time**: 1970-01-01T00:00:00 (UTC)
* **HDF5**: [Hierarchical Data Format](https://support.hdfgroup.org/HDF5/whatishdf5.html)

# **Requirements**
Any data reader must...
* return a SeisData structure for time-series data.
* return a SeisEvent structure for discrete earthquake data.
* work with one "read" wrapper without adding keywords.
* not modify existing GphysData channels unless reading to them
* not break existing readers by leaving buffers in BUF resized
* extend a channel whose ID matches the data being read into memory
* include tests in *../../test/DataFormats/test_FF.jl* for data format FF
  + Expected code coverage: >95% on both Coveralls and CodeCov

## **Suggestions**
* Import *SeisIO.Formats.formats* and add an appropriate description
* Once your reader works, change low-level file I/O to use *SeisIO.FastRead*
* Use *SeisIO.BUF* for data I/O; see API below

### Adding more formats
Seismology alone has ~10^2 extant file formats; I cannot guess how many more are used by geodesy, volcanology, etc. Before adding support for another one, ask yourself if it's in widespread use. If not, ask yourself if this is a judicious use of your research time.

# **File Reader API**
## **List of Variables**
| V   | Meaning                   | Type in Julia                           |
|:--- |:----                      | :---                                    |
| A   | string array              | Array{String, 1}                        |
| B   | byte vector for reading   | Array{UInt8, 1}                         |
| C   | single-channel structure  | typeof(C) <: SeisIO.GphysChannel        |
| D   | data read array           | AbstractArray                           |
| L   | channel :loc field        | typeof(L) <: SeisIO.InstrumentPosition  |
| Q   | integer array             | Array{Y,1} where Y<:Integer             |
| R   | channel :resp field       | typeof(R) <: SeisIO.InstrumentResponse  |
| S   | multichannel structure    | typeof(S) <: SeisIO.GphysData           |
| V   | output byte array         | Array{UInt8, 1}                         |
| Y   | a primitive Type          | Type                                    |
| c   | ASCII character           | Char                                    |
| fc  | lower corner frequency    | Float64                                 |
| fs  | channel :fs field         | Float64                                 |
| g   | channel :gain field       | Float64                                 |
| n   | an integer                | Integer                                 |
| s   | short integer             | Int16                                   |
| str | ASCII string              | String                                  |
| t   | time [μs] from Unix epoch | Int64                                   |
| tf  | boolean variable          | Bool                                    |
| u   | 8-bit unsigned integer    | UInt8                                   |
| uu  | channel :units field      | String                                  |
| x   | a Julia double float      | Float64                                 |
| q   | any integer               | Integer                                 |
| ul  | unsigned 32-bit integer   | UInt32                                  |

## **Function API**

`BUF`

SeisIO static structure containing arrays for buffered file reads. See **SeisIO.BUF API** below.

`ChanSpec`

Type alias to *Union{Integer, UnitRange, Array{Int64, 1}}*

`i = add_chan!(S::GphysData, C::GphysChannel, strict::Bool)`

Add channel *C* to *S*. If *C.id* matches a channel ID in *S*, data and times from *C* are added and the remaining information is discarded. Use *strict=true* to match channels on more than *:id*. Returns the index of the matching channel.

`i = channel_match(S::GphysData, i::Integer, fs::Float64)`

Check that *fs* matches *S.fs[i]*. Returns the index of the matching channel (if one exists) or 0 (if no match).

```
i = channel_match(S::GphysData, i::Integer, fs::Float64,
  g::AbstractFloat, L::InstrumentPosition, R::InstrumentResponse  
  uu::String)
```

Test that *S[i]* matches *fs*, *g*, *loc*, *R, *units*. If successful, returns *i*; if not, returns 0.

`c = getbandcode(fs::Float64; fc::Float64 = 1.0)`

Get FDSN-compliant band code (second letter of channel designator) for sampling frequency *fs* Hz with nominal lower instrument corner frequency *fc*. Returns the one-character code.

`A = split_id(id::AbstractString; c::String=".")`

Split *id* on delimiter *c*, always returning a length-4 String array containing the pieces. Incomplete IDs have their remaining fields filled with empty strings.

`str = fix_units(str::AbstractString)`

Replace *str* with UCUM-compliant unit string via Dict lookup.

`str = units2ucum(str::String)`

Replace *str* with UCUM-compliant unit string via substitution.

`tf = is_u8_digit(u::UInt8)`

Returns *true* if 0x2f < *u* < 0x3a, i.e., if *u* represents an ASCII character in the range '0'-'9'.

`fill_id!(B::Array{UInt8,1}, cv::Array{UInt8,1}, i::T, i_max::T, j::T, j_max::T)`

Fill id vector *V* from char vector *B*, starting at *B[i]* and *V[j]* and ending at *B[imax]* or *V[jmax]*, whichever is reached first.

`n = checkbuf!(B::Array{UInt8,1}, q::Y1, Y::Type) where Y1<:Integer`

Check that *B* can read at least *q* values of data type *Y*. Returns the new buffer size in bytes.

`checkbuf!(D::AbstractArray, q::Y) where Y<:Integer`

Calls *resize!(D, q)* if *q* > *length(D)*; otherwise, leaves *D* untouched.

`checkbuf_strict!(D::AbstractArray, q::Y) where Y<:Integer`

Calls *resize!(D, q)* if *q* != *length(D)*

`checkbuf_8!(B::Array{UInt8,1}, q::Integer)`

Check that *B* can hold a number of bytes equal to the first value *q1* > *q* that satisfies the equation *mod(q1, 8)* = 0.

### **Low-Level Parsers**
These functions all fill *x[os]:x[os+q]* from bytes buffer *B*. The function names completely describe the read operation:
* the character after the first underscore is the data type expected: 'i' for integer, 'u' for unsigned
* the next number is the number of bits per value: 4. 8, 16, 24, or 32
* the string after the second underscore gives the endianness: "le" for little-endian, "be"* for bigendian)

```
function fillx_i4!(x::AbstractArray, B::Array{UInt8,1}, q::Integer, os::Int64)
function fillx_i8!(x::AbstractArray, B::Array{UInt8,1}, q::Integer, os::Int64)
function fillx_i16_le!(x::AbstractArray, B::Array{UInt8,1}, q::Integer, os::Int64)
function fillx_i16_be!(x::AbstractArray, B::Array{UInt8,1}, q::Integer, os::Int64)
function fillx_i24_be!(x::AbstractArray, B::Array{UInt8,1}, q::Integer, os::Int64)
function fillx_i32_le!(x::AbstractArray, B::Array{UInt8,1}, q::Integer, os::Int64)
function fillx_i32_be!(x::AbstractArray, B::Array{UInt8,1}, q::Integer, os::Int64)
function fillx_u32_be!(x::AbstractArray, B::Array{UInt8,1}, q::Integer, os::Int64)
function fillx_u32_le!(x::AbstractArray, B::Array{UInt8,1}, q::Integer, os::Int64)
```

The above data types include every integer encoding that we've encountered in real data.

### **Byte-wise ASCII Parsers**
Use these to parse ASCII data. They're generally faster than `parse()`.

`u = buf_to_uint(B::Array{UInt8,1}, q::Integer)`

Parse characters in *B* to an unsigned Int64, to a maximum position in *B* of *q*.

`s = buf_to_i16(B::Array{UInt8,1}, s₀::Int16, s₁::Int16)`

Parse characters in *B* to create a 16-bit signed integer, starting at position *s₀* in *B* and ending at position *s₁*.

`x = buf_to_double(B::Array{UInt8,1}, n::Int64)`

Parse characters in *B* to create a Float64, to a maximum position in *B* of *n*.

`ul1, ul2 = parse_digits(io::IO, u_in::UInt8, u_max::UInt8)`

Parse *io* one byte at a time until reaching a non-digit character, returning two unsigned 32-bit integers. A maximum of *u_max* characters will be parsed.

`n = stream_int(io::IO, nᵢ::Int64)`

Parse a maximum of *nᵢ* bytes from *io*, creating a 64-bit integer *n* from the character bytes.

`x = stream_float(io::IO, u_in::UInt8)`

Parse *io* to create a single-precision float. Can parse many degenerate float strings, like "3F12".

`t = stream_time(io::IO, Q::Array{Y,1}) where Y<:Integer`

Parse characters in *io* to fill an array *Q* of time values, then convert to integer μs measured from the Unix epoch.

`t = string_time(str::String, Q::Array{Y,1}) where Y<:Integer`

`t = string_time(str::String)`

Wrap *str* in an IOBuffer and call *stream_time* on the buffer. Returns a time in integer μs measured from the Unix epoch. If only one argument is supplied, *string_time* buffers to *BUF.date_buf*.

## **Usable Buffers**

| field_name  | Type    | Used By         | resize_to |
|:---         |:---     |:---             |       ---:|
| buf         | UInt8   | everything      |     65535 |
| int16_buf   | Int16   | SEG Y           |        62 |
| int32_buf   | Int32   | SEGY, Win32     |       100 |
| int64_buf   | Int64   | rseis/wseis     |         6 |
| sac_cv      | UInt8   | AH, SAC         |       192 |
| sac_fv      | Float32 | SAC             |        70 |
| sac_iv      | Int32   | SAC             |        40 |
| uint16_buf  | UInt16  | SEED            |         6 |
| uint32_buf  | UInt32  | mini-SEED       |     16384 |
| x           | Float32 | everything      |     65535 |

* Call `checkbuf!`, `checkbuf_8!`, or `checkbuf_strict!` before use as needed
* Call `resize!(BUF.field_name, resize_to)` when done

## **Unusable Buffers**
calibs, date_buf, dh_arr, flags, hdr, hdr_old, id, seq

These buffers are part of the SEED reader.
