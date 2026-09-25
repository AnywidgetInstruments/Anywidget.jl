@testitem "Aqua (AW-QA-002)" begin
    using Aqua
    Aqua.test_all(Anywidget)
end

@testitem "core dependencies (AW-GEN-002)" begin
    using TOML
    project = TOML.parsefile(joinpath(pkgdir(Anywidget), "Project.toml"))
    @test Set(keys(project["deps"])) ⊆ Set(["JSON", "Base64", "UUIDs"])
    @test haskey(project["weakdeps"], "SlateExtensionsBase")
end
