function write_network(path::AbstractString,settings::Dict,network_df::DataFrame,demand_country_zone_map::DataFrame)
    

    line_map_df=copy(network_df)
    line_map_df.Country=line_map_df.CountryFrom
    line_map_df=innerjoin(line_map_df,demand_country_zone_map,on=:Country)
    rename!(line_map_df,:zone=>:Origin_Zone)
    line_map_df.Country=line_map_df.CountryTo
    line_map_df=innerjoin(line_map_df,demand_country_zone_map,on=:Country)
    rename!(line_map_df,:zone=>:Destination_Zone)
    
    allzones=sort(unique([line_map_df.Origin_Zone;line_map_df.Destination_Zone]))
    
    filename=joinpath(path,"Network_xlsx.xlsx")
    XLSX.openxlsx(filename,mode="w") do xf
        sheet=xf[1]
        sheet[1,:]=["Network_zones","Network_Lines","Origin_Zone","Destination_Zone","Line_Max_Flow_MW","Line_Loss_Percentage"]
        sheet["A2",dim=1]=allzones
        sheet["B2",dim=1]=collect(1:size(network_df)[1])
        sheet["C2",dim=1]=line_map_df.Origin_Zone
        sheet["D2",dim=1]=line_map_df.Destination_Zone
        sheet["E2",dim=1]=line_map_df.TransferCapMW 
        sheet["F2",dim=1]=zeros(size(network_df)[1])
    end
    load_xls=DataFrame(XLSX.readtable(filename,"Sheet1",header=true))
    rm(filename)
    outfile=joinpath(path,"Network.csv")
    CSV.write(outfile,load_xls)


end