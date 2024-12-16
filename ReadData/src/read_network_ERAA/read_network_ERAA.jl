function read_network_ERAA(path::AbstractString,mysettings::Dict)
    
    if mysettings["UseRegionMap"]==true
        RegionMapDF=mysettings["RegionMapDF"]
    end


    file_name=string("Transfer Capacities_ERAA2022_TY",mysettings["RunYear_ERAA"],".xlsx")
    raw_excel=XLSX.readxlsx(joinpath(path,file_name))

    df_HVAC=DataFrame(XLSX.gettable(raw_excel["HVAC"],first_row=10,stop_in_empty_row=false))[[1,2,6],:]
    df_HVAC=permutedims(df_HVAC)
    df_HVAC=df_HVAC[2:nrow(df_HVAC),:]
    rename!(df_HVAC,[:x1=>:From,:x2=>:To,:x3=>:TransferCAPMW])
    df_HVAC.directline=string.(df_HVAC.From,df_HVAC.To)
    df_HVAC.line=join.(sort.(collect.(df_HVAC.directline)))
    df_HVAC=groupby(df_HVAC,:line)
    df_HVAC=combine(df_HVAC,[:From=>first=>:From,:To=>first=>:To,:TransferCAPMW=>mean=>:TransferCAPMW,:directline=>first=>:directline])
    df_HVAC.CountryFrom=SubString.(df_HVAC.From,1,2)
    df_HVAC.CountryTo=SubString.(df_HVAC.To,1,2)
    df_HVAC=df_HVAC[(in.(df_HVAC.CountryFrom,Ref(mysettings["NetCountryList"]))).&(in.(df_HVAC.CountryTo,Ref(mysettings["NetCountryList"]))),:]

    

    if mysettings["UseRegionMap"]==true
        for c in unique(df_HVAC.CountryFrom)
            replace!(df_HVAC.CountryFrom,c=>RegionMapDF[RegionMapDF.Country.==c,:][:,:Region][1])
        end
        
        for c in unique(df_HVAC.CountryTo)
            replace!(df_HVAC.CountryTo,c=>RegionMapDF[RegionMapDF.Country.==c,:][:,:Region][1])
        end
    end

    insertcols!(df_HVAC,:Typeline=>"HVAC")
    df_HVAC=df_HVAC[df_HVAC.CountryFrom.!=df_HVAC.CountryTo,:]

    df_HVDC=DataFrame(XLSX.gettable(raw_excel["HVDC"],first_row=10,stop_in_empty_row=false))[[1,2,7],:]
    df_HVDC=permutedims(df_HVDC)
    df_HVDC=df_HVDC[2:nrow(df_HVDC),:]
    rename!(df_HVDC,[:x1=>:From,:x2=>:To,:x3=>:TransferCAPMW])
    df_HVDC.directline=string.(df_HVDC.From,df_HVDC.To)
    df_HVDC.line=join.(sort.(collect.(df_HVDC.directline)))
    df_HVDC=groupby(df_HVDC,:line)
    df_HVDC=combine(df_HVDC,[:From=>first=>:From,:To=>first=>:To,:TransferCAPMW=>mean=>:TransferCAPMW,:directline=>first=>:directline])
    df_HVDC.CountryFrom=SubString.(df_HVDC.From,1,2)
    df_HVDC.CountryTo=SubString.(df_HVDC.To,1,2)
    df_HVDC=df_HVDC[(in.(df_HVDC.CountryFrom,Ref(mysettings["NetCountryList"]))).&(in.(df_HVDC.CountryTo,Ref(mysettings["NetCountryList"]))),:]


    if mysettings["UseRegionMap"]==true
        for c in unique(df_HVDC.CountryFrom)
            replace!(df_HVDC.CountryFrom,c=>RegionMapDF[RegionMapDF.Country.==c,:][:,:Region][1])
        end
        
        for c in unique(df_HVDC.CountryTo)
            replace!(df_HVDC.CountryTo,c=>RegionMapDF[RegionMapDF.Country.==c,:][:,:Region][1])
        end
    end
    
    insertcols!(df_HVDC,:Typeline=>"HVDC")
    df_HVDC=df_HVDC[df_HVDC.CountryFrom.!=df_HVDC.CountryTo,:]


    network_df=vcat(df_HVAC,df_HVDC)
    size(network_df)
    network_df=network_df[network_df.CountryFrom.!=network_df.CountryTo,:]
    network_df.directline=string.(network_df.CountryFrom,network_df.CountryTo)
    network_df.line=join.(sort.(collect.(network_df.directline)))
    network_df=groupby(network_df,:line)
    network_df=combine(network_df,[:CountryFrom=>first=>:CountryFrom,:CountryTo=>first=>:CountryTo,:TransferCAPMW=>sum=>:TransferCapMW])

    return network_df

end