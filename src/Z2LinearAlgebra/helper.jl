"""
    bit2type(n::Integer) :: DataType

Returns minimal integer type that contains `n` bits

# Examples
```jldoctest
julia> TR.bit2type(5)
UInt8

julia> TR.bit2type(9)
UInt16

julia> TR.bit2type(32)
UInt32

julia> TR.bit2type(33)
UInt64

julia> TR.bit2type(100)
UInt128
```
"""
function bit2type(n::Integer)
    if n <= 8
        UInt8
    elseif n <= 16
        UInt16
    elseif n <= 32
        UInt32
    elseif n <= 64
        UInt64
    elseif n <= 128
        UInt128
    else
        throw(ArgumentError("doesn't support dimension $n"))
    end
end

"""
    type2bit(::Type{T})

The inverse of [`bit2type`](@ref).
"""
type2bit(::Type{T}) where T<:Integer = sizeof(T) << 3

"""
    getbit(x::Integer, n::Integer)

Get the `n`-th (counting from zero) last bit of `x`. See also [`setbit`](@ref)

# Example
```jldoctest
julia> [TR.getbit(0b10110, n) for n in 0:4]
5-element Vector{Bool}:
 0
 1
 1
 0
 1
```
"""
@inline getbit(x::Integer, n::Integer) = isodd(x >> n)

"""
    setbit(x::Integer, y::Bool, n::Integer)

Set the `n`-th (counting from zero) last bit of `x` to `y`. See also [`getbit`](@ref).

# Example
```jldoctest
julia> string(TR.setbit(0b10110, true, 0), base = 2)
"10111"

julia> string(TR.setbit(0b10110, false, 0), base = 2)
"10110"
```
"""
@inline setbit(x::Integer, y::Bool, n::Integer) = ifelse(y, x | one(x)<<n, x & ~(one(x)<<n))

@inline flipbit(x::Integer, n::Integer) = x ⊻ (one(x)<<n)
@inline flipbit(x::Integer, n::Integer, m...) = flipbit(flipbit(x, n), m...)

@inline xorbits(x::Integer, src::Integer, dest::Integer) = x ⊻ (((x>>src) & one(x)) << dest)

@inline exchangebits(x::Integer, m::Integer, n::Integer) = ifelse(getbit(x,m) == getbit(x,n), x, flipbit(x, m, n))

function rowmatmulvec(x::AbstractVector{<:Integer}, y::Integer)
    ret = zero(y)
    for u in x
        ret <<= 1
        ret += fuse(u, y)
    end
    ret
end

function colmatmulvec(x::AbstractVector{<:Integer}, y::Integer)
    ret = zero(y)
    for u in x
        ret = ifelse(isodd(y), ret ⊻ u, ret)
        y >>= 1
    end
    ret
end

function matrank!(x::AbstractVector{T}) where T<:Integer
    r = 0
    for i in lastindex(x):-1:1
        k = trailing_zeros(x[i])
        if k < type2bit(T)
            r += true
            for j in i-1:-1:1
                if getbit(x[j], k)
                    x[j] ⊻= x[i]
                end
            end
        end
    end
    r
end

function matdet!(x::AbstractVector{T}) where T<:Integer
    for i in lastindex(x):-1:1
        k = trailing_zeros(x[i])
        if k == type2bit(T)
            return false
        end
        for j in i-1:-1:1
            if isodd(x[j] >> k)
                x[j] ⊻= x[i]
            end
        end
    end
    return true
end

function rowmatldivrowmat!(z::AbstractVector{U}, x::AbstractVector{T}, y::AbstractVector{U}) where {T,U}
    p = zeros(T, length(x))
    for i in eachindex(x)
        if iszero(x[i])
            throw(SingularException(i))
        end
        k = trailing_zeros(x[i])
        for j in 1:i-1
            if isodd(x[j] >> k)
                x[j] ⊻= x[i]
                y[j] ⊻= y[i]
            end
        end
        for j in i+1:lastindex(x)
            if isodd(x[j] >> k)
                x[j] ⊻= x[i]
                y[j] ⊻= y[i]
            end
        end
        p[k+1] = i
    end
    for i in eachindex(p)
        z[i] = y[p[i]]
    end
end

"""
    z2number(::Number)
    z2number(::AbstractMatrix{<:Number})

Convert `Number` to `Bool` in the ``\\mathbb{Z}_2`` sense.

# Examples

```jldoctest
julia> TR.z2number(25)
true

julia> TR.z2number(1:5)
5-element BitVector:
 1
 0
 1
 0
 1
```
"""
z2number(x::Bool) = x
z2number(x::Integer) = isodd(x)
z2number(x::Number) = z2number(Integer(x))
z2number(x::AbstractArray{Bool}) = x
z2number(x::AbstractArray{<:Number}) = z2number.(x)
