function write_variability(path::AbstractString,variability_df::DataFrame,Year_WS::Int64)

    CSV.write(joinpath(path,"Generators_variability.csv"),variability_df[variability_df.YearWS.==Year_WS,:][:,2:size(variability_df)[2]])


end