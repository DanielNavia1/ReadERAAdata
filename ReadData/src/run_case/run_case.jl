
function run_case(basepath::AbstractString,datapath::AbstractString)

    settings=YAML.load(open(joinpath(basepath,"Settings.yml")))

    if settings["UseRegionMap"]==true
        RegionMapDF=DataFrame(CSV.File(joinpath(datapath,settings["RegionMapFile"])))
        settings["RegionMapDF"]=RegionMapDF
        settings["CapZoneList"]=RegionMapDF.Cap_zone
        settings["VarZoneList"]=RegionMapDF.Var_zone
        settings["NetCountryList"]=RegionMapDF.Country
    end



    capacity_df,cap_weights=read_capacity_ERAA(datapath,settings)
    inputs=Dict()
    inputs["G"]=length(capacity_df[!,:Resource])
    inputs["RESOURCES"]=collect(skipmissing(capacity_df[!,:Resource][1:inputs["G"]]))
    inputs["COUNTRIES_NAMES"]=unique(SubString.(inputs["RESOURCES"],1,2))
    
    demand_df=read_demand_ERAA(datapath,settings)
    variability_df=read_variability(datapath,settings,inputs,cap_weights)

    network_df=read_network_ERAA(datapath,settings)


    return settings,capacity_df,variability_df,demand_df,network_df



end