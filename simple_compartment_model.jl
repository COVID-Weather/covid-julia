using Agents, Random, Distributions

mutable struct Human <: AbstractAgent
           id :: Int
       status :: Symbol # :susceptible, :infected, or :removed
    infection :: Float64
end

Random.seed!(123)

function SIRModel(; 
                   humans = 1000,         # Number of susceptible
                   infected = 10,           # Number of infected
                   contact_rate = 0.1,
                   probability_of_infection = 0.1,
                   initial_infection = Uniform(0, 1) # Probability distribution for time-since-infected
                  )

    model_properties = Dict(
                            :contact_rate             => contact_rate,
                            :probability_of_infection => probability_of_infectiocontact_rate,
                            :total                    => humans,
                            :infected                 => infected,
                           )

    model = ABM(Human, scheduler=fastest, properties=model_properties)

    # Initialize susceptible population
    susceptible = humans - infected

    for i = 1:susceptible
        add_agent!(model, :susceptible, 0.0)
    end

    # Initialize infected population
    for i = 1:infected
        add_agent!(model, :infected, rand(initial_infection))
    end

    return model
end

function agent_step!(agent, m)

    contacted = rand(Poisson(m.infected, m.contact_rate))

    if status == :removed 
        return nothing
    elseif status  == :susceptible
        
        
        # agent may become infected
    elseif status == :infected
        # agent may become removed
    end

    return nothing
end

N = 5
M = 2000

agent_properties = [:wealth]

model = wealth_model(numagents=M)

data = step!(model, agent_step!, N, agent_properties)

data[end-20:end, :]

# What we mostly care about is the distribution of wealth,
# which we can obtain for example by doing the following query:

wealths = filter(x -> x.step == N, data)[!, :wealth]

# and then we can make a histogram of the result.
# With a simple visualization we immediatelly see the power-law distribution:

using UnicodePlots

UnicodePlots.histogram(wealths)

# ## Core structures, with space
# We now expand this model to (in this case) a 2D grid. The rules are the same
# but agents exchange wealth only with their neighbors.
# We therefore have to add a `pos` field as the second field of the agents:

mutable struct WealthInSpace <: AbstractAgent
    id::Int
    pos::NTuple{2, Int}
    wealth::Int
end

function wealth_model_2D(;dims = (25,25), wealth = 1, M = 1000)
    space = GridSpace(dims, periodic = true)
    model = ABM(WealthInSpace, space; scheduler = random_activation)

    for i in 1:M # add agents in random nodes
        add_agent!(model, wealth)
    end

    return model
end

model2D = wealth_model_2D()

# The agent actions are a just a bit more complicated in this example.
# Now the agents can only give wealth to agents that exist on the same or
# neighboring nodes (their "neighbhors").

function agent_step_2d!(agent, model)
    agent.wealth == 0 && return # do nothing
    agent_node = coord2vertex(agent.pos, model)
    neighboring_nodes = node_neighbors(agent_node, model)
    push!(neighboring_nodes, agent_node) # also consider current node
    rnode = rand(neighboring_nodes) # the node that we will exchange with
    available_ids = get_node_contents(rnode, model)
    if length(available_ids) > 0
        random_neighbor_agent = model[rand(available_ids)]
        agent.wealth -= 1
        random_neighbor_agent.wealth += 1
    end
end

# ## Running the model with space
using Random
Random.seed!(5)
init_wealth = 4
model = wealth_model_2D(;wealth = init_wealth)
agent_properties = [:wealth, :pos]
data = step!(model, agent_step!, 10, agent_properties, when = [1, 5, 10], step0=false)
data[end-20:end, :]

# Okay, now we want to get the 2D spatial wealth distribution of the model.
# That is actually straightforward:
function wealth_distr(data, model, n)
    W = zeros(Int, size(model.space))
    for row in eachrow(filter(r -> r.step == n, data)) # iterate over rows at a specific step
        W[row.pos...] += row.wealth
    end
    return W
end

W1 = wealth_distr(data, model2D, 1)
W5 = wealth_distr(data, model2D, 5)
W10 = wealth_distr(data, model2D, 10)

#

using Plots
Plots.heatmap(W1)

#

Plots.heatmap(W5)

#

Plots.heatmap(W10)

# What we see is that wealth gets more and more localized.
