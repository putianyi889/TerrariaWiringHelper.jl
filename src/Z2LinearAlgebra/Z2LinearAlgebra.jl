import Base: *, +, &, |, ⊻, ⊼, ⊽, ~, \
import Base: size, zero, fill!, getindex, error_if_canonical_getindex, unsafe_getindex, promote_shape, setindex!, copy, transpose, adjoint, similar, one, IndexStyle
import Base: sum
import Base: UndefInitializer, Dims
import LinearAlgebra: dot, AdjOrTrans, mul!, rank, det, checksquare, ldiv!, SingularException, lmul!, rmul!

include("helper.jl")
include("vector.jl")
include("arrays.jl")
include("interface.jl")
include("reduce.jl")
