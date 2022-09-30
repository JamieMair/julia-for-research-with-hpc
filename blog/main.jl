using Random
using BenchmarkTools
using Plots
using DataFrames
using CSV
using CUDA

function simple_monte_carlo(n, T)
	x = zeros(n)	
	for i in eachindex(x)
		for t in 1:T	
			x[i] += Random.randn()	
		end	
	end
	return x
end
function simple_monte_carlo_threaded(n, T)
	x = zeros(n)	
	Threads.@threads for i in eachindex(x)
		for t in 1:T	
			x[i] += Random.randn()	
		end	
	end
	return x
end

function random_walk!(x, T)
	fill!(x, zero(eltype(x))) # Set all elements of the x array to zero
	cache = similar(x) # Create a cache array of the same size and type as x
	for t in 1:T
		Random.randn!(cache) # Populate the cached memory with random numbers
		x .+= cache
	end
	return x
end
function simple_monte_carlo_array(n, T)
	x = zeros(n)
	random_walk!(x, T)
	return x
end
function simple_monte_carlo_gpu(n, T)
	x = CUDA.zeros(n) # Creates a GPU array of zeros
	random_walk!(x, T) # Same fn as before, but different type of `x`
	return x
end


function read_cpp_csv(filename = "cpp_results.csv")
    df = DataFrame(CSV.File(filename))
    rename!(df, :time_ns=>:cpp_ns)
    return df;
end

const symbol_to_line_style_mapping = Dict{Symbol, Any}(
    :times_cpp_ns => (label="C++", c=:orange, markershape=:circle),
    :times_jl_ns => (label="Serial", c=:darkred, markershape=:utriangle),
    :times_jl_threaded_ns => (label="Threaded", c=:purple, markershape=:diamond),
    :times_jl_array_ns => (label="Array", c=:darkcyan, markershape=:rect),
    :times_jl_gpu_ns => (label="GPU", c=:green, markershape=:octagon),
    :times_jl_dist_ns => (label="DArray", c=:darkblue, markershape=:dtriangle),
)

function add_serial_benchmark!(df)
    function bench_julia(args)
        n, T = args
        time = @belapsed simple_monte_carlo($n, $T);
        GC.gc();
        return time;
    end
    sym = :times_jl_ns
    
    is_missing_indexer = hasproperty(df, sym) ? ismissing.(df[:, sym]) : (x->true).(df.n)
    df[is_missing_indexer, sym] = bench_julia.(Iterators.zip(df.n[is_missing_indexer], df.T[is_missing_indexer])) .* 1e9;
    
    nothing
end
function add_threaded_benchmark!(df)
    function bench_julia(args)
        n, T = args
        time = @belapsed simple_monte_carlo_threaded($n, $T);
        GC.gc();
        return time;
    end

    sym = :times_jl_threaded_ns
    
    is_missing_indexer = hasproperty(df, sym) ? ismissing.(df[:, sym]) : (x->true).(df.n)
    df[is_missing_indexer, sym] = bench_julia.(Iterators.zip(df.n[is_missing_indexer], df.T[is_missing_indexer])) .* 1e9;

    nothing
end
function add_array_benchmark!(df)
    function bench_julia(args)
        n, T = args
        time = @belapsed simple_monte_carlo_array($n, $T);
        GC.gc();
        return time;
    end
    sym = :times_jl_array_ns
    is_missing_indexer = hasproperty(df, sym) ? ismissing.(df[:, sym]) : (x->true).(df.n)
    df[is_missing_indexer, sym] = bench_julia.(Iterators.zip(df.n[is_missing_indexer], df.T[is_missing_indexer])) .* 1e9;

    nothing
end
function add_gpu_benchmark!(df)
    function bench_julia(args)
        n, T = args
        time = @belapsed CUDA.@sync simple_monte_carlo_gpu($n, $T);
        GC.gc();
        return time;
    end
    sym = :times_jl_gpu_ns
    is_missing_indexer = hasproperty(df, sym) ? ismissing.(df[:, sym]) : (x->true).(df.n)
    df[is_missing_indexer, sym] = bench_julia.(Iterators.zip(df.n[is_missing_indexer], df.T[is_missing_indexer])) .* 1e9;

    nothing
