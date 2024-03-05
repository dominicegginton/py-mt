#!/usr/bin/env python

from fastapi import FastAPI

import time
from random import Random
from math import ldexp

import multiprocessing as mp

app = FastAPI()

class FullRandom(Random):
    def random(self):
        mantissa = 0x10_0000_0000_0000 | self.getrandbits(52)
        exponent = -53
        x = 0
        while not x:
            x = self.getrandbits(32)
            exponent += x.bit_length() - 32
        return ldexp(mantissa, exponent)

def work(_):
    prime_numbers = []
    for num in range(2, 10000):
        if num > 1:
            for i in range(2, num):
                if (num % i) == 0:
                    break
            else:
                random_number = FullRandom()
                num = num * random_number.random()
                prime_numbers.append(num)
    return prime_numbers

@app.get("/")
def multi_prime_number(multi: int, mt = False):
    startTime = time.time()

    if not mt:
        prime_numbers = []
        for _ in range(multi):
            prime_numbers.append(work(None))
    else:
        with mp.Pool(multi) as p:
            prime_numbers = p.map(work, [None] * multi)

    endTime = time.time()
    totalTime = endTime - startTime

    return {
        "prime_numbers": prime_numbers,
        "time": totalTime,
        "mt": mt,
        "multi": multi
    }

@app.get("/health")
def health_check():
    return {"status": "ok"}

if __name__ == "__main__":
    host = "localhost"
    port = 8000
    print(f"Running on {host}:{port}")

    import uvicorn
    uvicorn.run(app, host=host, port=port)
