using Documenter
using TerrariaWiringHelper

makedocs(
    sitename = "TerrariaWiringHelper",
    format = Documenter.HTML(),
    modules = [TerrariaWiringHelper]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(
    repo = "github.com/putianyi889/TerrariaWiringHelper.jl.git"
)
