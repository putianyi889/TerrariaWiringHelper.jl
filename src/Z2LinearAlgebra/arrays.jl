

"""
    Z2RowMat{C<:Integer, R<:Integer}(data::Vector{R}, size::Int)
    Z2RowMat(undef, m, n)
    Z2RowMat(::AbstractMatrix)

``\\mathbb{Z}_2`` matrix stored in a `Vector` where each entry represents a row. `size` specifies the width. `C` and `R` are used for dispatch; they specify the integer type used to represent a column vector and a row vector respectively. See also [`bit2type`](@ref), [`Z2ColMat`](@ref)

# Example
```jldoctest
julia> Z2RowMat([1, 3, 5], 3)
3×3 Z2RowMat{UInt8, UInt8}:
 1  0  0
 1  1  0
 1  0  1
```
"""
mutable struct Z2RowMat{C<:Integer, R<:Integer} <: AbstractMatrix{Bool}
    data::Vector{R}
    size::Int

    function Z2RowMat{C,R}(data::Vector{R}, size::Int) where {C,R}
        for i in eachindex(data)
            data[i] &= datamask(R, size)
        end
        unsafe_Z2RowMat(C, data, size)
    end

    global unsafe_Z2RowMat(C::Type{<:Integer}, data::Vector{R}, size::Int) where R = new{C,R}(data, size)
    unsafe_Z2RowMat(data::Vector{R}, size::Int) where R = unsafe_Z2RowMat(bit2type(size), data, size)
end

"""
    Z2ColMat{C<:Integer, R<:Integer}(data::Vector{C}, size::Int)
    Z2ColMat(undef, m, n)
    Z2ColMat(::AbstractMatrix)

``\\mathbb{Z}_2`` matrix stored in a `Vector` where each entry represents a column. `size` specifies the height. `C` and `R` are used for dispatch; they specify the integer type used to represent a column vector and a row vector respectively. See also [`bit2type`](@ref), [`Z2RowMat`](@ref)

# Example
```jldoctest
julia> Z2ColMat([1, 3, 5], 3)
3×3 Z2ColMat{UInt8, UInt8}:
 1  1  1
 0  1  0
 0  0  1
```
"""
mutable struct Z2ColMat{C<:Integer, R<:Integer} <: AbstractMatrix{Bool}
    data::Vector{C}
    size::Int

    function Z2ColMat{C,R}(data::Vector{C}, size::Int) where {C,R}
        for i in eachindex(data)
            data[i] &= datamask(C, size)
        end
        unsafe_Z2ColMat(R, data, size)
    end

    global unsafe_Z2ColMat(R::Type{<:Integer}, data::Vector{C}, size::Int) where C = new{C,R}(data, size)
    unsafe_Z2ColMat(data::Vector{C}, size::Int) where C = unsafe_Z2ColMat(bit2type(size), data, size)
end
const Z2Mat{C,R} = Union{Z2RowMat{C,R}, Z2ColMat{C,R}}

function Z2RowMat(data::AbstractVector{<:Integer}, cols::Integer)
    C = bit2type(length(data))
    R = bit2type(cols)
    Z2RowMat{C,R}(convert(Vector{R}, (data)), cols)
end
function Z2ColMat(data::AbstractVector{<:Integer}, rows::Integer)
    C = bit2type(rows)
    R = bit2type(length(data))
    Z2ColMat{C,R}(convert(Vector{C}, (data)), rows)
end

Z2RowMat{C,R}(::UndefInitializer, m::Integer, n::Integer) where {C,R} = Z2RowMat{C,R}(zeros(R, m), n)
Z2ColMat{C,R}(::UndefInitializer, m::Integer, n::Integer) where {C,R} = Z2ColMat{C,R}(zeros(C, n), m)
function Z2RowMat(A::AbstractMatrix)
    m, n = size(A)
    ret = Z2RowMat(undef, m, n)
    ret .= z2number(A)
end
function Z2ColMat(A::AbstractMatrix)
    m, n = size(A)
    ret = Z2ColMat(undef, m, n)
    ret .= z2number(A)
end
for Typ in (:Z2RowMat, :Z2ColMat)
    @eval $Typ(::UndefInitializer, m::Integer, n::Integer) = $Typ{bit2type(m), bit2type(n)}(undef, m, n)
end

size(A::Z2RowMat) = (length(A.data), A.size)
size(A::Z2ColMat) = (A.size, length(A.data))

function setindex!(A::Z2RowMat, x::Number, i::Integer, j::Integer)
    A.data[i] = setbit(A.data[i], z2number(x), j-1)
end
function setindex!(A::Z2ColMat, x::Number, i::Integer, j::Integer)
    A.data[j] = setbit(A.data[j], z2number(x), i-1)
end

datamask(A::Z2RowMat{C,R}) where {C,R} = (one(R) << A.size) - one(R)
datamask(A::Z2ColMat{C,R}) where {C,R} = (one(C) << A.size) - one(C)