end

function save_bench(df, filename="julia_vs_cpp_results.csv")
    CSV.write(filename, df);
end

function load_bench(filename="julia_vs_cpp_results.csv")
    return DataFrame(CSV.File(filename))
end


function compare_benches(df, symbols...; new_plot = true, kwargs...)
    plot_fn = new_plot ? plot : plot!
    
    plt = plot_fn(df.n, df.times_jl_ns./df.times_jl_ns, label=symbol_to_line_style_mapping[:times_jl_ns].label, c=symbol_to_line_style_mapping[:times_jl_ns].c, markershape=symbol_to_line_style_mapping[:times_jl_ns].markershape, lw=2)
    for sym in symbols
        label, c, markershape = symbol_to_line_style_mapping[sym]
        plot!(plt, df.n, df.times_jl_ns ./ df[:, sym], label=label, c=c, markershape=markershape, lw=2)
    end
    plot!(plt; xscale=:log10, kwargs...)
    ylabel!(plt, "Relative Speedup")
    xlabel!(plt, "n")
    return plt
end

function create_cpp_plot(df)
    plt = plot(df.n, df.times_jl_ns, label="Julia", c=symbol_to_line_style_mapping[:times_jl_ns].c, markershape=symbol_to_line_style_mapping[:times_jl_ns].markershape, lw=2)
    plot!(df.n, df.times_cpp_ns, label="C++", c=symbol_to_line_style_mapping[:times_cpp_ns].c, markershape=symbol_to_line_style_mapping[:times_jl_ns].markershape, lw=2, legend=:topleft, xscale=:log10, yscale=:log10)
    xticks!(10 .^ (1:10))
    xlabel!("n")
    ylabel!("Time (ns)")
    savefig("figures/monte_carlo_cpp.png")
    return plt
end
function create_threaded_plot(df; num_threads=Threads.nthreads())
    plt = plot(df.n, df.n ./ df.n .* num_threads, label="# Threads", linestyle=:dash, lw=2)
    plt = compare_benches(df, :times_cpp_ns, :times_jl_threaded_ns; legend=:topleft, new_plot=false)
    
    xticks!(10 .^ (1:10))
    savefig("figures/monte_carlo_threaded.png")
    return plt
end

function create_array_plot(df; num_threads=Threads.nthreads())
    plt = plot(df.n, df.n ./ df.n .* num_threads, label="# Threads", linestyle=:dash, lw=2)
    plt = compare_benches(df, :times_cpp_ns, :times_jl_threaded_ns, :times_jl_array_ns,; legend=:topleft, new_plot=false)
    
    xticks!(10 .^ (1:10))
    savefig("figures/monte_carlo_array.png")
    
    return plt
end

function create_gpu_plot(df; num_threads=Threads.nthreads())
    plt = plot(df.n, df.n ./ df.n .* num_threads, label="# Threads", linestyle=:dash, lw=2)
    plt = compare_benches(df, :times_cpp_ns, :times_jl_threaded_ns, :times_jl_array_ns, :times_jl_gpu_ns; legend=:topleft, new_plot=false, yscale=:log10)
    xticks!(10 .^ (1:10))
    
    savefig("figures/monte_carlo_gpu.png")
    return plt
end

function create_dist_plot(df; num_threads=Threads.nthreads())
    plt = plot(df.n, df.n ./ df.n .* num_threads, label="# Cores", linestyle=:dash, lw=2)
    plt = compare_benches(df, :times_cpp_ns, :times_jl_threaded_ns, :times_jl_array_ns, :times_jl_gpu_ns, :times_jl_dist_ns; legend=:topleft, new_plot=false, yscale=:log10)
    xticks!(10 .^ (1:10))
    
    savefig("figures/monte_carlo_dist.png")
    return plt
end

function plot_all()
    df = load_bench()
    display(create_cpp_plot(df))
    display(create_threaded_plot(df))
    display(create_array_plot(df))
    display(create_gpu_plot(df))
    display(create_dist_plot(df))
    nothing
end