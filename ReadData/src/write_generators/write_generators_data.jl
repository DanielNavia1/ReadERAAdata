function write_generators_data(path::AbstractString,capacity_df::DataFrame,demand_country_zone_map::DataFrame,settings::Dict)

    capacity_df0=deepcopy(capacity_df)

    for r in unique(capacity_df.region)                                                                                                                                                                                
        capacity_df[capacity_df.region.==r,[:Zone]].=demand_country_zone_map[demand_country_zone_map.Country.==r,[:zone]][1,1]                                                                                             
    end

    CSV.write(joinpath(path,"Generators_data.csv"),capacity_df)

    if settings["RunYear_ERAA"]!=2024

        steps=settings["Steps"]


        Case_map=DataFrame(step_factor=Float64[],generator_file=AbstractString[])

        for s in 1:size(steps)[1]
            for g in settings["Modifiable_Generators"]
                capacity_df[capacity_df.Resource_Type.==g,:Existing_Cap_MW]=(1+steps[s])*capacity_df0[capacity_df0.Resource_Type.==g,:Existing_Cap_MW]
                capacity_df[capacity_df.Resource_Type.==g,:Existing_Cap_MWh]=(1+steps[s])*capacity_df0[capacity_df0.Resource_Type.==g,:Existing_Cap_MWh]
            end
        CSV.write(joinpath(path,string("Generators_data",string(s),".csv")),capacity_df)
        push!(Case_map,[steps[s],string("Generators_data",string(s),".csv")])
        CSV.write(joinpath(path,"Case_map.csv"),Case_map)
        end
    end


    

end