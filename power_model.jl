# Nonlinear optimization model for planning production and transmission of
# electric power (TMA947 / MMG621 project).
#
# Minimizes the total cost of active-power production subject to:
#   - the nonlinear AC active/reactive power-flow equations on every line,
#   - active- and reactive-power balance at every node,
#   - generator capacity and voltage/angle operating limits.

using JuMP
import Ipopt

include("power_data.jl")

gen_ids = collect(keys(generators))
cons_ids = collect(keys(consumers))

# Build an adjacency list: for each node k, the list of (neighbour l, b_kl, g_kl)
neighbors = Dict(k => Tuple{Int,Float64,Float64}[] for k in nodes)
for (k, l, b, g) in edges
    push!(neighbors[k], (l, b, g))
    push!(neighbors[l], (k, b, g))
end

the_model = Model(Ipopt.Optimizer)

# ----------------------------- Variables --------------------------------

@variable(the_model, v_lb <= v[nodes] <= v_ub)
@variable(the_model, theta_lb <= theta[nodes] <= theta_ub)

# Reference (slack) bus: the power-flow equations only depend on angle
# DIFFERENCES theta[k] - theta[l], so the model has a redundant rotational
# degree of freedom. Fixing one angle removes this redundancy (a standard
# modelling choice in AC power flow) without changing the achievable
# objective value or any physical quantity of interest.
fix(theta[1], 0.0; force = true)

@variable(the_model, 0 <= P[g = gen_ids] <= generators[g].cap)
@variable(
    the_model,
    -q_frac * generators[g].cap <= Q[g = gen_ids] <= q_frac * generators[g].cap
)

# ------------------------------ Objective --------------------------------

@objective(the_model, Min, sum(generators[g].cost * P[g] for g in gen_ids))

# ------------------- Active / reactive line-flow expressions -------------

p_flow(k, l, b, g) =
    v[k]^2 * g - v[k] * v[l] * g * cos(theta[k] - theta[l]) -
    v[k] * v[l] * b * sin(theta[k] - theta[l])

q_flow(k, l, b, g) =
    -v[k]^2 * b + v[k] * v[l] * b * cos(theta[k] - theta[l]) -
    v[k] * v[l] * g * sin(theta[k] - theta[l])

# ---------------------------- Power balance -------------------------------

@constraint(
    the_model,
    active_balance[k = nodes],
    sum(P[g] for g in gen_ids if generators[g].node == k; init = 0.0) -
    sum(consumers[c].demand for c in cons_ids if consumers[c].node == k; init = 0.0) ==
    sum(p_flow(k, l, b, g) for (l, b, g) in neighbors[k]; init = 0.0)
)

@constraint(
    the_model,
    reactive_balance[k = nodes],
    sum(Q[g] for g in gen_ids if generators[g].node == k; init = 0.0) ==
    sum(q_flow(k, l, b, g) for (l, b, g) in neighbors[k]; init = 0.0)
)

# ------------------------------- Solve ------------------------------------

optimize!(the_model)

println("Termination status: ", termination_status(the_model))
println("Optimal objective function value (total cost, SEK): ", objective_value(the_model))

println("\nGenerator dispatch:")
for g in gen_ids
    println(
        "  ", g, " (node ", generators[g].node, "): P = ",
        round(value(P[g]); digits = 5), " pu  (cap ", generators[g].cap, ")",
        "   Q = ", round(value(Q[g]); digits = 5), " pu",
    )
end

println("\nNode voltages and phase angles:")
for k in nodes
    println(
        "  Node ", k, ": v = ", round(value(v[k]); digits = 5), " vu   theta = ",
        round(value(theta[k]); digits = 5), " rad",
    )
end

println("\nActive/reactive power flow on each line (k -> l):")
for (k, l, b, g) in edges
    pkl = value(p_flow(k, l, b, g))
    plk = value(p_flow(l, k, b, g))
    qkl = value(q_flow(k, l, b, g))
    qlk = value(q_flow(l, k, b, g))
    println(
        "  (", k, ",", l, "): p_", k, l, " = ", round(pkl; digits = 5),
        "  p_", l, k, " = ", round(plk; digits = 5),
        "  (loss = ", round(pkl + plk; digits = 5), ")   |  q_", k, l, " = ",
        round(qkl; digits = 5), "  q_", l, k, " = ", round(qlk; digits = 5),
        "  (loss = ", round(qkl + qlk; digits = 5), ")",
    )
end

total_gen = sum(value(P[g]) for g in gen_ids)
total_dem = sum(consumers[c].demand for c in cons_ids)
println(
    "\nTotal active generation: ", round(total_gen; digits = 5),
    " pu, total demand: ", round(total_dem; digits = 5),
    " pu, total transmission losses: ", round(total_gen - total_dem; digits = 5), " pu",
)

# Dual variables (Lagrange multipliers) of the balance constraints give the
# nodal (shadow) prices of active/reactive power -- useful for further
# economic analysis, following the pattern shown in the intro example.
println("\nShadow price of active power at each node (dual of active_balance):")
for k in nodes
    println("  Node ", k, ": ", round(dual(active_balance[k]); digits = 3), " SEK/pu")
end
