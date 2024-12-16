function do_demand_map(demand_df::DataFrame)

    country_list_ordered=names(demand_df[:,3:size(demand_df)[2]])
    zone_list_ordered=collect(1:size(country_list_ordered)[1])
    demand_country_zone_map=DataFrame(Country=country_list_ordered,zone=zone_list_ordered)

    return demand_country_zone_map

end