using SparseArrays, DiffEqOperators, LinearAlgebra, Random, Test, BandedMatrices

function second_derivative_stencil(N)
  A = zeros(N,N+2)
  for i in 1:N, j in 1:N+2
      (j-i==0 || j-i==2) && (A[i,j]=1)
      j-i==1 && (A[i,j]=-2)
  end
  A
end

function convert_by_multiplication(::Type{Array}, A::AbstractDerivativeOperator{T}, N::Int=A.dimension) where T
    @assert N >= A.stencil_length # stencil must be able to fit in the matrix
    mat = zeros(T, (N, N+2))
    v = zeros(T, N+2)
    for i=1:N+2
        v[i] = one(T)
        #=
            calculating the effect on a unit vector to get the matrix of transformation
            to get the vector in the new vector space.
        =#
        mul!(view(mat,:,i), A, v)
        v[i] = zero(T)
    end
    return mat
end

# tests for full and sparse function
@testset "Full and Sparse functions:" begin
    N = 10
    d_order = 2
    approx_order = 2
    correct = second_derivative_stencil(N)
    A = DerivativeOperator{Float64}(d_order,approx_order,1.0,N)

    @test convert_by_multiplication(Array,A,N) == correct
    @test Array(A) == second_derivative_stencil(N)
    @test sparse(A) == second_derivative_stencil(N)
    @test BandedMatrix(A) == second_derivative_stencil(N)
    @test_broken opnorm(A, Inf) == opnorm(correct, Inf)


    # testing higher derivative and approximation concretization
    N = 20
    d_order = 4
    approx_order = 4
    A = DerivativeOperator{Float64}(d_order,approx_order,1.0,N)
    correct = convert_by_multiplication(Array,A,N)

    @test Array(A) ≈ correct
    @test sparse(A) ≈ correct
    @test BandedMatrix(A) ≈ correct

    N = 26
    d_order = 8
    approx_order = 8
    A = DerivativeOperator{Float64}(d_order,approx_order,1.0,N)
    correct = convert_by_multiplication(Array,A,N)

    @test Array(A) ≈ correct
    @test sparse(A) ≈ correct
    @test BandedMatrix(A) ≈ correct

    # testing correctness of multiplication
    N = 1000
    d_order = 4
    approx_order = 10
    y = collect(1:1.0:N+2).^4 - 2*collect(1:1.0:N+2).^3 + collect(1:1.0:N+2).^2;
    y = convert(Array{BigFloat, 1}, y)

    A = DerivativeOperator{BigFloat}(d_order,approx_order,one(BigFloat),N)
    correct = convert_by_multiplication(Array,A,N)
    @test Array(A) ≈ correct
    @test sparse(A) ≈ correct
    @test BandedMatrix(A) ≈ correct

    @test A*y ≈ Array(A)*y
end

@testset "Indexing tests" begin
    N = 1000
    d_order = 4
    approx_order = 10

    A = DerivativeOperator{Float64}(d_order,approx_order,1.0,N)
    @test A[1,1] == Array(A)[1,1]
    @test A[10,20] == 0

    correct = Array(A)
    for i in 1:N-5
        @test A[i,i] == correct[i,i]
    end
    for i in N-4:N
        @test_broken A[i,i] == correct[i,i]
    end

    # Indexing Tests
    N = 1000
    d_order = 2
    approx_order = 2

    A = DerivativeOperator{Float64}(d_order,approx_order,1.0,N)
    M = Array(A,1000)
    @test A[1,1] == M[1,1]
    @test A[1:4,1] == M[1:4,1]
    @test_broken A[5,2:10] == M[5,2:10]
    @test_broken A[60:100,500:600] == M[60:100,500:600]
end

@testset begin "Operations on matrices"
    N = 51
    M = 101
    d_order = 2
    approx_order = 2

    xarr = range(0,stop=1,length=N)
    yarr = range(0,stop=1,length=M)
    dx = xarr[2]-xarr[1]
    dy = yarr[2]-yarr[1]
    F = [x^2+y for x = xarr, y = yarr]

    A = DerivativeOperator{Float64}(d_order,approx_order,dx,length(xarr))
    B = DerivativeOperator{Float64}(d_order,approx_order,dy,length(yarr))

    @test_broken A*F ≈ 2*ones(N,M) atol=1e-2
    @test_broken F*B ≈ 8*ones(N,M) atol=1e-2
    @test_broken A*F*B ≈ zeros(N,M) atol=1e-2

    G = [x^2+y^2 for x = xarr, y = yarr]

    @test_broken A*G ≈ 2*ones(N,M) atol=1e-2
    @test_broken G*B ≈ 8*ones(N,M) atol=1e-2
    @test_broken A*G*B ≈ zeros(N,M) atol=1e-2
end

@testset "Linear combinations of operators" begin
    # Only tests the additional functionality defined in "operator_combination.jl"
    N = 10
    Random.seed!(0); LA = DiffEqArrayOperator(rand(N,N))
    LD = DerivativeOperator{Float64}(2,2,1.0,N)
    @test_broken begin
      L = 1.1*LA - 2.2*LD + 3.3*I
      # Builds convert(L) the brute-force way
      fullL = zeros(N,N)
      v = zeros(N)
      for i = 1:N
          v[i] = 1.0
          fullL[:,i] = L*v
          v[i] = 0.0
      end
      @test convert(L) ≈ fullL
      @test exp(L) ≈ exp(fullL)
      for p in [1,2,Inf]
          @test opnorm(L,p) ≈ opnorm(fullL,p)
          @test opnormbound(L,p) ≈ 1.1*opnorm(LA,p) + 2.2*opnorm(LD,p) + 3.3
      end
  end
end
