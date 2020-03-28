using CSV, DataFrames, Glob, Dates, OrderedCollections, PyPlot, Printf

"""
    load_daily_data(filename, date)

Returns a `DataFrame` corresponding to the column-separated data
in `filename`, with a `date` row added and a regularized naming scheme.
"""
function load_daily_data(filename, date)
    df = CSV.read(filename, copycols=true)

    df.Date = [string(date) for row in eachrow(df)]

    province_symbol = Symbol("Province/State") ∈ names(df) ?
                      Symbol("Province/State") : 
                      :Province_State

    region_symbol = Symbol("Country/Region") ∈ names(df) ?
                    Symbol("Country/Region") : 
                    :Country_Region

    update_symbol = Symbol("Last Update") ∈ names(df) ?
                    Symbol("Last Update") : 
                    :Last_Update

    rename!(df, province_symbol => :Province)
    rename!(df, region_symbol => :Region)
    rename!(df, update_symbol => :Last_Update)

    # Regularize...
    for row in eachrow(df)
        if occursin("China", row.Region)
            row.Region = "China"
        end
    end

    return df
end

"""
    load_all_data(filename, date)

Returns an array `DataFrame`s that correspond to data from every day
since Jan 22nd, 2020, when 17 deaths were reported in Hubei, China.
"""
function load_jhu_data(dir="./COVID-19/csse_covid_19_data/csse_covid_19_daily_reports")
    filenames = glob("$dir/*.csv")
    dates = [Date(basename(name)[1:10], "m-d-y") for name in filenames]

    # Sort by date
    ii = sortperm(dates)
    filenames = filenames[ii]
    dates = dates[ii]

    return [load_daily_data(name, date) for (name, date) in zip(filenames, dates)]
end

function join_jhu_data(data; until=length(data))
    df = deepcopy(data[1])

    for i = 2:until
        @show i
        df = join(df, data[i], kind=:outer, on=intersect(names(df), names(data[i])))
    end

    return df
end
 
replacements = ("/" => "_",) # " " => "_")

function getcol(df, name)
    col = try
        getproperty(df, Symbol(name))
    catch
        getproperty(df, Symbol(replace(name, replacements...)))
    end

    return col
end

hascol(df, name) = ismissing(getcol(df, name))

function iscol(row, name, value)
    col = getcol(row, name)
    return ismissing(col) ? false : col == value
end

function colmatch(row, name1, value1, name2, value2)
    col1 = getcol(row, name1)
    col2 = getcol(row, name2)
    test = col1 == value1 && col2 == value2
    return ismissing(test) ? false : test
end

isprovince(row, province) = iscol(row, "Province", province)
isregion(row, region) = iscol(row, "Region", region)

iscommunity(row, region, province) = colmatch(row, "Region", region, "Province", province)
iscommunity(row, region, ::Missing) = iscol(row, "Region", region)

function getrowvalue(df, rowname, i=1)
    row = getrow(df, rowname)
    return val[i]
end

nonempty(data) = filter(df -> size(df, 1) > 0, data)

function provincedata(df, province)
    data = filter(row -> isprovince(row, province), df)
    return nonempty(data)
end

function regiondata(df, region)
    data = filter(row -> isregion(row, region), df)
    return nonempty(data)
end

function communitydata(df, region, province=missing)
    data = filter(row -> iscommunity(row, region, province), df)
    return nonempty(data)
end

inprovince(data, province) = map(d -> provincedata(d, province), data)
inregion(data, region) = map(d -> regiondata(d, region), data)
incommunity(data, region, province) = map(d -> communitydata(d, region, province), data)
incommunity(data, region, ::Missing) = inregion(data, region)
    
get_dates(data, i=1) = map(df -> df.Date[i], data)
get_deaths(data, i=1) = map(df -> df.Deaths[i], data)
get_confirmed(data, i=1) = map(df -> df.Confirmed[i], data)
get_recovered(data, i=1) = map(df -> df.Recovered[i], data)
last_update(data, i=1) = map(df -> getcol(df, "Last Update")[i], data)

function plot_community_deaths(global_data, region, province=missing; plot_kwargs...)

    total_community_data = incommunity(global_data, region, province)
    community_data = nonempty(total_community_data)

    deaths = get_deaths(community_data)
    dates = get_dates(community_data)

    deaths_dates = [(deaths=d[1], dates=d[2]) for d in zip(deaths, dates)]
    deaths_dates = filter(dd -> !ismissing(dd.deaths), deaths_dates)

    deaths = map(dd -> dd.deaths, deaths_dates)
    dates = map(dd -> dd.dates, deaths_dates)

    plot(dates, deaths; label=communitystring(province, region), plot_kwargs...)

    fig = gcf()
    fig.autofmt_xdate()

    return nothing
end

function communities(global_data)
    latest = global_data[end]
    sort!(latest, :Deaths, rev=true)
    return [community(row) for row in eachrow(latest)]
end

community(row) = (region=row.Region, province=row.Province)

function communitystring(province, region)
    province = ismissing(province) ? "" : "$province, "
    return @sprintf("%s%s", province, region)
end

function by_hardest_hit(data)
    latest = deepcopy(data[end])
    sort!(latest, :Deaths, rev=true)
    return latest
end

function collect_hardest_hit(data, num=10)
    latest = by_hardest_hit(data)
    #reduced = 
end
