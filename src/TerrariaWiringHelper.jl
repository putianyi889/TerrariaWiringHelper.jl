module TerrariaWiringHelper

import Base: ==, length, reduce
using StaticArrays
using Z2Algebra

export AndGate, XorGate, CombGate
export lampstates, filtercolor
export CombLogic
export Z2Vector, Z2RowMat, Z2ColMat, unsafe_Z2Vector, unsafe_Z2RowMat, unsafe_Z2ColMat

include("Utils.jl")
include("LogicalGates.jl")
include("CombLogic.jl")

end
