
function +(u::Z2Vector{T}, v::Z2Vector{T}) where T
    promote_shape(u, v)
    Z2Vector(u.data ⊻ v.data, u.size)
end

-(u::AbstractArray, v::Z2Vector) = u + v
