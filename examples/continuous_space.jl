# # A simple continuous space model

using Agents, Random, Plots

mutable struct Agent <: AbstractAgent
  id::Int
  pos::NTuple{2, Float64}
  vel::NTuple{2, Float64}
  diameter::Float64
  moved::Bool
end

function model_initiation(;N=100, speed=0.005, diameter=0.01, seed=0)
  Random.seed!(seed)
  space = ContinuousSpace(2; periodic = true, extend = (1, 1))
  model = ABM(Agent, space);

  ## Add initial individuals
  for ind in 1:N
    pos = Tuple(rand(2))
    vel = sincos(2π*rand()) .* speed
    add_agent!(pos, model, vel, diameter, false)
  end

  Agents.index!(model)
  return model
end

function agent_step!(agent, model)
  move_agent!(agent, model)
  collide!(agent, model)
end

function collide!(agent, model)
  agent.moved && return
  r = space_neighbors(agent.pos, model, agent.diameter)
  length(r) == 0 && return
  # change direction
  for contactid in 1:length(r)
    contact = id2agent(r[contactid], model)
    if contact.moved == false
      agent.vel, contact.vel = (agent.vel[1], contact.vel[2]), (contact.vel[1], agent.vel[2])
      contact.moved = true
    end
  end
  agent.moved=true
end

function model_step!(model)
  for agent in values(model.agents)
    agent.moved = false
  end
end

model = model_initiation(N=100, speed=0.005, diameter=0.01)
step!(model, agent_step!, model_step!, 500)

# ## Example animation
model = model_initiation(N=200, speed=0.005, diameter=0.01);
colors = rand(200)
@time anim = @animate for i ∈ 1:100
  xs = [a.pos[1] for a in values(model.agents)];
  ys = [a.pos[2] for a in values(model.agents)];
  p1 = scatter(xs, ys, label="", marker_z=colors, xlims=[0,1], ylims=[0, 1], xgrid=false, ygrid=false,xaxis=false, yaxis=false)
  title!(p1, "Day $(i)")
  step!(model, agent_step!, model_step!, 1)
end
gif(anim, "movement.gif", fps = 8);

# ![](social_distancing.gif)
