# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX

include("generation.jl")
include("io.jl")
TOL = 0.00001
"""
On suppose que le plateau est donné sous la forme d'un Array de n lignes (nombre de points) et de 3 colonnes
Colonne1 : abscisse
Colonne2 : ordonnée
Colonne3 : Capacité

"""
t = [
	2 1 1 ;
	4 1 3 ;
	1 4 2 ;
	4 4 4 ]
	

"""
Solve an instance with CPLEX
"""
function cplexSolve(t::Array{Int, 2})

	#nombre de lignes de t, càd nombre de points à connecter
	n = size(t, 1)

    # Create the model
    m = Model(with_optimizer(CPLEX.Optimizer))
	@variable(m,connexions[1:n,1:n] >= 0, Int)

	
	# Contrainte de symétrie de la matrice des connexions
	for i in 1:n
		@constraint(m, [j in 1:n], connexions[i,j] = connexions[j,i])
	end

	#Contrainte de non-connexion d'un point avec lui-même
	@constraint(m, [j in 1:n], connexions[j,j] = 0)

	# Contrainte de remplissage des capacités
	@constraint(m, [i in 1:n], sum(connexions[i,j] for j in i:n) == t[i,3])


	# Contrainte de non-connexion en diagonale
	for i in 1:n
		for j in 1:n
			if ((t[i,1] != t[j,1]) || (t[i,2] != t[j,2]))
				@constraint(m, connexions[i,j] == 0)
			end
		end
	end

	# Contrainte de non-croisement
	for i in 1:n
		for j in 1:n
			for k in 1:n
				for l in 1:n
					#on se place dans le cas où i et j sont alignés horizontalement, k et l verticalement
					#pas de perte de généralité, car, on parcourt toutes les combinaisons de sommets
					if ((t[i,2]==t[j,2])&&(t[k,1]==t[l,1]))
						#on se place dans les cas où les connexions peuvent potentiellement se croiser
						if ((t[i,1]<=t[k,1]) && (t[k,1] <= t[j,1]) && (t[k,2]<=t[i,2]) && (t[i,2]<=t[l,2]))
							@constraint(m, (connexions[i,j]>=1)+(connexions[k,l]>=1) <= 1)
				end
			end
		end
	end

	# Contrainte de nombre de ponts limité à deux
	for i in 1:n
		@constraint(m, [j in 1:n], connexions[i,j] <= 2)
	end


	# Contrainte de connexité

	
	# Objectif
	@objective(m,Max,0)
	

    # Start a chronometer
    start = time()

    # Solve the model
    optimize!(m)

    # Return:
    # 1 - true if an optimum is found
    # 2 - the resolution time
    return JuMP.primal_status(m) == JuMP.MathOptInterface.FEASIBLE_POINT, time() - start
    
end

"""
Heuristically solve an instance
"""
function heuristicSolve()

    # TODO
    println("In file resolution.jl, in method heuristicSolve(), TODO: fix input and output, define the model")
    
end 

"""
Solve all the instances contained in "../data" through CPLEX and heuristics

The results are written in "../res/cplex" and "../res/heuristic"

Remark: If an instance has previously been solved (either by cplex or the heuristic) it will not be solved again
"""
function solveDataSet()

    dataFolder = "../data/"
    resFolder = "../res/"

    # Array which contains the name of the resolution methods
    resolutionMethod = ["cplex"]
    #resolutionMethod = ["cplex", "heuristique"]

    # Array which contains the result folder of each resolution method
    resolutionFolder = resFolder .* resolutionMethod

    # Create each result folder if it does not exist
    for folder in resolutionFolder
        if !isdir(folder)
            mkdir(folder)
        end
    end
            
    global isOptimal = false
    global solveTime = -1

    # For each instance
    # (for each file in folder dataFolder which ends by ".txt")
    for file in filter(x->occursin(".txt", x), readdir(dataFolder))  
        
        println("-- Resolution of ", file)
        readInputFile(dataFolder * file)

        # TODO
        println("In file resolution.jl, in method solveDataSet(), TODO: read value returned by readInputFile()")
        
        # For each resolution method
        for methodId in 1:size(resolutionMethod, 1)
            
            outputFile = resolutionFolder[methodId] * "/" * file

            # If the instance has not already been solved by this method
            if !isfile(outputFile)
                
                fout = open(outputFile, "w")  

                resolutionTime = -1
                isOptimal = false
                
                # If the method is cplex
                if resolutionMethod[methodId] == "cplex"
                    
                    # TODO 
                    println("In file resolution.jl, in method solveDataSet(), TODO: fix cplexSolve() arguments and returned values")
                    
                    # Solve it and get the results
                    isOptimal, resolutionTime = cplexSolve()
                    
                    # If a solution is found, write it
                    if isOptimal
                        # TODO
                        println("In file resolution.jl, in method solveDataSet(), TODO: write cplex solution in fout") 
                    end

                # If the method is one of the heuristics
                else
                    
                    isSolved = false

                    # Start a chronometer 
                    startingTime = time()
                    
                    # While the grid is not solved and less than 100 seconds are elapsed
                    while !isOptimal && resolutionTime < 100
                        
                        # TODO 
                        println("In file resolution.jl, in method solveDataSet(), TODO: fix heuristicSolve() arguments and returned values")
                        
                        # Solve it and get the results
                        isOptimal, resolutionTime = heuristicSolve()

                        # Stop the chronometer
                        resolutionTime = time() - startingTime
                        
                    end

                    # Write the solution (if any)
                    if isOptimal

                        # TODO
                        println("In file resolution.jl, in method solveDataSet(), TODO: write the heuristic solution in fout")
                        
                    end 
                end

                println(fout, "solveTime = ", resolutionTime) 
                println(fout, "isOptimal = ", isOptimal)
                
                # TODO
                println("In file resolution.jl, in method solveDataSet(), TODO: write the solution in fout") 
                close(fout)
            end


            # Display the results obtained with the method on the current instance
            include(outputFile)
            println(resolutionMethod[methodId], " optimal: ", isOptimal)
            println(resolutionMethod[methodId], " time: " * string(round(solveTime, sigdigits=2)) * "s\n")
        end         
    end 
end
