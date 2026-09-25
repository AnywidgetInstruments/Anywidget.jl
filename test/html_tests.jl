@testitem "standalone HTML (AW-HTML-001..003, AW-HTML-006)" setup = [Fixtures] begin
    m = Fixtures.counter()
    w = Anywidget.Widget(m; count=1, label="</script><b>x</b>")
    @test showable(MIME"text/html"(), w)
    h = sprint(show, MIME"text/html"(), w)
    @test occursin("<script type=\"module\">", h)
    json_part = match(r"<script type=\"application/json\"[^>]*>(.*?)</script>"s, h).captures[1]
    @test !occursin("</", json_part)
    @test occursin("\\u003c/script", json_part)
    @test occursin("data-afm-esm=\"counter\"", h)       # inline module
    @test occursin("data-afm-css=\"counter\"", h)
    for api in ("get:", "set(", "save_changes:", "on:", "off:", "send:")
        @test occursin(api, h)
    end
    s = FrontendModule("inline"; source="export default { render({ el }) { el.textContent = 'hi'; } };")
    @test occursin("data-afm-esm=\"inline\"", sprint(show, MIME"text/html"(), Anywidget.Widget(s)))
end

@testitem "modules by URL (AW-HTML-004)" setup = [Fixtures] begin
    u = FrontendModule("remote"; esm="https://esm.sh/w@1", css=["https://example.org/w.css"])
    h = sprint(show, MIME"text/html"(), Anywidget.Widget(u))
    @test occursin("https://esm.sh/w@1", h)
    @test occursin("https://example.org/w.css", h)
    @test !occursin("data-afm-esm=\"remote\"", h)
    m = Fixtures.counter()
    set_asset_base!(m, "https://example.org/c/")
    h2 = sprint(show, MIME"text/html"(), Anywidget.Widget(m))
    @test occursin("https://example.org/c/counter.js", h2)
    @test occursin("https://example.org/c/counter.css", h2)
    @test !occursin("data-afm-esm=\"counter\"", h2)
end

@testitem "html page (AW-HTML-005)" setup = [Fixtures] begin
    m = Fixtures.counter()
    s = FrontendModule("other"; source="export default { render() {} };")
    p = html_page(Anywidget.Widget(m), Anywidget.Widget(m), Anywidget.Widget(s); title="A & B")
    @test startswith(p, "<!doctype html>")
    @test occursin("<title>A &amp; B</title>", p)
    @test count("data-afm-esm=\"counter\"", p) == 1
    @test count("data-afm-esm=\"other\"", p) == 1
    @test count("application/json", p) == 3
    path = tempname() * ".html"
    @test html_page(path, Anywidget.Widget(m)) == path
    @test isfile(path)
end
