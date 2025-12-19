
function getindex(A::Z2Mat, i::Union{Integer, Colon}, j::Union{Integer, Colon})
    @boundscheck checkbounds(A, i, j)
    return unsafe_getindex(A, i, j)
end

function getindex(v::Z2Vector, i::Union{Integer, Colon})
    @boundscheck checkbounds(v, i)
    return unsafe_getindex(v, i)
end

unsafe_getindex(v::Z2Vector, i::Integer) = getbit(v.data, i-1)
unsafe_getindex(v::Z2Vector, ::Colon) = copy(v)

unsafe_getindex(A::Z2RowMat, i::Integer, ::Colon) = unsafe_Z2Vector(A.data[i], A.size)
unsafe_getindex(A::Z2ColMat, ::Colon, j::Integer) = unsafe_Z2Vector(A.data[j], A.size)

unsafe_getindex(A::Z2RowMat, i::Integer, j::Integer) = getbit(A.data[i], j-1)
unsafe_getindex(A::Z2ColMat, i::Integer, j::Integer) = getbit(A.data[j], i-1)

unsafe_getindex(A::Z2RowMat{C}, ::Colon, j::Integer) where {C} = Z2Vector{C}((getbit(A.data[i], j-1) for i in 1:length(A.data)))
unsafe_getindex(A::Z2ColMat{C,R}, i::Integer, ::Colon) where {C,R} = Z2Vector{R}((getbit(A.data[j], i-1) for j in 1:length(A.data)))
