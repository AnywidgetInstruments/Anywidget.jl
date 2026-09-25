# Static reading of Python source (AW-PYPI-004..006): literals, expressions
# spanning lines, and the anywidget classes of a module. Python is never run.

"""
    NOT_LITERAL

Returned by [`python_literal`](@ref) when a Python expression is not a literal
(a call, a name, an operation).
"""
const NOT_LITERAL = :__not_a_python_literal__

"""
    python_literal(src::AbstractString)

The value of a Python literal: numbers, `True`, `False`, `None`, strings
(plain, raw, triple-quoted), lists and tuples (as `Vector{Any}`) and dicts (as
`Dict{String,Any}`), nested. Anything else gives [`NOT_LITERAL`](@ref).
"""
function python_literal(src::AbstractString)
    s = String(src)
    v, i = _lit(s, _skip(s, 1))
    return v === NOT_LITERAL || _skip(s, i) <= ncodeunits(s) ? NOT_LITERAL : v
end

# Skip spaces, newlines and comments.
function _skip(s, i)
    while i <= ncodeunits(s)
        c = s[i]
        if isspace(c)
            i = nextind(s, i)
        elseif c == '#'
            while i <= ncodeunits(s) && s[i] != '\n'
                i = nextind(s, i)
            end
        else
            break
        end
    end
    return i
end

function _lit(s, i)
    i > ncodeunits(s) && return NOT_LITERAL, i
    c = s[i]
    if c == '[' || c == '('
        return _seq(s, nextind(s, i), c == '[' ? ']' : ')')
    elseif c == '{'
        return _dict(s, nextind(s, i))
    end
    str = _string(s, i)
    str === nothing || return str
    m = match(r"^-?(?:\d[\d_]*\.?[\d_]*(?:[eE][-+]?\d+)?|\.\d+(?:[eE][-+]?\d+)?)", SubString(s, i))
    if m !== nothing
        t = replace(m.match, "_" => "")
        v = occursin(r"[.eE]", t) ? parse(Float64, t) : parse(Int, t)
        return v, i + ncodeunits(m.match)
    end
    for (word, v) in (("True", true), ("False", false), ("None", nothing))
        if startswith(SubString(s, i), word)
            j = i + ncodeunits(word)
            (j > ncodeunits(s) || !(isletter(s[j]) || isdigit(s[j]) || s[j] == '_')) && return v, j
        end
    end
    return NOT_LITERAL, i
end

function _seq(s, i, close)
    out = Any[]
    while true
        i = _skip(s, i)
        i > ncodeunits(s) && return NOT_LITERAL, i
        s[i] == close && return out, nextind(s, i)
        v, i = _lit(s, i)
        v === NOT_LITERAL && return NOT_LITERAL, i
        push!(out, v)
        i = _skip(s, i)
        i > ncodeunits(s) && return NOT_LITERAL, i
        if s[i] == ','
            i = nextind(s, i)
        elseif s[i] != close
            return NOT_LITERAL, i
        end
    end
end

function _dict(s, i)
    out = Dict{String,Any}()
    while true
        i = _skip(s, i)
        i > ncodeunits(s) && return NOT_LITERAL, i
        s[i] == '}' && return out, nextind(s, i)
        k, i = _lit(s, i)
        k === NOT_LITERAL && return NOT_LITERAL, i
        i = _skip(s, i)
        (i <= ncodeunits(s) && s[i] == ':') || return NOT_LITERAL, i
        v, i = _lit(s, _skip(s, nextind(s, i)))
        v === NOT_LITERAL && return NOT_LITERAL, i
        out[k isa AbstractString ? k : JSON.json(k)] = v
        i = _skip(s, i)
        i > ncodeunits(s) && return NOT_LITERAL, i
        if s[i] == ','
            i = nextind(s, i)
        elseif s[i] != '}'
            return NOT_LITERAL, i
        end
    end
end

# A string literal at i: (value, next index), or nothing. f-strings are not literals.
function _string(s, i)
    m = match(r"^([rRbBuU]{0,2})('''|\"\"\"|'|\")", SubString(s, i))
    m === nothing && return nothing
    prefix, q = m.captures
    raw = occursin(r"[rR]", prefix)
    j = i + ncodeunits(m.match)
    buf = IOBuffer()
    while j <= ncodeunits(s)
        if startswith(SubString(s, j), q)
            text = String(take!(buf))
            return (raw ? text : _unescape(text)), j + ncodeunits(q)
        end
        c = s[j]
        length(q) == 1 && c == '\n' && return nothing
        if c == '\\' && nextind(s, j) <= ncodeunits(s)
            k = nextind(s, j)
            print(buf, c, s[k])
            j = nextind(s, k)
        else
            print(buf, c)
            j = nextind(s, j)
        end
    end
    return nothing
end

const _ESCAPES = Dict(
    'n' => "\n",
    't' => "\t",
    'r' => "\r",
    '0' => "\0",
    '\\' => "\\",
    '\'' => "'",
    '"' => "\"",
    'a' => "\a",
    'b' => "\b",
    'f' => "\f",
    'v' => "\v",
    '\n' => "",
)

