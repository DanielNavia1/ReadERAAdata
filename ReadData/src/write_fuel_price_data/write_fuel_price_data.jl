function write_fuel_price_data(original_path::AbstractString, output_path::AbstractString,settings::Dict,repetition_data::DataFrame)

    filename=string("Fuel_Costs_Excel.xlsx")
    full_excel=XLSX.readxlsx(joinpath(original_path,filename))
    sheet=full_excel["Hoja1"]
    Fuel_Cost_Dataframe=DataFrame(XLSX.gettable(sheet,header=true,infer_eltypes=true))

    T=size(Fuel_Cost_Dataframe)[1]-1

    for f in intersect(names(Fuel_Cost_Dataframe[:,Not(["Time_Index","None"])]),names(repetition_data))
        Fuel_Cost_Dataframe[2:(T+1),Symbol(f)]=Fuel_Cost_Dataframe[2:(T+1),Symbol(f)].*repetition_data[:,Symbol(f)]
    end

    if settings["Truncate"]<8760
        Fuel_Cost_Dataframe=Fuel_Cost_Dataframe[1:(settings["Truncate"]+1),:] 
    end

    CSV.write(joinpath(output_path,"Fuels_data.csv"),Fuel_Cost_Dataframe)

end