#!/bin/bash

#SBATCH --ntasks=8
#SBATCH --cpus-per-task=1
#SBATCH --mem=10G

julia --project distributed_code.jl

rm julia-*-*-*.out