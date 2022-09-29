#include <iostream>
#include <iomanip>
#include <string>
#include <map>
#include <random>
#include <cmath>
#include <chrono>
#include <fstream>

using namespace std::chrono;

double *random_walk(size_t n, size_t T, std::normal_distribution<double> randn, std::mt19937_64 rng)
{
    double *x = new double[n];
    for (size_t i = 0; i < n; i++)
    {
        double x_t = 0.0;
        for (size_t t = 0; t < T; t++)
        {
            x_t += randn(rng);
        }
        x[i] = x_t;
    }
    return x;
}

double measure_random_walk_time(size_t n, size_t T, size_t repeats)
{
    std::random_device rd{};
    std::mt19937_64 rng{rd()};
    std::normal_distribution<> randn{0, 1};
    double min_time = MAXFLOAT;

    for (size_t r = 0; r < repeats; r++)
    {
        auto start = high_resolution_clock::now();
        double *x = random_walk(n, T, randn, rng);
        auto stop = high_resolution_clock::now();
        double duration = (double)duration_cast<nanoseconds>(stop - start).count();
        if (duration < min_time)
        {
            min_time = duration;
        }
        delete[] x; // don't leak memory
    }
    return min_time;
}

int main()
{
    std::random_device rd{};
    std::mt19937_64 rng{rd()};

    // values near the mean are the most likely
    // standard deviation affects the dispersion of generated values from the mean
    std::normal_distribution<> randn{0, 1};

    size_t repeats = 500;
    size_t ns[] {
        8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384
    };
    size_t T = 100;
    std::string filename("cpp_results.csv");
    std::fstream csv_file;

    csv_file.open(filename, std::ios_base::out);

    csv_file << "n,T,time_ns" << std::endl;

    for (size_t n:ns)
    {
        double min_time = measure_random_walk_time(n, T, repeats);
        csv_file << n << "," << T << "," << min_time << std::endl;
    }    

    csv_file.close();
}