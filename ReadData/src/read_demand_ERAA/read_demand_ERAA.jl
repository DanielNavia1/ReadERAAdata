function read_demand_ERAA(path::AbstractString,settings::Dict)
    
    file_name=string("Demand_TimeSeries_",settings["RunYear_ERAA"],"_NationalTrends_without_bat.xlsx")
    full_excel=XLSX.readxlsx(joinpath(path,file_name))
    df=DataFrame()

    if settings["UseRegionMap"]==true
        RegionMapDF=settings["RegionMapDF"]
    end



    for z in settings["VarZoneList"][:]
        seq_df=DataFrame(XLSX.gettable(full_excel[String(z)],first_row=11,header=true))
        seq_df[!,:Time_Index]=1:size(seq_df,1)
        seq_df[!,:zone].=z
        if settings["UseRegionMap"]==true
            seq_df[!,:Country].=RegionMapDF[RegionMapDF.Cap_zone.==z,:][:,:Region][1]
        else
            seq_df[!,:Country]=SubString.(seq_df.zone,1,2)
        end 
        df=vcat(df,seq_df,cols=:union)
    end

    if "2016_2" in names(df)
        select!(df,Not(Symbol("2016_2")))
    end
    

    df_stack=stack(df,3:40)
    rename!(df_stack,:variable=>:YearWSdemand)
    df_stack.YearWSdemand=parse.(Int,df_stack.YearWSdemand)
    df_stack=groupby(df_stack,[:Country,:YearWSdemand,:Time_Index])
    df_stack=combine(df_stack,:value=>sum)
    dropmissing!(df_stack)
    df_stack=unstack(df_stack,:Country,:value_sum)

    return df_stack

end