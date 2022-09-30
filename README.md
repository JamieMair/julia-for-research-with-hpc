# Julia for research on the HPC

A brief lightning talk on using Julia for research, allowing rapid prototyping of ideas alongside high performance parallelism at any scale.

## Resources

This repository contains the raw source code (along with the raw benchmark timings and graphs) showing how Julia can be used in parallel applications. If you are coming here from the blog, checkout the `blog` subdirectory!

## How to run the code

You will need to install Julia either directly from the [website](https://julialang.org/downloads/) or install via [JuliaUp](https://github.com/JuliaLang/juliaup). After that, clone/download this repository and lauch a terminal in this folder. From the terminal, run:
```bash
julia --project
```
This will open the Julia REPL (Read-Evaluate-Print-Loop), where you can interactively run code. To install all the packages needed you can access the package manager by pressing the `]` key. You can write `instantiate` to download the packages:
```julia
] instantiate
```
or, alternatively:
```julia
using Pkg;
Pkg.instantiate();
```
You can press backspace to get out of the package manager in the REPL. If you want to use CUDA, you can download the CUDA binaries by running:
```julia
using CUDA
CUDA.versioninfo()
```
If you are following the blog, you have to move into the `blog` subfolder by running:
```julia
cd("blog")
```
Then you can get all of the functions in `blog/main.jl` by typing:
```julia
include("main.jl")
```
Explore this source code in your text editor (I recommend VS Code with the Julia extension) and you can load the timings and run the code, and experiment by changing things.
