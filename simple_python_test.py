import random
import time

def simple_monte_carlo(n, T):
    x = [0.0 for _ in range(n)]
    for i in range(n):
        for t in range(T):
            x[i] += random.gauss(0.0,1.0)
    return x

if __name__=="__main__":
    n = 1024
    T = 100
    
    repeats = 10
    total_time = 0.0
    min_time = 10000000000
    for i in range(repeats):
        start_time = time.perf_counter()
        results = simple_monte_carlo(n, T)
        end_time = time.perf_counter()
        total_time += (end_time-start_time)
        min_time = min(min_time, (end_time-start_time))
    
    print(f"The mean time was {total_time/repeats*1000}ms, the min was {min_time*1000}ms")