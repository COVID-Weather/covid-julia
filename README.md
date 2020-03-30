# covid-julia

This repository contains scripts for COVID-19 data analysis and modeling with the [julia programming language](https://julialang.org).

## Installing julia packages

After [cloning this repository](https://help.github.com/en/github/creating-cloning-and-archiving-repositories/cloning-a-repository) and [installing `julia`](https://julialang.org/downloads/), open a terminal and type
```
julia --project -e 'using Pkg; Pkg.instantiate();'
```
to install the julia packages used by scripts in this repository. 

## Downloading 

Open a terminal and type
```
git clone https://github.com/CSSEGISandData/COVID-19.git
```
to download [COVID-19 data compiled by the Johns Hopkins University Center for Systems Science and Engineering](https://github.com/CSSEGISandData/COVID-19) into the directory `/COVID-19`.

Finally, run `.jl` scripts from the julia REPL.
