# jsphchoi.github.io

Joseph W Choi's website.

## Dependencies
- julia
- texlive
- bibtex2html

## Usage
```julia-repl
$ julia --project
julia> using ChoiIO
julia> ChoiIO.build()    # CV + site into build/
julia> ChoiIO.serve()    # preview at 127.0.0.1:8000
julia> ChoiIO.deploy()   # push build/ to gh-pages
```

## Layout
- `content/*.html`: page bodies, one page per file
- `template/template.html`: navbar and footer
- `bib/*.bib`: publications, shared by the site and the CV
- `tex/jsphchoi.tex`: CV
- `src/ChoiIO.jl`: links, nav items, publication sections
