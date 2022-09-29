using Random
using BenchmarkTools
using Plots
using DataFrames
using CSV

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

function read_cpp_csv(filename = "cpp_results.csv")
    df = DataFrame(CSV.File(filename))
    rename!(df, :time_ns=>:times_cpp_ns)
    return df;
end

function add_serial_benchmark!(df)
    function bench_julia(args)
        n, T = args
        time = @belapsed simple_monte_carlo($n, $T);
        GC.gc();
        return time;
    end

    julia_times = bench_julia.(Iterators.zip(df.n, df.T)) .* 1e9;
    df[:, :times_jl_ns] = julia_times;
    nothing
end
function add_threaded_benchmark!(df)
    function bench_julia(args)
        n, T = args
        time = @belapsed simple_monte_carlo_threaded($n, $T);
        GC.gc();
        return time;
    end

    julia_times = bench_julia.(Iterators.zip(df.n, df.T)) .* 1e9;
    df[:, :times_jl_threaded_ns] = julia_times;
    nothing
end

function save_bench(df, filename="julia_vs_cpp_results.csv")
    CSV.write(filename, df);
end

function load_bench(filename="julia_vs_cpp_results.csv")
    return DataFrame(CSV.File(filename))
end

function compare_benches(df)
    plt = plot(df.n, df.times_jl_ns ./ df.times_cpp_ns, label="C++", markershape=:diamond, lw=2)
    plot!(plt, df.n, df.times_jl_ns./df.times_jl_ns, label="Julia", markershape=:circle, lw=2)
    plot!(plt; xscale=:log10, legend=:topleft)
    ylabel!(plt, "Relative Speedup")
    xlabel!(plt, "n")
    return plt
end

function compare_benches(df, comparisons...; new_plot = true, kwargs...)
    comparison_dict = Dict(comparisons...)
    plot_fn = new_plot ? plot : plot!
    plt = plot_fn(df.n, df.times_jl_ns./df.times_jl_ns, label="Serial", markershape=:circle, lw=2)
    for (sym, label) in comparison_dict
        plot!(plt, df.n, df.times_jl_ns ./ df[:, sym], label=label, markershape=:auto, lw=2)
    end
    plot!(plt; xscale=:log10, kwargs...)
    ylabel!(plt, "Relative Speedup")
    xlabel!(plt, "n")
    return plt
end

function create_threaded_plot(df; num_threads=Threads.nthreads())
    plt = plot(df.n, df.n ./ df.n .* num_threads, label="# Threads", linestyle=:dash)
    plt = compare_benches(df, :times_cpp_ns=>"CPP", :times_jl_threaded_ns=>"Threaded"; legend=:topleft, new_plot=false)
    savefig("figures/monte_carlo_threaded.png")
    return plt
end