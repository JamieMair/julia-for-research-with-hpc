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

function read_cpp_csv(filename = "cpp_results.csv")
    df = DataFrame(CSV.File(filename))
    rename!(df, :time_ns=>:times_cpp_ns)
    return df;
end

function add_benchmarks!(df)
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

function save_bench(df, filename="julia_vs_cpp_results.csv")
    CSV.write(filename, df);
end

function load_bench(filename="julia_vs_cpp_results.csv")
    return DataFrame(CSV.File(filename))
end

function compare_benches(df)
    plt = plot(df.n, df.times_cpp_ns./df.times_jl_ns, label="C++", markershape=:diamond, lw=2)
    plot!(plt, df.n, df.times_jl_ns./df.times_jl_ns, label="Julia", markershape=:circle, lw=2)
    plot!(plt; xscale=:log10, legend=:topleft)
    ylabel!(plt, "Relative Time")
    xlabel!(plt, "n")
    return plt
end