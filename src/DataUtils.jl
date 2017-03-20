__precompile__(true)

module DataUtils


using DataTables
import DataFrames
import DataArrays


import Base.convert
import Base.serialize
import Base.deserialize
import Base.Dict


include("utils.jl")
include("dfutils.jl")
include("tsutils.jl")
include("dffilters.jl")
include("featherwrap.jl")



end
