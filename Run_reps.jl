

push!(LOAD_PATH,"/home/dn406/.julia/packages")
import Pkg

Pkg.activate("../..")
Pkg.instantiate()
Pkg.status()

settings_path = joinpath(pwd(), "Settings")
src_path = "../../src/"
push!(LOAD_PATH, src_path)




using GenX
using CSV
using DataFrames

Case_number=parse(Int,ARGS[1])


case=joinpath(pwd(),"Repetitions",string(Case_number))
Generators_heading=joinpath(pwd(),"Repetitions",string(Case_number))

println("Running Case")
println(Case_number)


Case_map=DataFrame(CSV.File(joinpath(Generators_heading,"Case_map.csv")))
output_paths_df=DataFrame(outputs_path=AbstractString[])
results_map=DataFrame(step_factor=Float64[],generator_file=AbstractString[],outputs_path=AbstractString[])

for rg in 1:size(Case_map)[1]
    cp(joinpath(Generators_heading,Case_map[rg,:generator_file]),joinpath(Generators_heading,"Generators_data.csv"),force=true)
    run_genx_case!(case,output_paths_df)
    push!(results_map,[Case_map[rg,:step_factor],Case_map[rg,:generator_file],output_paths_df[rg,:outputs_path]])
    CSV.write(joinpath(case,"results_map.csv"),results_map)
end

