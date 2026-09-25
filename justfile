set shell := ["bash", "-cu"]

julia := env_var_or_default("JULIA", "julia")

default:
    @just --list

# Install the package dependencies
instantiate:
    {{julia}} --project=. -e 'using Pkg; Pkg.instantiate()'

# Unit tests (TestItemRunner)
test:
    {{julia}} --project=. -e 'using Pkg; Pkg.test()'

# Unit tests on the LTS release (needs juliaup)
test-lts:
    julia +1.10 --project=. -e 'using Pkg; Pkg.test()'

# Tests of the Kaimon Slate extension (Julia >= 1.12)
test-slate:
    {{julia}} --project=test/slate -e 'using Pkg; Pkg.instantiate()'
    {{julia}} --project=test/slate test/slate/runtests.jl

# Build the documentation (with llms.txt and llms-full.txt)
docs:
    {{julia}} --project=docs -e 'using Pkg; Pkg.instantiate()'
    {{julia}} --project=docs docs/make.jl

# Format the code
format:
    {{julia}} --startup-file=no -e 'using Pkg; Pkg.activate(; temp = true); Pkg.add(name = "JuliaFormatter", version = "2"); using JuliaFormatter; format(".", verbose = true)'

# Check the formatting
format-check:
    {{julia}} --startup-file=no -e 'using Pkg; Pkg.activate(; temp = true); Pkg.add(name = "JuliaFormatter", version = "2"); using JuliaFormatter; format(".", overwrite = false) || exit(1)'

# Everything run before a commit
check: format-check test test-slate docs
