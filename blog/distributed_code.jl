using Distributed
using ClusterManagers
using Plots
include("main.jl")

addprocs(SlurmManager(8), exeflags=["--project"])

@everywhere include("shared_distributed_code.jl")

function simple_monte_carlo_dist(n, T)
	x = dzeros(n) # Creates a Distributed Array (DArray) of zeros
	random_walk!(x, T) # Same fn as before, but different type of `x`
	return x
end
function add_dist_benchmark!(df)
    function bench_julia(args)
        n, T = args
        time = @belapsed simple_monte_carlo_dist($n, $T);
        GC.gc();
        return time;
    end
    sym = :times_jl_dist_ns
    if hasproperty(df, sym)
        is_missing_indexer = ismissing.(df[:, sym])
        df[is_missing_indexer, sym] = bench_julia.(Iterators.zip(df.n[is_missing_indexer], df.T[is_missing_indexer])) .* 1e9;
    else
        df[:, sym] = bench_julia.(Iterators.zip(df.n, df.T)) .* 1e9;
    end

    nothing
end

df = load_bench()

add_dist_benchmark!(df)

save_bench(df, "test.csv")