# Python escape sequences of a non-raw string; unknown escapes keep the backslash.
function _unescape(t)
    out = IOBuffer()
    i = 1
    while i <= ncodeunits(t)
        c = t[i]
        if c == '\\' && nextind(t, i) <= ncodeunits(t)
            k = nextind(t, i)
            e = t[k]
            n = if e == 'x'
                2
            elseif e == 'u'
                4
            elseif e == 'U'
                8
            else
                0
            end
            if n > 0 && k + n <= ncodeunits(t) && all(isxdigit, SubString(t, k + 1, k + n))
                print(out, Char(parse(UInt32, SubString(t, k + 1, k + n); base=16)))
                i = k + n + 1
            elseif haskey(_ESCAPES, e)
                print(out, _ESCAPES[e])
                i = nextind(t, k)
            else
                print(out, c, e)
                i = nextind(t, k)
            end
        else
            print(out, c)
            i = nextind(t, i)
        end
    end
    return String(take!(out))
end

# The expression starting at i, up to the end of its logical line: strings and
# brackets may span lines; a comment ends it.
function _expression(s, i)
    start = i
    depth = 0
    while i <= ncodeunits(s)
        c = s[i]
        str = (c in ('\'', '"') || (c in "rRbBuUfF" && i < ncodeunits(s))) ? _string(s, i) : nothing
        if str !== nothing
            i = str[2]
            continue
        end
        if c in "([{"
            depth += 1
        elseif c in ")]}"
            depth -= 1
        elseif (c == '\n' || c == '#') && depth <= 0
            break
        end
        i = nextind(s, i)
    end
    return strip(SubString(s, start, prevind(s, i)))
end

# Top-level assignments `name = expr` of a block of lines at `indent` spaces.
function _assignments(text::AbstractString, indent::Int)
    out = Dict{String,String}()
    re = Regex("^" * " "^indent * raw"([A-Za-z_]\w*)\s*(?::[^=\n]+)?=(?!=)\s*", "m")
    for m in eachmatch(re, text)
        out[m.captures[1]] = String(_expression(text, m.offset + ncodeunits(m.match)))
    end
    return out
end

"""
    PyClass

An anywidget class read from Python source: its name, the file it is in, the
assignments of its body and those of its module, and the anywidget class it
derives from (`nothing` for a direct subclass of `AnyWidget`).
"""
struct PyClass
    name::String
    file::String
    body::Dict{String,String}
    globals::Dict{String,String}
    parent::Union{Nothing,PyClass}
end

"""
    anywidget_classes(dir) -> Dict{String,PyClass}

The anywidget classes of the Python files of `dir`, keyed by name: classes
deriving from `anywidget.AnyWidget` (or `AnyWidget`), directly or through other
classes of the package (AW-PYPI-004, AW-PYPI-012).
"""
function anywidget_classes(dir::AbstractString)
    # every class of the package: name => (bases, file, body, globals)
    found = Dict{String,Tuple{Vector{String},String,Dict{String,String},Dict{String,String}}}()
    for (root, dirs, files) in walkdir(dir)
        filter!(d -> !endswith(d, ".dist-info") && !startswith(d, "."), dirs)
        for f in sort(files)
            endswith(f, ".py") || continue
            path = joinpath(root, f)
            text = read(path, String)
            occursin("class ", text) || continue
            globals = _assignments(text, 0)
            for m in eachmatch(r"^class\s+([A-Za-z_]\w*)\s*\(([^)]*)\)\s*:[^\n]*\n"m, text)
                bases = [String(strip(b)) for b in split(m.captures[2], ',') if !occursin('=', b)]
                start = m.offset + ncodeunits(m.match)
                stop = findnext(r"^\S"m, text, start)
                body = SubString(text, start, stop === nothing ? ncodeunits(text) : first(stop) - 1)
                ind = match(r"^( +)\S"m, body)
                ind === nothing && continue
                haskey(found, m.captures[1]) ||
                    (found[m.captures[1]] = (bases, path, _assignments(body, length(ind.captures[1])), globals))
            end
        end
    end
    out = Dict{String,PyClass}()
    changed = true
    while changed        # classes whose base is AnyWidget or an anywidget class already found
        changed = false
        for (name, (bases, file, body, globals)) in found
            haskey(out, name) && continue
            leaf = [last(split(b, '.')) for b in bases]
            if any(b -> b in ("anywidget.AnyWidget", "AnyWidget"), bases)
                out[name] = PyClass(name, file, body, globals, nothing)
                changed = true
            else
                i = findfirst(l -> haskey(out, l), leaf)
                i === nothing && continue
                out[name] = PyClass(name, file, body, globals, out[leaf[i]])
                changed = true
            end
        end
    end
    return out
end

