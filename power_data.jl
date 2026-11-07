# Data file for the electric power production and transmission planning
# project (TMA947 / MMG621 - Nonlinear optimization).
#
# Network: 11 nodes, 15 transmission lines, 9 generators, 7 consumers.
# All quantities are already given in normalized (per-unit) values.

nodes = 1:11

# Transmission line data: (from, to, b_kl, g_kl).
# b_kl = b_lk and g_kl = g_lk (the lines are physically symmetric);
# the direction only matters for the power-flow formulas below.
edges = [
    (1, 2, -20.1, 4.12),
    (1, 11, -22.3, 5.67),
    (2, 3, -16.8, 2.41),
    (2, 11, -17.2, 2.78),
    (3, 4, -11.7, 1.98),
    (3, 9, -19.4, 3.23),
    (4, 5, -10.8, 1.59),
    (5, 6, -12.3, 1.71),
    (5, 8, -9.2, 1.26),
    (6, 7, -13.9, 1.11),
    (7, 8, -8.7, 1.32),
    (7, 9, -11.3, 2.01),
    (8, 9, -7.7, 4.41),
    (9, 10, -13.5, 2.14),
    (10, 11, -26.7, 5.06),
]

# Generators: name => (node, maximum active-power capacity [pu], cost [SEK/pu])
generators = Dict(
    "G1" => (node = 2, cap = 0.02, cost = 175.0),
    "G2" => (node = 2, cap = 0.15, cost = 100.0),
    "G3" => (node = 2, cap = 0.08, cost = 150.0),
    "G4" => (node = 3, cap = 0.07, cost = 150.0),
    "G5" => (node = 4, cap = 0.04, cost = 300.0),
    "G6" => (node = 5, cap = 0.17, cost = 350.0),
    "G7" => (node = 7, cap = 0.17, cost = 400.0),
    "G8" => (node = 9, cap = 0.26, cost = 300.0),
    "G9" => (node = 9, cap = 0.05, cost = 200.0),
)

# Consumers: name => (node, active-power demand [pu])
consumers = Dict(
    "C1" => (node = 1, demand = 0.10),
    "C2" => (node = 4, demand = 0.19),
    "C3" => (node = 6, demand = 0.11),
    "C4" => (node = 8, demand = 0.09),
    "C5" => (node = 9, demand = 0.21),
    "C6" => (node = 10, demand = 0.05),
    "C7" => (node = 11, demand = 0.04),
)

# Bounds
v_lb, v_ub = 0.98, 1.02      # voltage amplitude [vu]
theta_lb, theta_ub = -pi, pi # voltage phase angle [rad]
q_frac = 0.03                # reactive power = +/- 3% of a generator's capacity
