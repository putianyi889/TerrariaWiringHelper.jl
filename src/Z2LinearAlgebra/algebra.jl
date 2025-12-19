
==(u::Z2Vector, v::Z2Vector) = u.size == v.size && u.data == v.data
==(u::Z2ColMat, v::Z2ColMat) = u.size == v.size && u.data == v.data
==(u::Z2RowMat, v::Z2RowMat) = u.size == v.size && u.data == v.data

function +(u::Z2Vector{T}, v::Z2Vector{T}) where T
    promote_shape(u, v)
    unsafe_Z2Vector(u.data ⊻ v.data, u.size)
end

-(u::AbstractArray, v::Z2Vector) = u + v
