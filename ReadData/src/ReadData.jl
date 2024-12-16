module ReadData

using CSV
using DataFrames
using XLSX
using YAML
using Statistics
using CategoricalArrays


export read_repetitions
include("./read_repetitions/read_repetitions.jl")

export read_excel
include("./read_excel/read_excel.jl")

export read_capacity_TYNDP
include("./read_capacity_TYNDP/read_capacity_TYNDP.jl")

export read_capacity_ERAA
include("./read_capacity_ERAA/read_capacity_ERAA.jl")

export read_variability
include("./read_variability/read_variability.jl")

export read_demand_ERAA
include("./read_demand_ERAA/read_demand_ERAA.jl")

export read_network_ERAA
include("./read_network_ERAA/read_network_ERAA.jl")

export write_load_data
include("./write_load_data/write_load_data.jl")

export write_network
include("./write_network/write_network.jl")

export write_variability
include("./write_variability/write_variability.jl")

export write_generators_data
include("./write_generators/write_generators_data.jl")

export write_fuel_price_data
include("./write_fuel_price_data/write_fuel_price_data.jl")

export do_demand_map
include("./do_demand_map/do_demand_map.jl")


export run_case
include("./run_case/run_case.jl")



end # module


