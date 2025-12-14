import Base: ==, length

"""
	(AndGate|XorGate){T<:Integer, V<:AbstractVector{<:Integer}}(gatestate::Bool, args::T, lampstates::V) <:AbstractGate
	CombGate{T, V} = Union{AndGate{T, V}, XorGate{T, V}}

Combinatory gates in Terraria. `gatestate` tells the default (when all inputs are zero) state of the gate. `args` tells the number of inputs. `lampstates` lists how the inputs are wired to each logic lamp. 

# Example
Consider `AndGate(false, 4, [0x12, 0x09, 0x04])`. It's an `AND` gate whose default state is `OFF`. Since there are `4` args (named `a-d`), we consider the last `5` bits of each entry of `lampstates`. The leading bit tells the default state of the lamps. The other 4 bits (from lower to higher) tell which args are wired to the lamp. i.e.,
- `0x12 = 0b10010` means the default state of the first lamp is `ON` and only `b` is connected to the lamp.
- `0x09 = 0b01001` means the default state of the second lamp is `OFF` and `a` and `d` are connected to the lamp.
- `0x04 = 0b00100` means the default state of the third lamp is `OFF` and only `c` is connected to the lamp.

```jldoctest
julia> AndGate(false, 4, [0x12, 0x09, 0x04])
&(~b, ad, c)
```

The output is visualized via [`gate2string`](@ref).
"""
AndGate, XorGate, CombGate

abstract type AbstractGate end
struct CombGate{F<:Union{typeof(AND), typeof(XOR)}, T<:Integer, V<:AbstractVector{<:Integer}} <: AbstractGate
    f::F
    gatestate::Bool
    args::T
    lampstates::V
end
const AndGate = CombGate{typeof(AND)}
const XorGate = CombGate{typeof(XOR)}

CombGate{typeof(AND)}(gatestate::Bool, args::Integer, lampstates::AbstractVector{<:Integer}) = CombGate(AND, gatestate, args, lampstates)
CombGate{typeof(XOR)}(gatestate::Bool, args::Integer, lampstates::AbstractVector{<:Integer}) = CombGate(XOR, gatestate, args, lampstates)

==(A::CombGate, B::CombGate) = (A.f == B.f) && (A.gatestate == B.gatestate) && (A.args == B.args) && (A.lampstates == B.lampstates)
lampstates(A::CombGate) = A.lampstates
length(A::CombGate) = length(lampstates(A))
logicsymb(A::CombGate) = logicsymb(A.f)

"""
	gate2string(G::CombGate)

Convert a `CombGate` into a readable string. See also [`CombGate`](@ref), [`lampstate2string`](@ref), [`logicsymb`](@ref).
"""
function gate2string(G::CombGate)
	ret = IOBuffer()
	print(ret, ifelse(G.gatestate, '~', ""), logicsymb(G), '(', lampstate2string(G.lampstates[1], G.args))
	for k in 2:lastindex(G.lampstates)
		print(ret, ", ", lampstate2string(G.lampstates[k], G.args))
	end
	print(ret, ')')
	return String(take!(ret))
end
Base.show(io::IO, G::CombGate) = print(io, gate2string(G))

const alphabet = "abcdefghijklmnopqrstuvwxyz"

"""
	lampstate2string(lampstate::Integer, args::Integer)

Convert binary coded `lampstate` into a readable string. `args` tells the number of distinct inputs.
# Examples
```jldoctest
julia> lampstate2string(0b1111, 4)
"abcd"

julia> lampstate2string(0b11101, 4)
"~acd"

julia> lampstate2string(0b10000, 4)
"~"
```
"""
function lampstate2string(lampstate::Integer, args::Integer)
	ret = ifelse(isodd(lampstate >> args), "~", "")
	for k in 1:args
		if isodd(lampstate)
			ret *= alphabet[k]
		end
		lampstate >>= 1
	end
	return ret
end

import Base: Fix2
filtercolor(lampstate::Integer, mask::Integer) = lampstate & mask
filtercolor(mask::Integer) = Fix2(filtercolor, mask)

"""
	hascolor(lampstate::Integer, mask::Integer) = lampstate & mask
	hascolor(mask::Integer) = Fix2(hascolor, mask)
	hascolor(G::AbstractGate, mask::Integer) = any(hascolor(mask), lampstates(G))

Check if some lamp is connected to some wire (combination), or if some gate has a such lamp.
"""
hascolor(lampstate::Integer, mask::Integer) = filtercolor(lampstate, mask) == mask
hascolor(mask::Integer) = Fix2(hascolor, mask)
hascolor(G::AbstractGate, mask::Integer) = any(hascolor(mask), lampstates(G))

"""
	hasallcolor(G::AbstractGate, mask::Integer)
	hasallcolor(mask::Integer) = Fix2(hasallcolor, mask)

Check if some gate is connect to some wires.
"""
hasallcolor(G::AbstractGate, mask::Integer) = mapreduce(filtercolor(mask), |, lampstates(G)) == mask
hasallcolor(mask::Integer) = Fix2(hasallcolor, mask)