# Path expression `base / "a" / "b"`, base being Path(__file__).parent (with
# more .parent, .resolve(), .absolute()) or a module-level variable holding one.
function _python_path(expr::AbstractString, cls::PyClass, depth::Int=0)
    depth > 5 && return nothing
    parts = String[]
    rest = String(expr)
    # split on top-level "/"
    level = 0
    cur = IOBuffer()
    i = 1
    while i <= ncodeunits(rest)
        str = rest[i] in ('\'', '"') ? _string(rest, i) : nothing
        if str !== nothing
            print(cur, SubString(rest, i, prevind(rest, str[2])))
            i = str[2]
            continue
        end
        c = rest[i]
        c in "([{" && (level += 1)
        c in ")]}" && (level -= 1)
        if c == '/' && level == 0
            push!(parts, strip(String(take!(cur))))
        else
            print(cur, c)
        end
        i = nextind(rest, i)
    end
    push!(parts, strip(String(take!(cur))))
    base = parts[1]
    m = match(r"^(?:pathlib\.)?Path\(\s*__file__\s*\)((?:\.(?:resolve|absolute)\(\))*)((?:\.parent)+)$", base)
    dir = if m !== nothing
        d = dirname(cls.file)
        for _ in 2:count(".parent", m.captures[2])
            d = dirname(d)
        end
        d
    elseif occursin(r"^[A-Za-z_]\w*$", base) && haskey(cls.globals, base)
        _python_path(cls.globals[base], cls, depth + 1)
    else
        nothing
    end
    dir === nothing && return nothing
    for p in parts[2:end]
        seg = python_literal(p)
        seg isa AbstractString || return nothing
        dir = joinpath(dir, seg)
    end
    return dir
end

"""
    python_asset(cls::PyClass, attr) -> (:source, text) | (:file, path) | (:missing, nothing) | (:unresolved, expr)

The front end `attr` (`"_esm"` or `"_css"`) of a class: inline text, a file of
the package, absent, or an expression that cannot be read statically
(AW-PYPI-005).
"""
function python_asset(cls::PyClass, attr::AbstractString)
    expr = get(cls.body, attr, nothing)
    if expr === nothing     # inherited from the parent class, resolved in its module
        return cls.parent === nothing ? (:missing, nothing) : python_asset(cls.parent, attr)
    end
    v = python_literal(expr)
    if v isa AbstractString
        # anywidget reads a string naming an existing file as that file
        p = joinpath(dirname(cls.file), v)
        return !occursin('\n', v) && occursin(r"\.(m?js|css)$", v) && isfile(p) ? (:file, p) : (:source, v)
    end
    p = _python_path(expr, cls)
    p !== nothing && isfile(p) && return (:file, p)
    return (:unresolved, expr)
end

const _TRAIT_DEFAULTS = Dict(
    "Int" => 0,
    "CInt" => 0,
    "Integer" => 0,
    "Float" => 0.0,
    "CFloat" => 0.0,
    "Unicode" => "",
    "CUnicode" => "",
    "Bool" => false,
    "CBool" => false,
    "List" => Any[],
    "Tuple" => Any[],
    "Dict" => Dict{String,Any}(),
    "Any" => nothing,
)

# Top-level comma-separated arguments of a call.
function _arguments(args::AbstractString)
    out = String[]
    level = 0
    cur = IOBuffer()
    i = 1
    while i <= ncodeunits(args)
        str = args[i] in ('\'', '"') ? _string(args, i) : nothing
        if str !== nothing
            print(cur, SubString(args, i, prevind(args, str[2])))
            i = str[2]
            continue
        end
        c = args[i]
        c in "([{" && (level += 1)
        c in ")]}" && (level -= 1)
        if c == ',' && level == 0
            push!(out, strip(String(take!(cur))))
        else
            print(cur, c)
        end
        i = nextind(args, i)
    end
    last = strip(String(take!(cur)))
    isempty(last) || push!(out, last)
    return out
end

"""
    python_trait_defaults(cls::PyClass) -> Dict{String,Any}

Defaults of the synced traits of a class declared with a literal first
argument (`traitlets.Int(0).tag(sync=True)`), or with no argument for the
common trait types (AW-PYPI-006).
"""
function python_trait_defaults(cls::PyClass)
    out = cls.parent === nothing ? Dict{String,Any}() : python_trait_defaults(cls.parent)
    re = r"^(?:[A-Za-z_]\w*\.)?([A-Za-z_]\w*)\((.*)\)\s*\.tag\((.*)\)$"s
    for (name, expr) in cls.body
        startswith(name, "_") && continue
        m = match(re, expr)
        m === nothing && continue
        occursin(r"\bsync\s*=\s*True\b", m.captures[3]) || continue
        args = _arguments(m.captures[2])
        kw = filter(a -> occursin(r"^[A-Za-z_]\w*\s*=(?!=)", a), args)
        pos = filter(a -> !occursin(r"^[A-Za-z_]\w*\s*=(?!=)", a), args)
        dv = findfirst(a -> startswith(a, "default_value"), kw)
        src = if dv !== nothing
            split(kw[dv], '='; limit=2)[2]
        elseif isempty(pos)
            nothing
        else
            pos[1]
        end
        v = src === nothing ? get(_TRAIT_DEFAULTS, m.captures[1], NOT_LITERAL) : python_literal(src)
        v === NOT_LITERAL || (out[name] = deepcopy(v))
    end
    return out
end
