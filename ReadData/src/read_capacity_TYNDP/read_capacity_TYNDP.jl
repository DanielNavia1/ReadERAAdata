function read_capacity_TYNDP(path::AbstractString,mysettings::Dict)

    Gen_characteristics_excel_path=joinpath(path,"Generator_characteristics_TYNDP.xlsx")
    raw_GenCharacteristics_excel=read_excel(Gen_characteristics_excel_path)
    raw_GenCharacteristics=DataFrame(XLSX.gettable(raw_GenCharacteristics_excel["Hoja1"]))
    
    Modelling_excel_path=joinpath(path,"220310_Updated_Electricity_Modelling_Results.xlsx")
    raw_Modelling_excel=read_excel(Modelling_excel_path)
    raw_capacity=DataFrame(XLSX.gettable(raw_Modelling_excel["Capacity & Dispatch"]))

    filt_capacity=raw_capacity[(raw_capacity.Year.==mysettings["RunYear_TYNDP"]).&
    (raw_capacity."Climate Year".==mysettings["RunClimateYear"]).&
    (raw_capacity.Scenario.==mysettings["RunScenario"]).&
    (raw_capacity.Parameter.==mysettings["RunParameter"]),:]

    filt_capacity=filt_capacity[in.(filt_capacity.Node,Ref(mysettings["CapCountryList"])),:]
    filt_capacity.Fuel=replace.(filt_capacity.Fuel," "=>"")

    select!(filt_capacity,Cols(:Node,:Fuel,:Value))

    generators_data=rightjoin(filt_capacity,raw_GenCharacteristics,on=:Fuel)

    generators_data.region=copy(SubString.(generators_data.Node,1,2))

    generators_data.Resource=copy(string.(generators_data.region,generators_data.Fuel))

    generators_data.Existing_Cap_MW=copy(generators_data.Value)

    capacity_df=select!(generators_data,Not([:Node,:Value]))


    return capacity_df

end