# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX

include("generation.jl")

TOL = 0.00001

"""
Solve an instance with CPLEX
"""
function cplexSolve(t::Array{Int, 2})

    # Create the model
    m = Model(with_optimizer(CPLEX.Optimizer))
    n = Int(size(t, 1)) - 1 # 

      
    # domino[i, j, :] = [0, 1, 0, 0]
    # Signifie que la case i, j est dominotée avec le domino i, j + 1. 
    # CF : ([(i, j-1), (i, j+1), (i-1, j), (i+1, j)])
    @variable(m, domino[1:n+1, 1:n+2, 0:4], Bin)
    @variable(m, dominos_poss[1:3, 1:floor(Int, (n+1 * (n+2)) / 2)], Bin) #28 dominos différents pour n = 6
    

    # Contraintes des dominos possibles
    debut = 1
    n_domino_i = n + 1 
    for i in 0:n
        @constraint(m, dominos_poss[1, debut:(debut + n_domino_i - 1)] == zeros(Int, n_domino_i) * i)
        debut = debut + n_domino_i
        n_domino_i = n - i
    end

    # Contrainte d'initialisation
    for i in 1:n+1
        for j in 1:n+2
            @constraint(m, domino[i, j, 0] == t[i, j]) # Lecture de valeur générée
        end
    end


    # Contrainte de non superposition
    for i in 1:n+1
        for j in 1:n+2
            @constraint(m, sum(domino[i, j, k] for k in 1:4) <= 1) # Un seul domino par case
        end
    end


    # Contraintes intérieures de dominotage des deux chiffres du domino
    for i in 2:n
        for j in 2:n+1
            # 4 Coins
            
            if i == 0 and j == 0 
            elseif i == 0 and j == n+2 
            elseif i == n+1 and j == 0
            elseif i == n+1 and j == n+2
            
            # 4 Bords
            elseif i == 0 and j < n+2 and j > 0
            elseif i == n+1 and j < n+2 and j > 0
            elseif i < n+1 and j == 0
            else
                @constraint(m, domino[i, j, 1] == domino[i, j-1, 2]) # Les deux chiffres du domino
                @constraint(m, domino[i, j, 2] == domino[i, j+1, 1]) # sont dominotés ensemble
                @constraint(m, domino[i, j, 3] == domino[i-1, j, 4])
                @constraint(m, domino[i, j, 4] == domino[i+1, j, 3])
            end
        end
    end

    # Contraintes Bords haut et bas
    for j in 2:n+1
        @constraint(m, domino[0, j, 1] == domino[0, j-1, 2]) # Les deux chiffres du domino sont dominotés ensemble
        @constraint(m, domino[0, j, 2] == domino[0, j+1, 1])
        @constraint(m, domino[0, j, 4] == domino[1, j, 3])

        @constraint(m, domino[n+1, j, 1] == domino[n+1, j-1, 2])
        @constraint(m, domino[n+1, j, 2] == domino[n+1, j+1, 1])
        @constraint(m, domino[n+1, j, 3] == domino[n, j, 4]) 
    end

    # Contraintes Bords droit et gauche
    for i in 2:n
         # Les deux chiffres du domino
        @constraint(m, domino[i, 0, 2] == domino[i, 1, 1]) # sont dominotés ensemble
        @constraint(m, domino[i, 0, 3] == domino[i-1, 0, 4])
        @constraint(m, domino[i, 0, 4] == domino[i+1, 0, 3]) 

        @constraint(m, domino[i, n+2, 1] == domino[i, n+1, 2])
        @constraint(m, domino[i, n+2, 3] == domino[i-1, n+2, 4])
        @constraint(m, domino[i, n+2, 4] == domino[i+1, n+2, 3])
    end

    # 4 Coins
    # Coins hauts
    @constraint(m, domino[0, 0, 2] == domino[0, 1, 1]) # gauche
    @constraint(m, domino[0, 0, 4] == domino[1, 0, 3])

    @constraint(m, domino[0, n+2, 1] == domino[0, n+1, 2]) #droit
    @constraint(m, domino[0, n+2, 4] == domino[1, j, 3])

    # Coins bas
    @constraint(m, domino[n+1, 0, 2] == domino[n+1, 1, 1]) #gauche
    @constraint(m, domino[n+1, 0, 3] == domino[n, 0, 4])

    @constraint(m, domino[n+1, n+2, 1] == domino[n+1, n+1, 2]) #droit
    @constraint(m, domino[n+1, n+2, 3] == domino[n, n+2, 4])


    @objective(m, Max, sum(sum(sum(domino[i, j, k] for k in 1:4) for)

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
