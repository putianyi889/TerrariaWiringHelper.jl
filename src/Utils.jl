@inline AND(args::Bool...) = all(args)
@inline XOR(args::Bool...) = sum(args) == 1

"""
	logicsymb(::typeof(AND|XOR)|::CombGate)

Return `'&'` or `'^'` according to input.
"""
logicsymb(::typeof(AND)) = '&'
logicsymb(::typeof(XOR)) = '^'

"""
    fuse(input::Integer)

Return the state of a tile connected to multiple wires. Each bit of the input represents the state of a wire.

# Examples
```jldoctest
julia> TerrariaWiringHelper.fuse(0b0110)
false

julia> TerrariaWiringHelper.fuse(0b1011)
true
```
"""
@inline fuse(input::Integer) = isodd(count_ones(input))

"""
    fuse(setup::Integer, input::Integer) = fuse(setup & input)

Return the state of a tile connected to multiple wires. Each bit of `setup` represents the state of a wire, and each bit of `input` represents the connection of a wire to the tile.
"""
@inline fuse(setup::Integer, input::Integer) = fuse(setup & input)
