module TerrariaWiringHelper

import Base: ==, length

export AndGate, XorGate, CombGate
export lampstates, filtercolor

include("Utils.jl")
include("LogicalGates.jl")

end
