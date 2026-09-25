using Documenter
using DocumenterLandingPage
using Anywidget

const PAGES = [
    "Home" => "index.md",
    "Getting started" => "getting-started.md",
    "Hosts" => "hosts.md",
    "Writing a widget package" => "packages.md",
    "API reference" => "api.md",
    "Specification" => "specification.md",
    "Roadmap" => "roadmap.md",
]

# Source links need a commit; a fresh clone without one builds without them.
has_commit = success(pipeline(`git -C $(dirname(@__DIR__)) rev-parse --verify -q HEAD`; stdout=devnull))
remotes = has_commit ? (;) : (; remotes=nothing)

makedocs(;
    remotes...,
    repo=Remotes.GitHub("s-celles", "Anywidget.jl"),
    sitename="Anywidget.jl",
    authors="Sébastien Celles",
    modules=[Anywidget],
    format=Documenter.HTML(; prettyurls=true, canonical="https://s-celles.github.io/Anywidget.jl", edit_link="main"),
    plugins=[LandingPage()],
    pages=PAGES,
    checkdocs=:exports,
    warnonly=false,
)

# llms.txt and llms-full.txt
const SRC = joinpath(@__DIR__, "src")
const BUILD = joinpath(@__DIR__, "build")
summary = """
# Anywidget.jl

> Host anywidget front-end modules (AFM) from Julia: standalone HTML in any environment showing HTML,
> and Kaimon Slate notebooks through SlateAFM. Custom messages with binary buffers.

$(join(("- [$(title)](./$(page == "index.md" ? "" : first(splitext(page)) * "/"))" for (title, page) in PAGES), "\n"))
- [Full documentation as one text file](./llms-full.txt)
"""
full = join(("<!-- Source: $(page) -->\n\n" * read(joinpath(SRC, page), String) for (_, page) in PAGES), "\n\n")
write(joinpath(BUILD, "llms.txt"), summary)
write(joinpath(BUILD, "llms-full.txt"), full)

if get(ENV, "GITHUB_ACTIONS", "false") == "true"
    deploydocs(; repo="github.com/s-celles/Anywidget.jl.git", devbranch="main", push_preview=true)
end
