using Random
using Distributed
using DistributedArrays

function random_walk!(x, T)
	fill!(x, zero(eltype(x))) # Set all elements of the x array to zero
	cache = similar(x) # Create a cache array of the same size and type as x
	for t in 1:T
		Random.randn!(cache) # Populate the cached memory with random numbers
		x .+= cache
	end
	return x
end
function random_walk!(x::DArray, T)
    if myid() == 1 # Main process (not a worker)
        SPMD.spmd(random_walk!, x, T; pids=workers())
    else
        random_walk!(localpart(x), T)
    end
end