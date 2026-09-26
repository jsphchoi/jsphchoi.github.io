module ChoiIO

using JSON
using LiveServer

const root_dir = joinpath(@__DIR__, "..")
const content_dir = joinpath(root_dir, "content")
const template_dir = joinpath(root_dir, "template")
const img_dir = joinpath(root_dir, "img")
const css_dir = joinpath(root_dir, "css")
const js_dir = joinpath(root_dir, "js")
const bib_dir = joinpath(root_dir, "bib")
const tex_dir = joinpath(root_dir, "tex")
const output_dir = joinpath(root_dir, "build")

const cv_name = "jsphchoi"
const repo_url = "git@github.com:jsphchoi/jsphchoi.github.io.git"

const KEYWORDS = [
    "{ email }" => "jsphchoi@mit.edu",
    "{ scholar }" => "https://scholar.google.com/citations?user=BTau6ocAAAAJ",
    "{ linkedin }" => "https://www.linkedin.com/in/jsphchoi/",
    "{ github }" => "https://github.com/jsphchoi",
    "{ cv }" => "/$cv_name.pdf",
]

const nav_items = [
    "Research" => "/research",
    "Software" => "/software",
    "Publications" => "/publications",
    "CV" => "/$cv_name.pdf",
]

# bib file => (heading, label); files that do not exist are skipped
const pub_sections = [
    "prep" => ("Preprints", "P"),
    "jrnl" => ("Journal Publications", "J"),
    "conf" => ("Conference Publications", "C"),
    "pres" => ("Presentations", "T"),
]

# name as printed by the abbrv style, bolded on the site and in the CV
const html_names = ["J.&nbsp;W. Choi"]
const tex_names = ["J.~W. Choi"]

"""
    cv()

Compile `tex/choi.tex` to `tex/choi.pdf`.
"""
function cv()
    @info "building CV"
    cd(tex_dir) do
        log = "build-cv.log"
        latex = `pdflatex -interaction=nonstopmode -halt-on-error $cv_name`
        run(pipeline(latex; stdout = log))
        for (f, _) in pub_sections
            isfile("$f.aux") || continue
            run(pipeline(`bibtex $f`; stdout = log, append = true))
            bbl = read("$f.bbl", String)
            write("$f.bbl", replace(bbl, (n => "{\\bf $n}" for n in tex_names)...))
        end
        run(pipeline(latex; stdout = log, append = true))
        run(pipeline(latex; stdout = log, append = true))
    end
end

"""
    build(; build_cv = true)

Render the site into `build/`.
"""
function build(; build_cv = true)
    build_cv && cv()

    @info "building website"
    rm(output_dir; recursive = true, force = true)
    mkpath(output_dir)
    cp(img_dir, joinpath(output_dir, "img"))
    cp(css_dir, joinpath(output_dir, "css"))
    cp(js_dir, joinpath(output_dir, "js"))
    pdf = joinpath(tex_dir, "$cv_name.pdf")
    isfile(pdf) && cp(pdf, joinpath(output_dir, "$cv_name.pdf"))
    touch(joinpath(output_dir, ".nojekyll"))

    for f in readdir(content_dir)
        _write_page(read(joinpath(content_dir, f), String), splitext(f)[1])
    end
    _write_page(_publications_html(), "publications")
    _write_search_index()
end

"""
    serve()

Host `build/` at `127.0.0.1:8000` with live reload.
"""
serve() = LiveServer.serve(dir = output_dir)

"""
    deploy()

Force-push `build/` to the `gh-pages` branch.
"""
function deploy()
    cd(output_dir) do
        rm(".git"; recursive = true, force = true)
        run(`git init -q -b gh-pages`)
        run(`git add -A`)
        run(`git commit -q -m "Deploy website"`)
        run(`git push -q --force $repo_url gh-pages`)
    end
end

function _write_page(content, name)
    html = replace(
        read(joinpath(template_dir, "template.html"), String),
        "{ nav }" => _nav_html("/$name"),
        "{ home }" => name == "index" ? " active" : "",
        "{ content }" => content,
    )
    html = replace(html, KEYWORDS...)
    dir = name == "index" ? output_dir : joinpath(output_dir, name)
    mkpath(dir)
    write(joinpath(dir, "index.html"), html)
end

_nav_html(active) = join(
    """<li class="nav-item"><a class="nav-link$(url == active ? " active" : "")" href="$url">$name</a></li>"""
    for (name, url) in nav_items
)

function _publications_html()
    sections = String[]
    for (f, (heading, label)) in pub_sections
        file = joinpath(bib_dir, "$f.bib")
        isfile(file) || continue
        push!(sections, "<h2>$heading</h2>\n" * _bib_html(file, label))
    end
    return "<h1>Publications</h1>\n" * join(sections, "\n")
end

function _bib_html(file, label)
    path = tempname()
    run(`bibtex2html -nf pdf pdf -q -r -s abbrv -revkeys -nodoc -nofooter -nobibsource -o $path $file`)
    html = read(path * ".html", String)
    rm(path * ".html"; force = true)
    return replace(
        html,
        r"<!--.*?-->\s*"s => "",
        (n => "<strong>$n</strong>" for n in html_names)...,
        "[<a name" => "[$label<a name",
        "<sup>*</sup>" => "*",
        "http://arxiv.org/abs/" => "https://arxiv.org/abs/",
        "http://dx.doi.org/" => "https://doi.org/",
    )
end

# Home and every nav page except the CV, as [{title, url, text}]
function _write_search_index()
    pages = ["Home" => "/"; filter(p -> !endswith(p[2], ".pdf"), nav_items)]
    index = [
        Dict(
            "title" => title,
            "url" => url,
            "text" => _page_text(read(joinpath(output_dir, lstrip(url, '/'), "index.html"), String)),
        )
        for (title, url) in pages
    ]
    write(joinpath(output_dir, "search-index.json"), JSON.json(index))
end

# Visible page text, without head, navbar, footer, and scripts
function _page_text(html)
    html = replace(html, r"<!--.*?-->"s => " ", r"<(head|nav|footer|script|style)\b.*?</\1>"is => " ")
    text = replace(html, r"<[^>]+>" => " ")
    text = replace(text, r"&#(\d+);" => m -> string(Char(parse(Int, m[3:end-1]))))
    text = replace(
        text,
        "&nbsp;" => " ",
        "&lt;" => "<",
        "&gt;" => ">",
        "&quot;" => "\"",
        "&amp;" => "&",
    )
    return strip(replace(text, r"\s+" => " "))
end

end # module
