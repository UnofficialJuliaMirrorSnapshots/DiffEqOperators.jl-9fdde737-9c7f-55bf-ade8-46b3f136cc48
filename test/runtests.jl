using SafeTestsets
import Base: isapprox

@time @safetestset "Basic Operators Interface" begin include("basic_operators_interface.jl") end
@time @safetestset "Robin Boundary Condition Operators" begin include("robin.jl") end
@time @safetestset "JacVec Operators Interface" begin include("jacvec_operators.jl") end
@time @safetestset "Composite Operators Interface" begin include("composite_operators_interface.jl") end
@time @safetestset "Derivative Operators Interface" begin include("derivative_operators_interface.jl") end
@time @safetestset "Validate and Compare Generic Operators" begin include("generic_operator_validation.jl") end
#@time @safetestset "2nd order check" begin include("2nd_order_check.jl") end
#@time @safetestset "KdV" begin include("KdV.jl") end # KdV times out and all fails
#@time @safetestset "Heat Equation" begin include("heat_eqn.jl") end
@time @safetestset "Matrix-Free Operators" begin include("matrixfree.jl") end

#=
using StaticArrays, DiffEqOperators
function isapprox(x::DerivativeOperator{T,S,LBC,RBC},y::FiniteDifference{T,S,LBC,RBC}; kwargs...) where {T<:Real,S<:StaticArrays.SVector,LBC,RBC}
    der_order           = (x,y) -> x.derivative_order == y.derivative_order
    approximation_order = (x,y) -> x.approximation_order == y.approximation_order
    dx                  = (x,y) -> !any(x.dx .!= y.dx)
    dimension           = (x,y) -> x.dimension == y.dimension
    stencil_length      = (x,y) -> x.stencil_length == y.stencil_length
    stencil_coefs       = (x,y) -> !any(!isapprox.(x.stencil_coefs,y.stencil_coefs; kwargs...))
    boundary_point_count= (x,y) -> x.boundary_point_count == y.boundary_point_count
    boundary_length     = (x,y) -> x.boundary_length == y.boundary_length
    low_boundary_coefs  = (x,y) -> !any(!isapprox.(x.low_boundary_coefs,y.low_boundary_coefs; kwargs...))
    high_boundary_coefs = (x,y) -> !any(!isapprox.(x.high_boundary_coefs,y.high_boundary_coefs; kwargs...))
    boundary_condition  = (x,y) -> !any(!isapprox.(x.high_boundary_coefs,y.high_boundary_coefs; kwargs...))
    t                   = (x,y) -> x.t ≈ y.t

    #in order of fast to slow comparison
    for f in (der_order,approximation_order,dimension,t,boundary_point_count,boundary_length,dx,boundary_condition,low_boundary_coefs,high_boundary_coefs,stencil_coefs)
        if !f(x,y)
            return false
        end
    end
    return true
end

isapprox(x::FiniteDifference{T,S,LBC,RBC},y::DerivativeOperator{T,S,LBC,RBC}; kwargs...) where {T<:Real,S<:StaticArrays.SVector,LBC,RBC} = isapprox(y,x; kwargs...)
=#
