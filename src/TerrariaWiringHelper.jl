module TerrariaWiringHelper

import Base: ==, length

export AndGate, XorGate, CombGate
export lampstates, filtercolor, lampstate2string

include("Utils.jl")
include("LogicalGates.jl")

end
