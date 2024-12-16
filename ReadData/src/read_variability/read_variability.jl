
function read_variability(path::AbstractString,settings::Dict, inputs::Dict,cap_weights::DataFrame)

    if settings["UseRegionMap"]==true
        RegionMapDF=settings["RegionMapDF"]
    end



    # Do for Wind Onshore

    sufix="Wind_Onshore"
    filename=string("PECD_Wind_Onshore_",settings["RunYear_ERAA"],"_edition 2022.1.xlsx")
    
    full_excel=XLSX.readxlsx(joinpath(path,filename))

    df=DataFrame()
    

    for z in settings["VarZoneList"][:]
        seq_df=DataFrame(XLSX.gettable(full_excel[String(z)],first_row=11,header=true))
        seq_df[!,:Time_Index]=1:size(seq_df,1)
        seq_df[!,:zone].=z
        if settings["UseRegionMap"]==true
            seq_df[!,:Resource].=string(RegionMapDF[RegionMapDF.Cap_zone.==z,:][:,:Region][1],sufix)
        else
            seq_df[!,:Resource]=string.(SubString.(seq_df.zone,1,2),sufix)
        end 
        seq_df=coalesce.(seq_df,0.0)
        df=vcat(df,seq_df,cols=:union)
    end
    
    select!(df,:Date,:Hour,:Time_Index,:zone,:Resource,Not([:Date,:Hour,:Time_Index,:zone,:Resource]))
    cols_df=size(df)[2]
    df_stack=stack(df,6:cols_df)
    #df_stack=stack(df,3:40)
    rename!(df_stack,:variable=>:YearWS)
    df_stack.YearWS=parse.(Int,df_stack.YearWS)
    df_stack=innerjoin(df_stack,cap_weights,on=[:zone,:Resource])
    df_stack=groupby(df_stack,[:Resource,:YearWS,:Time_Index])
    df_stack=combine(df_stack,[:value,:Cap_Size]=>((x,y)->(sum(x.*y)/sum(y)))=>:value_mean)
    df_stack=unstack(df_stack,:Resource,:value_mean)
    variability_df=copy(df_stack)

    # Do for Wind Offshore

    sufix="Wind_Offshore"
    filename=string("PECD_Wind_Offshore_",settings["RunYear_ERAA"],"_edition 2022.1.xlsx")

    full_excel=XLSX.readxlsx(joinpath(path,filename))

    df=DataFrame()
    
    for z in settings["VarZoneList"][:]
        seq_df=DataFrame(XLSX.gettable(full_excel[String(z)],first_row=11,header=true))
        seq_df[!,:Time_Index]=1:size(seq_df,1)
        seq_df[!,:zone].=z
        if settings["UseRegionMap"]==true
            seq_df[!,:Resource].=string(RegionMapDF[RegionMapDF.Cap_zone.==z,:][:,:Region][1],sufix)
        else
            seq_df[!,:Resource]=string.(SubString.(seq_df.zone,1,2),sufix)
        end
        seq_df=coalesce.(seq_df,0.0)
        df=vcat(df,seq_df,cols=:union)
    end
    
    select!(df,:Date,:Hour,:Time_Index,:zone,:Resource,Not([:Date,:Hour,:Time_Index,:zone,:Resource]))
    cols_df=size(df)[2]
    df_stack=stack(df,6:cols_df)
    #df_stack=stack(df,3:40)
    rename!(df_stack,:variable=>:YearWS)
    df_stack.YearWS=parse.(Int,df_stack.YearWS)
    df_stack=innerjoin(df_stack,cap_weights,on=[:zone,:Resource])
    df_stack=groupby(df_stack,[:Resource,:YearWS,:Time_Index])
    df_stack=combine(df_stack,[:value,:Cap_Size]=>((x,y)->(sum(x.*y)/sum(y)))=>:value_mean)
    df_stack=unstack(df_stack,:Resource,:value_mean)


    variability_df=innerjoin(variability_df,df_stack,on=[:YearWS,:Time_Index])

    # Do for SolarPV

    sufix="Solar_PV"
    filename=string("PECD_LFSolarPV_",settings["RunYear_ERAA"],"_edition 2022.1.xlsx")
    

    full_excel=XLSX.readxlsx(joinpath(path,filename))

    df=DataFrame()

    for z in settings["VarZoneList"][:]
        seq_df=DataFrame(XLSX.gettable(full_excel[String(z)],first_row=11,header=true))
        seq_df[!,:Time_Index]=1:size(seq_df,1)
        seq_df[!,:zone].=z
        if settings["UseRegionMap"]==true
            seq_df[!,:Resource].=string(RegionMapDF[RegionMapDF.Cap_zone.==z,:][:,:Region][1],sufix)
        else
            seq_df[!,:Resource]=string.(SubString.(seq_df.zone,1,2),sufix)
        end
        seq_df=coalesce.(seq_df,0.0)
        description=describe(seq_df)
        if isempty(description[description.nmissing.>0,:][!,:variable])
            df=vcat(df,seq_df,cols=:union)
        end
    end

    select!(df,:Date,:Hour,:Time_Index,:zone,:Resource,Not([:Date,:Hour,:Time_Index,:zone,:Resource]))
    cols_df=size(df)[2]
    df_stack=stack(df,6:cols_df)
    #df_stack=stack(df,6:43)
    rename!(df_stack,:variable=>:YearWS)
    df_stack.YearWS=parse.(Int,df_stack.YearWS)
    df_stack=innerjoin(df_stack,cap_weights,on=[:zone,:Resource])
    df_stack=groupby(df_stack,[:Resource,:YearWS,:Time_Index])
    df_stack=combine(df_stack,[:value,:Cap_Size]=>((x,y)->(sum(x.*y)/sum(y)))=>:value_mean)
    df_stack=unstack(df_stack,:Resource,:value_mean)
 

    variability_df=innerjoin(variability_df,df_stack,on=[:YearWS,:Time_Index])




    # Do for inflows into Hydro reservoirs

    df_raw_week=DataFrame()
    


    for z in settings["VarZoneList"]
        HydroPath=joinpath(path,"Hydro Inflows")
        filename=string("PEMMDB_",z,"_Hydro Inflow_",settings["RunYear_ERAA"],".xlsx")
        
        if filename in readdir(HydroPath)
            full_excel=XLSX.readxlsx(joinpath(HydroPath,filename))
        else
            continue
        end

        Hydro_type="Reservoir"
        sheet=full_excel[Hydro_type]
        reference_capacity=sheet["C6"]
        raw_variability=DataFrame(XLSX.gettable(sheet,"Q:BA";first_row=13,header=true,infer_eltypes=true))
        rename!(raw_variability,append!([Symbol("Week")],Symbol.(1982:2017)))
        if reference_capacity>0
            raw_variability[:,Not(:Week)]=(raw_variability[:,Not(:Week)].*(1000)./(24*7))./reference_capacity
        else
            raw_variability[:,Not(:Week)].=0
        end
        raw_variability[!,:Zone].=z
        
        if settings["UseRegionMap"]==true
            raw_variability[!,:Country].=RegionMapDF[RegionMapDF.Cap_zone.==z,:][:,:Region][1]
            raw_variability[!,:Fweight].=cap_weights[(cap_weights.zone.==z).&(cap_weights.Resource.==string(RegionMapDF[RegionMapDF.Cap_zone.==z,:][:,:Region][1],"Hydro_Reservoir")),:][:,:Cap_Size]
        else
            raw_variability[!,:Country].=SubString(z,1,2)
            raw_variability[!,:Fweight].=cap_weights[(cap_weights.zone.==z).&(cap_weights.Resource.==string(SubString(z,1,2),"Hydro_Reservoir")),:][:,:Cap_Size]
        end
        

        #raw_variability[!,:Fweight].=reference_capacity

        df_raw_week=vcat(df_raw_week,raw_variability,cols=:union)

    end

    df_raw_week=stack(df_raw_week,Not([:Week,:Country,:Fweight,:Zone]))
    rename!(df_raw_week,:variable=>:YearWS)
    df_raw_week=groupby(df_raw_week,[:YearWS,:Week,:Country])
    df_raw_week=combine(df_raw_week,[:value,:Fweight]=>((x,y)->(sum(x.*y)/sum(y)))=>:weighted_mean)
    df_raw_week=unstack(df_raw_week,[:YearWS,:Week],:Country,:weighted_mean,renamecols=x->string(x,"Hydro_Reservoir"))
    df_raw_week.YearWS=parse.(Int64,df_raw_week.YearWS)


    df_raw_hourly=DataFrame()

    for y in 1982:2017
        raw_variability_hourly=DataFrame(Time_Index=1:8760)
        raw_variability_hourly.Week=raw_variability_hourly.Time_Index.÷(8760÷52).+1
        raw_variability_hourly[!,:YearWS].=y
        df_raw_hourly=vcat(df_raw_hourly,raw_variability_hourly,cols=:union)
    end


    df_raw_hourly=innerjoin(df_raw_hourly, df_raw_week, on=[:Week,:YearWS])
    select!(df_raw_hourly,Not(:Week))

    variability_df=innerjoin(variability_df,df_raw_hourly,on=[:YearWS,:Time_Index])

    
    # Do for inflows into Hydro Run of River

    df_raw_week=DataFrame()
    
    for z in settings["VarZoneList"]
        
        HydroPath=joinpath(path,"Hydro Inflows")
        filename=string("PEMMDB_",z,"_Hydro Inflow_",settings["RunYear_ERAA"],".xlsx")
       
        if filename in readdir(HydroPath)
            full_excel=XLSX.readxlsx(joinpath(HydroPath,filename))
        else
            continue
        end

        Hydro_type="Run of River"
        sheet=full_excel[Hydro_type]
        reference_capacity=sheet["C6"]
        raw_variability=DataFrame(XLSX.gettable(sheet,"Q:BA";first_row=13,header=true,infer_eltypes=true))
        rename!(raw_variability,append!([Symbol("Week")],Symbol.(1982:2017)))

        if reference_capacity>0
            raw_variability[:,Not(:Week)]=(raw_variability[:,Not(:Week)].*(1000)./(24*7))./reference_capacity
        else
            raw_variability[:,Not(:Week)].=0
        end
        raw_variability[!,:Zone].=z
        
        if settings["UseRegionMap"]==true
            raw_variability[!,:Country].=RegionMapDF[RegionMapDF.Cap_zone.==z,:][:,:Region][1]
            raw_variability[!,:Fweight].=cap_weights[(cap_weights.zone.==z).&(cap_weights.Resource.==string(RegionMapDF[RegionMapDF.Cap_zone.==z,:][:,:Region][1],"Hydro_Run")),:][:,:Cap_Size]
        else
            raw_variability[!,:Country].=SubString(z,1,2)
            raw_variability[!,:Fweight].=cap_weights[(cap_weights.zone.==z).&(cap_weights.Resource.==string(SubString(z,1,2),"Hydro_Run")),:][:,:Cap_Size]
        end
        
        #raw_variability[!,:Fweight].=reference_capacity

        df_raw_week=vcat(df_raw_week,raw_variability,cols=:union)

    end

    df_raw_week=stack(df_raw_week,Not([:Week,:Country,:Fweight,:Zone]))
    rename!(df_raw_week,:variable=>:YearWS)
    df_raw_week=groupby(df_raw_week,[:YearWS,:Week,:Country])
    df_raw_week=combine(df_raw_week,[:value,:Fweight]=>((x,y)->(sum(x.*y)/sum(y)))=>:weighted_mean)
    df_raw_week=unstack(df_raw_week,[:YearWS,:Week],:Country,:weighted_mean,renamecols=x->string(x,"Hydro_Run"))
    df_raw_week.YearWS=parse.(Int64,df_raw_week.YearWS)


    df_raw_hourly=DataFrame()

    for y in 1982:2017
        raw_variability_hourly=DataFrame(Time_Index=1:8760)
        raw_variability_hourly.Week=raw_variability_hourly.Time_Index.÷(8760÷52).+1
        raw_variability_hourly[!,:YearWS].=y
        df_raw_hourly=vcat(df_raw_hourly,raw_variability_hourly,cols=:union)
    end


    df_raw_hourly=innerjoin(df_raw_hourly, df_raw_week, on=[:Week,:YearWS])
    select!(df_raw_hourly,Not(:Week))

    variability_df=innerjoin(variability_df,df_raw_hourly,on=[:YearWS,:Time_Index])

    
    
    
    
    # The remaining resources have 1 capacity factor

    CtanVarResources=inputs["RESOURCES"][(!in).(inputs["RESOURCES"],Ref(names(variability_df)))]

    for r in CtanVarResources
        variability_df[:,Symbol(r)].=1
    end

    # Print a warning if some resource is missing completely

    description=describe(variability_df)
    if !isempty(description[isnan.(description.mean),:][!,:variable])
        println("The following resources are missing...")
        println(description[isnan.(description.mean),:][!,:variable])
        println("Substitutions being carried out")
        for g in description[isnan.(description.mean),:][!,:variable]
            if occursin("Off",string(g))
                 variability_df[:,g]=variability_df[:,Symbol(replace(string(g),"Off"=>"On"))]
            end
            if occursin("Hydro",string(g))
                variability_df[:,g].=0
           end
        end
    end

    description=describe(variability_df)
    if !isempty(description[isnan.(description.mean),:][!,:variable])
        println("The following resources are STILL missing...")
        println(description[isnan.(description.mean),:][!,:variable])
    end
    



    return variability_df


end