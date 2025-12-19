"""
    Z2Vector{T<:Integer}(data::T, size::Int)
    Z2Vector(::AbstractVector)

``\\mathbb{Z}_2`` vector stored in an integer `data` where each bit represents an entry. `size` specifies the length.

# Example

```jldoctest
julia> Z2Vector(0b10110, 5)
5-element Z2Vector{UInt8}:
 0
 1
 1
 0
 1
```
"""
mutable struct Z2Vector{T<:Integer} <: AbstractVector{Bool}
    data::T
    size::Int
    Z2Vector{T}(data::Integer, size::Int) where T = unsafe_Z2Vector(T(data) & datamask(T, size), size)

    global unsafe_Z2Vector(data::T, size::Int) where T = new{T}(data, size)
end
Z2Vector(data::Integer, size::Integer) = Z2Vector{bit2type(size)}(data, size)
Z2Vector(itr) = Z2Vector{bit2type(length(itr))}(itr)
function Z2Vector{T}(itr) where T
    ret = zero(T)
    for x in Iterators.reverse(itr)
        ret <<= 1
        ret += isodd(x)
    end
    unsafe_Z2Vector(ret, length(itr))
end

size(v::Z2Vector) = (v.size, )
IndexStyle(::Type{<:Z2Vector}) = IndexLinear()
similar(::Z2Vector{T}, ::Type{Bool}, dims::Tuple{Int}) where T = Z2Vector(zero(T), dims[1])

function getindex(v::Z2Vector, i::Integer)
    @boundscheck checkbounds(v, i)
    unsafe_getindex(v, i)
end
function setindex!(v::Z2Vector, x::Number, i::Integer)
    v.data = setbit(v.data, z2number(x), i-1)
    v
end

"""
    datamask(::Type{T}, size::Integer)
    datamask(A::Z2Vector{T}) = datamask(T, A.size)

Internal. Returns the bitmask of type `T` where the lower `size` bits are set to 1.

# Examples
```jldoctest; setup = :"using TerrariaWiringHelper: datamask"
julia> datamask(UInt8, 3)
0x07

julia> datamask(Z2Vector(0b10110, 5))
0x1f

julia> datamask(Z2Vector(0b10110, 4))
0x0f
```
"""
datamask(::Type{T}, size::Integer) where T = (one(T) << size) - one(T)
datamask(A::Z2Vector{T}) where T = datamask(T, A.size)

zero(v::Z2Vector{T}) where T = Z2Vector{T}(zero(T), v.size)
copy(v::Z2Vector{T}) where T = Z2Vector{T}(v.data, v.size)
similar(v::Z2Vector) = copy(v)

function fill!(v::Z2Vector{T}, x::Number) where T
    v.data = ifelse(z2number(x), datamask(v), zero(T))
    v
end

for op in (:&, :|, :⊻, :⊽, :⊼)
    @eval function $op(A::Z2Vector{T}, B::Z2Vector{T}) where T
        promote_shape(A, B)
        Z2Vector{T}($op(A.data, B.data), A.size)
    end
end

~(v::Z2Vector{T}) where T = Z2Vector(v.data ⊻ datamask(v), length(v))
