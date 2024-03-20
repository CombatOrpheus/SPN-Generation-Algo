# SPN-Generation-Algo
An Octave implementation of the algorithm described in "The Benchmark Datasets for Stochastic Petri Net Learning"

This is done mostly as a learning exercise so that I can work through the formulas and identify possible improvements for execution speed. Liberal inspiration from the available Python code, which can be found [here](https://github.com/netlearningteam/SPN-Benchmark-DS), but using appropriate idioms so that the Octave code is not unreasonably slow. 

## Reasoning
The original code is implemented in Python using Numpy, but the execution speed is not ideal for quick iteration and experimentation. Most of the improvements and idioms found in this implementation could be easily backported to the original mostly 1:1 and they would enjoy the same performance improvements. But, as said before, the final goal of this project is to have a more complete understanding of the algorithm and implement it in a compiled language, so that a single executable could be used for quick generation datasets.

## Ideas
* Specifying a binary data format could increase read/write speeds for large datasets.
* Implementing performance critical sections in C/C++ or Fortran.