for Typ in (Z2RowMat, Z2ColMat)
    for op in (:zero, :copy)
        @eval $op(A::$Typ{C,R}) where {C,R} = $Typ{C,R}($op.(A.data), A.size)
    end
    for op in (:&, :|, :⊻, :⊽, :⊼)
        @eval function $op(A::$Typ{C,R}, B::$Typ{C,R}) where {C,R}
            promote_shape(A, B)
            $Typ{C,R}($op.(A.data, B.data), A.size)
        end
    end
    @eval begin
        similar(A::$Typ) = zero(A)
        similar(A::$Typ, dims::Dims{2}) = $Typ(undef, dims...)
        similar(A::$Typ, ::Type{Bool}, dims::Dims{2}) = similar(A, dims)

        function fill!(A::$Typ, x::Number)
            fill!(A.data, ifelse(z2number(x), datamask(A), zero(eltype(A.data))))
            A
        end

        function lmul!(x::Number, A::$Typ)
            if !z2number(x)
                fill!(A, false)
            end
            A
        end
        function rmul!(A::$Typ, x::Number)
            if !z2number(x)
                fill!(A, false)
            end
            A
        end

        function one(A::$Typ{C,R}) where {C,R}
            m = checksquare(A)
            $Typ{C,R}(one(C) .<< (0:m-1), m)
        end

        rank(A::$Typ) = matrank!(copy(A.data))
        det(A::$Typ) = matdet!(copy(A.data))
        +(A::$Typ, B::$Typ) = A ⊻ B
        ~(A::$Typ{C,R}) where {C,R} = $Typ(A.data .⊻ datamask(A), A.size)
    end
end

for op in (:transpose, :adjoint)
    @eval $op(A::Z2RowMat{C,R}) where {C,R} = Z2ColMat{R,C}(A.data, A.size)
    @eval $op(A::Z2ColMat{C,R}) where {C,R} = Z2RowMat{R,C}(A.data, A.size)
end




# algebra

function lmul!(x::Bool, v::Z2Vector{T}) where T
    if !x
        v.data = zero(T)
    end
    v
end
function rmul!(v::Z2Vector{T}, x::Bool) where T
    if !x
        v.data = zero(T)
    end
    v
end

function dot(u::Z2Vector, v::Z2Vector)
    if length(u) != length(v)
        throw(DimensionMismatch("first array has length $(length(u)) which does not match the length of the second, $(length(v))."))
    end
    fuse(u.data, v.data)
end

function *(A::Z2RowMat{C,R}, v::Z2Vector{T}) where {C,R,T}
    if size(A, 2) != length(v)
        throw(DimensionMismatch("second dimension of A, $nA, does not match length of v, $(length(v))"))
    end
    Z2Vector{C}(rowmatmulvec(A.data, v.data), size(A, 1))
end
function *(A::Z2ColMat{C,R}, v::Z2Vector{T}) where {C,R,T}
    if size(A, 2) != length(v)
        throw(DimensionMismatch("second dimension of A, $nA, does not match length of v, $(length(v))"))
    end
    Z2Vector{C}(colmatmulvec(A.data, v.data), size(A,1))
end

for Typ in (Z2RowMat, Z2ColMat)
    @eval begin
        function *(A::$Typ{C1,R1}, B::$Typ{C2,R2}) where {C1,R1,C2,R2}
            C = $Typ{C1,R2}(undef, size(A, 1), size(B, 2))
            mul!(C, A, B)
        end
    end
end

@inline function check_mul_mismatch(A, B)
    if size(A, 2) != size(B, 1)
        throw(DimensionMismatch("A has dimensions $(size(A)) but B has dimensions $(size(B))"))
    end
end

@inline function check_div_mismatch(A, B)
    if size(A, 1) != size(B, 1)
        throw(DimensionMismatch("A has dimensions $(size(A)) but B has dimensions $(size(B))"))
    end
end

function mul!(C::Z2RowMat{C1,R2}, A::Z2RowMat{C1,R1}, B::Z2RowMat{C2,R2}) where {C1,R1,C2,R2}
    check_mul_mismatch(A, B)
    for j in eachindex(C.data)
        C.data[j] = colmatmulvec(B.data, A.data[j])
    end
    C
end
function mul!(C::Z2ColMat{C1,R2}, A::Z2ColMat{C1,R1}, B::Z2ColMat{C2,R2}) where {C1,R1,C2,R2}
    check_mul_mismatch(A, B)
    for j in eachindex(C.data)
        C.data[j] = colmatmulvec(A.data, B.data[j])
    end
    C
end
function mul!(C::Z2RowMat{C1,R2}, A::Z2RowMat{C1,R1}, B::Z2ColMat{C2,R2}) where {C1,R1,C2,R2} # TODO
    check_mul_mismatch(A, B)
end

function ldiv!(C::Z2RowMat{C1,R2}, A::Z2RowMat{C1,R1}, B::Z2RowMat{C1,R2}) where {C1,R1,R2}
    rowmatldivrowmat!(C.data, copy(A.data), copy(B.data))
    C
end

function \(A::Z2RowMat{C1,R1}, B::Z2RowMat{C1,R2}) where {C1,R1,R2}
    check_div_mismatch(A, B)
    C = similar(B)
    ldiv!(C, A, B)
end
