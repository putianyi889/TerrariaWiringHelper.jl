sum(v::Z2Vector) = isodd(count_ones(v.data))
prod(v::Z2Vector) = v.data == datamask
