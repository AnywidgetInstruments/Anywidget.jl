"""
    Anywidget

Host [anywidget](https://anywidget.dev) front-end modules (AFM) from Julia. An
AFM is an ES module exporting `{ initialize?, render }` that drives a model
provided by the host. This package describes such modules ([`FrontendModule`](@ref)),
binds them to trait dictionaries ([`AbstractAnywidget`](@ref),
[`anywidget`](@ref)), and hosts them:

- as standalone HTML, in any environment that shows HTML;
- in Kaimon Slate notebooks, through SlateAFM (package extension on
  SlateExtensionsBase).

Published anywidgets are loaded from PyPI without Python
([`pypi_anywidget`](@ref)): the wheel and the class source are read as data.

```julia
using Anywidget
counter = FrontendModule("counter"; source = \"\"\"
export default { render({ model, el }) { el.textContent = model.get("count"); } };
\"\"\")
anywidget(counter; count = 1)
```
"""
module Anywidget

using Base64: base64encode
using Downloads: Downloads
using JSON: JSON
using SHA: SHA
using UUIDs: uuid4
using p7zip_jll: p7zip_jll

export FrontendModule, set_asset_base!
export AbstractAnywidget, afm_module, widget_traits, message_id, anywidget
export Message, encode_buffer, send_message, set_transport!
export html_page
export pypi_module, pypi_anywidget

include("modules.jl")
include("widgets.jl")
include("messages.jl")
include("html.jl")
include("pylit.jl")
include("pypi.jl")

end # module
