include("utils.jl")

global_data = load_jhu_data()

hardest_hit = communities(global_data)[1:20]

missingstring(str) = ismissing(str) ? "" : "$str "

for community in hardest_hit
    @printf "%s %s\n" missingstring(community.region) missingstring(community.province)
end

close("all")
fig, axs = subplots()

plot_community_deaths(global_data, "China", "Hubei"; marker="*", linestyle="None")

plot_community_deaths(global_data, "Italy"; marker="o", alpha=0.6, linestyle="None")
plot_community_deaths(global_data, "Spain"; marker="^", alpha=0.6, linestyle="None")
plot_community_deaths(global_data, "Iran";  marker="s", alpha=0.6, linestyle="None")
plot_community_deaths(global_data, "France";  marker="+", alpha=0.6, linestyle="None")
plot_community_deaths(global_data, "United Kingdom";  marker="1", alpha=0.6, linestyle="None")

legend()

pause(0.1)

tix = xticks()
ii = [1, 11, 25, 40, 55, 64]
xticks(tix[1][ii], tix[2][ii])

ylabel("Deaths by community")
