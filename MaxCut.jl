using Convex # Pkg.add("Convex")
using SCS # Pkg.add("SCS")

"Max-Cut"

function input()
    readline(STDIN)
end

function goemansWilliamson{T<:Real}(W::Matrix{T}; tol::Real=1e-1, iter::Int=100)
	"Partition a graph into two disjoint sets such that the sum of the edge weights
	from all edges which cross the partition is as large as possible (known to be NP-hard)."

	"A cut of a graph can be produced by assigning either 1 or -1 to each vertex.  The Goemans-Williamson 
	algorithm relaxes this binary condition to allow for vector assignments drawn from the (n-1)-sphere
	(choosing an n-1 dimensional space will ensure seperability).  This relaxation can then be written as 
	an SDP.  Once the optimal vector assignments are found, origin centered hyperplanes are generated and 
	their corresponding cuts evaluated.  After 'iter' trials, or when the desired tolerance is reached,
	which ever comes first, the hyperplane with the highest corresponding binary cut is used to partition 
	the vertices."
	"W:		Adjacency matrix."
	"tol:	Maximum acceptable distance between a cut and the Max-Cut upper bound."
	"iter:	Maximum number of hyperplane iterations before a cut is chosen."

	LinAlg.checksquare(W)
	@assert LinAlg.issymmetric(W)	"Adjacency matrix must be symmetric."
	@assert all(W .>= 0)			"Entries of the adjacency matrix must be nonnegative."
	@assert all(diag(W) .== 0)		"Diagonal entries of adjacency matrix must be zero."
	@assert tol > 0					"The tolerance 'tol' must be positive."
	@assert iter > 0				"The number of iterations 'iter' must be a positive integer."

	"This is the standard SDP Relaxation of the Max-Cut problem, a reference can be found at
	http://www.sfu.ca/~mdevos/notes/semidef/GW.pdf."
	k = size(W, 1)
	S = Semidefinite(k)
	
	expr = vecdot(W, S)
	constr = [S[i,i] == 1.0 for i in 1:k]
	problem = minimize(expr, constr...)
	solve!(problem, SCSSolver(verbose=0))

	A = 0.5 * (S.value + S.value') # Ensure symmetric.
	A += max(0, -eigmin(A)) * eye(size(A, 1)) + eps(1.0) # Ensure positive-definite.

	X = full(chol(A))
	upperbound = (sum(W) - vecdot(W, S.value)) / 4 # A non-trivial upper bound on Max-Cut.

	"Random origin-centered hyperplanes, generated to produce partitions of the graph."
	maxcut = 0
	maxpartition = nothing

	for i in 1:iter
		eval = X' * randn(k)
		partition = (find(eval .>= 0), find(eval .< 0))
		cut = sum(W[partition...])

		if cut > maxcut
			maxpartition = partition
			maxcut = cut
		end

		upperbound - maxcut < tol && break
		i == iter && println("Max iterations reached.")
	end
	return round(maxcut, 3), maxpartition
end

function test()
  v1 = [parse(Int, ss) for ss in split(input())]
  n = v1[1]
  m = v1[2]
  W = zeros(n,n)
  i = 0
  while i < m
    v2 = [parse(Int, ss) for ss in split(input())]
    u = v2[1]
    v = v2[2]
    c = v2[3]
    W[u,v] = 1
    W[v,u] = 1
    i += 1
  end
  
	maxcut, maxpartition = goemansWilliamson(W)
	@show maxcut
	@show maxpartition
	nothing
end

test()
