function checkTTAND(setup::AbstractVector{<:Integer}, inputs::AbstractVector{<:Integer}, outputs::AbstractVector{Bool})
	for (input, output) in zip(inputs, outputs)
		if AND(fuse.(setup, input)...) != output
			return false
		end
	end
	return true
end
function checkTTNAND(setup::AbstractVector{<:Integer}, inputs::AbstractVector{<:Integer}, outputs::AbstractVector{Bool})
	for (input, output) in zip(inputs, outputs)
		if AND(fuse.(setup, input)...) == output
			return false
		end
	end
	return true
end
function checkTTXOR(setup::AbstractVector{<:Integer}, inputs::AbstractVector{<:Integer}, outputs::AbstractVector{Bool})
	for (input, output) in zip(inputs, outputs)
		if XOR(fuse.(setup, input)...) != output
			return false
		end
	end
	return true
end
function checkTTNXOR(setup::AbstractVector{<:Integer}, inputs::AbstractVector{<:Integer}, outputs::AbstractVector{Bool})
	for (input, output) in zip(inputs, outputs)
		if XOR(fuse.(setup, input)...) == output
			return false
		end
	end
	return true
end

"""
	CombLogic(lamps, inputs, outputs::AbstractVector{Bool})

Return the lists of possible combinatory logics for given `inputs` and `outputs`.

# Arguments	
- `lamps::Integer`: the number of logic lamps on the gate, from `2` to `7`.
- `inputs::AbstractVector{<:Integer}`: the list of input values specified by the lower bits of entries, with a `1` in front of the first bit.
- `outputs::AbstractVector{Bool}`: the expected return values of the logic. This should have the same length as `inputs`, although it's not strictly checked.

# Example
Imagine we want to check if a 4-bit input can be divided by 3. Further, the input is expected to have only one decimal digit, i.e. in `0:9`. We don't care how the logic behaves for inputs `10:15`. The truth table would be

|  in|  out||in|out|
|:-:|:-:|:-:|:-:|:-:|
|0000| true||0101|false|
|0001|false||0110| true|
|0010|false||0111|false|
|0011| true||1000|false|
|0100|false||1001| true|

Now we try to find a configuration with least lamps.
```jldoctest
julia> inputs = 16:25; # `0:9` with the 5th last bit set to `1`

julia> outputs = [true, false, false, true, false, false, true, false, false, true];

julia> CombLogic(2, inputs, outputs) # there is no 2-lamp logic
Union{AndGate{Int64, StaticArraysCore.SVector{2, UInt8}}, XorGate{Int64, StaticArraysCore.SVector{2, UInt8}}}[]

julia> CombLogic(3, inputs, outputs) # there are 12 3-lamp logics, all of which use XOR gates
12-element Vector{Union{AndGate{Int64, StaticArraysCore.SVector{3, UInt8}}, XorGate{Int64, StaticArraysCore.SVector{3, UInt8}}}}:
 ^(~b, ad, c)
 ^(~b, abd, bc)
 ^(~ac, ad, ab)
 ^(~ac, abd, a)
 ^(~ac, cd, bc)
 ^(~ac, bcd, c)
 ^(~bd, c, a)
 ^(~bd, bc, ab)
 ^(~bd, cd, ad)
 ^(~bd, bcd, abd)
 ^(~acd, bc, c)
 ^(~acd, abd, ad)
```
See also [`CombGate`](@ref)
"""
function CombLogic(lamps::Integer, inputs::AbstractVector{<:Integer}, outputs::AbstractVector{Bool})
	args = ndigits(inputs[1], base = 2) - true
	stack = MVector{lamps, UInt8}(undef)
	top = 1
	stack[1] = 0
	ret = Vector{Union{AndGate{Int, SVector{lamps, UInt8}}, XorGate{Int, SVector{lamps, UInt8}}}}()
	cases = 1 << (args + true)
	while top > 0
		if top == lamps
			for k in 0:stack[lamps - 1]
				stack[lamps] = k
				if checkTTAND(stack, inputs, outputs)
					push!(ret, AndGate(false, args, SVector(stack)))
				elseif checkTTNAND(stack, inputs, outputs)
					push!(ret, AndGate(true, args, SVector(stack)))
				end
				if checkTTXOR(stack, inputs, outputs)
					push!(ret, XorGate(false, args, SVector(stack)))
				elseif checkTTNXOR(stack, inputs, outputs)
					push!(ret, XorGate(true, args, SVector(stack)))
				end
			end
			top = lamps - true
		elseif top == 1
			stack[1] += true
			if stack[1] > cases
				break
			else
				top = 2
			end
		else
			stack[top] += true
			if stack[top] > stack[top - 1]
				stack[top] = 0
				top -= true
			else
				top += true
			end
		end
	end
	return ret
end
