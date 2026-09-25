@testitem "Aqua (AW-QA-002)" begin
    using Aqua
    Aqua.test_all(Anywidget)
end

@testitem "core dependencies (AW-GEN-002)" begin
    using TOML
    project = TOML.parsefile(joinpath(pkgdir(Anywidget), "Project.toml"))
    @test Set(keys(project["deps"])) ⊆ Set(["JSON", "Base64", "UUIDs", "Downloads", "SHA", "p7zip_jll"])
    @test haskey(project["weakdeps"], "SlateExtensionsBase")
end

@testitem "unofficial status stated (AW-GEN-004)" begin
    root = pkgdir(Anywidget)
    for f in ("README.md", joinpath("docs", "src", "index.md"))
        @test occursin("not affiliated", replace(read(joinpath(root, f), String), r"\s+" => " "))
    end
end
