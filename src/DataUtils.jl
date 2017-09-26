__precompile__(true)

module DataUtils

# using Requires
using DataFrames
# import Feather

import Base.convert
import Base.serialize
import Base.deserialize
import Base.Dict


include("utils.jl")
include("tsutils.jl")

include("dfutils.jl")
include("dffilters.jl")
# include("tokenize.jl")

# include("dataframes_compat.jl")
# include("featherwrap.jl")


end # module DataUtils
