function write_load_data(path::AbstractString,settings::Dict,demand_df::DataFrame,demand_country_zone_map::DataFrame,repetition_data::DataFrame)

    filename=joinpath(path,"Load_data_xlsx.xlsx")

    XLSX.openxlsx(filename,mode="w") do xf
        sheet=xf[1]
        sheet[1,:]=["Voll","Demand_Segment","Cost_of_Demand_Curtailment_per_MW","Max_Demand_Curtailment","Time_Index"]
        sheet[2,1]=settings["Voll"]
        sheet["B2",dim=1]=settings["Demand_Segment"]
        sheet["C2",dim=1]=settings["Cost_of_demand_Curt"]
        sheet["D2",dim=1]=settings["Max_Demand_Curt"]
        sheet["E2",dim=1]=collect(1:min(settings["Truncate"],8760))
        for i in 1:size(demand_country_zone_map)[1]
            sheet[1,i+5]=string("Load_MW_z",demand_country_zone_map[i,:zone])
            sheet[2,i+5,dim=1]=demand_df[demand_df.YearWSdemand.==repetition_data.Year_WS,Symbol(demand_country_zone_map[i,:Country])].*repetition_data[1,Symbol(demand_country_zone_map[i,:Country])]
        end
    end
    
    load_xls=DataFrame(XLSX.readtable(filename,"Sheet1",header=true))
    outfile=joinpath(path,"Load_data.csv")
    rm(filename,force=true)
    CSV.write(outfile,load_xls)

end