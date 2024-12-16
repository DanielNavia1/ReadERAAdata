function read_capacity_ERAA(datapath::AbstractString,mysettings::Dict)

    if mysettings["UseRegionMap"]==true
        RegionMapDF=mysettings["RegionMapDF"]
    end

    Gen_characteristics_excel_path=joinpath(datapath,"Generator_characteristics_ERAA.xlsx")
    raw_GenCharacteristics_excel=read_excel(Gen_characteristics_excel_path)
    raw_GenCharacteristics=DataFrame(XLSX.gettable(raw_GenCharacteristics_excel["Hoja1"]))
    
    Modelling_excel_path=joinpath(datapath,"ERAA 2022 PEMMDB National Estimates_read.xlsx")
    sheet_read=string("TY ",mysettings["RunYear_ERAA"])
    raw_capacity=DataFrame(XLSX.readtable(Modelling_excel_path,sheet_read,first_row=4,infer_eltypes=true))
    dropmissing!(raw_capacity)
    rename!(raw_capacity,:"Resource Capacities* (MW) - Accounts for derating **"=>:Resource)
    raw_capacity=stack(raw_capacity,Not(:Resource))
    rename!(raw_capacity,:variable=>:Node)
    for key in mysettings["Generator_Categories"]
        for g in key[2]
            replace!(raw_capacity.Resource,g=>key[1])
        end
    end


    filt_capacity=raw_capacity[in.(raw_capacity.Node,Ref(mysettings["CapZoneList"])),:]
    filt_capacity.Country=SubString.(filt_capacity.Node,1,2)


    if mysettings["UseRegionMap"]==true
        for c in unique(filt_capacity.Country)
            replace!(filt_capacity.Country,c=>RegionMapDF[RegionMapDF.Country.==c,:].Region[1])
        end
    end

    cap_weights=copy(filt_capacity[in.(filt_capacity.Resource,Ref(collect(unique(raw_GenCharacteristics.Resource)))),:])
    cap_weights.Resource=string.(cap_weights.Country,cap_weights.Resource)

    rename!(cap_weights,:value=>:Cap_Size)
    rename!(cap_weights,:Node=>:zone)
    cap_weights=groupby(cap_weights,[:Resource,:zone])
    cap_weights=combine(cap_weights,:Cap_Size=>sum=>:Cap_Size)




    filt_capacity=groupby(filt_capacity,[:Resource,:Country])
    filt_capacity=combine(filt_capacity,:value=>sum)
    


    filt_capacity.Resource=replace.(filt_capacity.Resource," "=>"_")
    generators_data=innerjoin(filt_capacity,raw_GenCharacteristics,on=:Resource)
    
    generators_data.region=copy(generators_data.Country)
    generators_data.Resource=copy(string.(generators_data.region,generators_data.Resource))

    generators_data.Existing_Cap_MW=copy(generators_data.value_sum)
    generators_data.Zone=levelcode.(categorical(generators_data.region))

    raw_energy_storage=DataFrame(XLSX.readtable(Modelling_excel_path,sheet_read,first_row=31,infer_eltypes=true))
    rename!(raw_energy_storage,:"Energy Storage (MWh)"=>:Resource)
    raw_energy_storage=stack(raw_energy_storage,Not(:Resource))
    rename!(raw_energy_storage,:variable=>:Node)
    for key in mysettings["StorageHydro_Categories"]
        for g in key[2]
            replace!(raw_energy_storage.Resource,g=>key[1])
        end
    end
    
    filt_energy=raw_energy_storage[in.(raw_energy_storage.Node,Ref(mysettings["CapZoneList"])),:]
    
    filt_energy.Country=SubString.(filt_energy.Node,1,2)
    
    if mysettings["UseRegionMap"]==true
        for c in unique(filt_energy.Country)
            replace!(filt_energy.Country,c=>RegionMapDF[RegionMapDF.Country.==c,:].Region[1])
        end
    end


    filt_energy=groupby(filt_energy,[:Resource,:Country])
    filt_energy=combine(filt_energy,:value=>sum=>:EnergyStorage)
    filt_energy.region=copy(filt_energy.Country)
    filt_energy.Resource=copy(string.(filt_energy.region,filt_energy.Resource))

    generators_data=leftjoin(generators_data,filt_energy,on=:Resource,makeunique=true)
    #generators_data=generators_data[generators_data.Existing_Cap_MW.!=0,:]

    generators_data[:,[:Hydro_Energy_to_Power_Ratio]].=generators_data.EnergyStorage./generators_data.Existing_Cap_MW
    generators_data[generators_data.HYDRO.!=1,[:Hydro_Energy_to_Power_Ratio]].=0

    generators_data.Existing_Cap_MWh=copy(generators_data.EnergyStorage)
    generators_data[generators_data.STOR.!=1,[:Existing_Cap_MWh]].=0


    capacity_df=select!(generators_data,Not([:value_sum,:Country]))
    capacity_df.New_Build.=-1
    insertcols!(capacity_df,:LDS=>0)
    select!(capacity_df,Not([:Country_1,:EnergyStorage,:region_1]))
    generators_data[generators_data.Fuel.=="Uranium",:Min_Power].=mysettings["Nuclear_minimum_power"]
    

    
    return capacity_df,cap_weights
    

end