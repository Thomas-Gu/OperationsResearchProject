# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX
using JuMP

#include("generation.jl")
include("io.jl")

TOL = 0.00001

"""
Solve an instance with CPLEX
"""

t_0 = [
    0 0 1 ;
    1 1 0 ]

t_3 = [
    3 3 3 2 0 ;
    3 3 0 2 1 ;
    0 1 1 2 1 ;
    2 2 0 0 1 ]

t1 = [
    4 6 5 1 6 0 3 4 ;
    1 1 4 0 3 3 0 1 ;
    6 6 6 5 6 4 0 1 ;
    2 2 4 3 1 4 1 3 ;
    0 0 6 2 3 4 5 3 ;
    2 2 6 1 0 0 4 2 ;
    5 5 2 3 2 5 5 5 ] 

t = [
    1 5 6 6 2 0 2 3 ;
    0 0 5 3 0 6 1 1 ;
    4 4 2 4 5 0 6 1 ;
    5 3 2 0 2 1 5 5 ;
    4 2 3 4 0 0 2 4 ;
    1 3 2 5 5 1 4 6 ;
    3 6 4 6 6 1 3 3 ]



function cplexSolve(t::Array{Int, 2})

    # Modèle et variables de calcul (ok)
        m = Model(with_optimizer(CPLEX.Optimizer))

        n = Int(size(t, 1)) - 1
        n_domino = floor(Int, (((n+1) * (n+2)) * 0.5))
        #@show n, n_domino

    # Variables d'optimisation (ok)
        # domino[i, j, :] = [(j-1), (j+1), (i-1), (i+1)]
        @variable(m, domino[1:n+1, 1:n+2, 1:4], Bin)
        dominos_poss = zeros(Int, 3, n_domino)


    # Ensemble des dominos possibles (ok)
        debut = 1
        n_domino_i = n + 1
        for i in 0:n #boucle sur les chiffres des dominos
            for j in debut:(debut + n_domino_i - 1)
                dominos_poss[1, j] = i #on a n_domino_i premiers chiffres constants
                dominos_poss[2, j] = j - debut + i #chacun associés avec des chiffres variables
            end

            debut = debut + n_domino_i
            n_domino_i = n_domino_i - 1
            
            if n_domino_i == 0
                break
            end
        end

    # Contrainte de non superposition (ok en principe)
        @constraint(m, [i in 1:n+1, j in 1:n+2], sum(domino[i, j, k] for k in 1:4) == 1) # Exactement un seul domino par case


    # domino[i, j, :] = [(j-1), (j+1), (i-1), (i+1)]

    # Contraintes de dominotage des deux chiffres du domino : Les deux chiffres du domino sont dominotés ensemble
        # Contraintes intérieures
            @constraint(m, [i in 2:n, j in 2:n+1], domino[i, j, 1] == domino[i, j-1, 2]) 
            @constraint(m, [i in 2:n, j in 2:n+1], domino[i, j, 2] == domino[i, j+1, 1]) 
            @constraint(m, [i in 2:n, j in 2:n+1], domino[i, j, 3] == domino[i-1, j, 4])
            @constraint(m, [i in 2:n, j in 2:n+1], domino[i, j, 4] == domino[i+1, j, 3])

      
        # domino[i, j, :] = [(j-1), (j+1), (i-1), (i+1)]

        # Contraintes Bords haut et bas
            # Bord haut
                @constraint(m, [j in 2:n+1], domino[1, j, 1] == domino[1, j-1, 2]) 
                @constraint(m, [j in 2:n+1], domino[1, j, 2] == domino[1, j+1, 1])
                @constraint(m, [j in 2:n+1], domino[1, j, 3] == 0) # le domino en (0,j) n'existe pas, on ne peut pas se lier à lui
                @constraint(m, [j in 2:n+1], domino[1, j, 4] == domino[2, j, 3])

            # Bord bas
                @constraint(m, [j in 2:n+1], domino[n+1, j, 1] == domino[n+1, j-1, 2])
                @constraint(m, [j in 2:n+1], domino[n+1, j, 2] == domino[n+1, j+1, 1])
                @constraint(m, [j in 2:n+1], domino[n+1, j, 3] == domino[n, j, 4])
                @constraint(m, [j in 2:n+1], domino[n+1, j, 4] == 0) # le domino en (n+2,j) n'existe pas, on ne peut pas se lier à lui


        # domino[i, j, :] = [(j-1), (j+1), (i-1), (i+1)]

        # Contraintes Bords droit et gauche
            # Bord gauche
                @constraint(m, [i in 2:n], domino[i, 1, 1] == 0)
                @constraint(m, [i in 2:n], domino[i, 1, 2] == domino[i, 2, 1])
                @constraint(m, [i in 2:n], domino[i, 1, 3] == domino[i-1, 1, 4])
                @constraint(m, [i in 2:n], domino[i, 1, 4] == domino[i+1, 1, 3]) 

            # Bord droit
                @constraint(m, [i in 2:n], domino[i, n+2, 1] == domino[i, n+1, 2])
                @constraint(m, [i in 2:n], domino[i, n+2, 2] == 0)
                @constraint(m, [i in 2:n], domino[i, n+2, 3] == domino[i-1, n+2, 4])
                @constraint(m, [i in 2:n], domino[i, n+2, 4] == domino[i+1, n+2, 3])

        # domino[i, j, :] = [(j-1), (j+1), (i-1), (i+1)]

        # Coins hauts
            # Haut gauche
            @constraint(m, domino[1, 1, 1] == 0)
            @constraint(m, domino[1, 1, 2] == domino[1, 2, 1]) 
            @constraint(m, domino[1, 1, 3] == 0)
            @constraint(m, domino[1, 1, 4] == domino[2, 1, 3])

            # Haut droit
            @constraint(m, domino[1, n+2, 1] == domino[1, n+1, 2]) 
            @constraint(m, domino[1, n+2, 2] == 0)
            @constraint(m, domino[1, n+2, 3] == 0)
            @constraint(m, domino[1, n+2, 4] == domino[2, n+2, 3])

        # Coins bas
            # Bas gauche
            @constraint(m, domino[n+1, 1, 1] == 0)
            @constraint(m, domino[n+1, 1, 2] == domino[n+1, 2, 1]) 
            @constraint(m, domino[n+1, 1, 3] == domino[n, 1, 4])
            @constraint(m, domino[n+1, 1, 4] == 0)

            # Bas droit
            @constraint(m, domino[n+1, n+2, 1] == domino[n+1, n+1, 2])
            @constraint(m, domino[n+1, n+2, 2] == 0)
            @constraint(m, domino[n+1, n+2, 3] == domino[n, n+2, 4])
            @constraint(m, domino[n+1, n+2, 4] == 0)
    # Fin de contrainte


    

    # Non répétition d'un domino
        @constraint(m, [i in 1:n_domino], sum(reduce(+, domino[l, j, 2] + domino[l, j+1, 1] for l in 1:n+1 if ((t[l, j] == dominos_poss[1,i] && t[l, j+1] == dominos_poss[2,i]) || (t[l, j] == dominos_poss[2,i] && t[l, j+1] == dominos_poss[1,i])) ;init = 0) for j in 1:n+1) + sum(reduce(+, domino[l, j, 4] + domino[l+1, j, 3] for l in 1:n if ((t[l, j] == dominos_poss[1,i] && t[l+1, j] == dominos_poss[2,i]) || (t[l, j] == dominos_poss[2,i] && t[l+1, j] == dominos_poss[1,i])) ; init = 0) for j in 1:n+2) == 2)
    
    
    print(m)

    #Start a chronometer
    start = time()

    # Objectif
    @objective(m, Max, sum(sum(sum(domino[i,j,k] for k in 1:4) for i in 1:n+1) for j in 1:n+2))
    # Solve the model
    optimize!(m)

    # Return:
        # 1 - true if an optimum is found
        # 2 - the resolution time

        domino_val = zeros(n+1, n+2, 5)
        for i in 1:n+1
            for j in 1:n+2
                for k in 1:4
                    domino_val[i,j,k] = JuMP.value(domino[i,j,k])
                end
            end
        end

        




    return solution, dominos_poss
    
end


solution, domi = cplexSolve(t_0)
disp_sol(solution)
print("\n\n", domi[1, :])
print("\n", domi[2, :])
print("\n", domi[3, :])


# """
# Heuristically solve an instance
# """
# function heuristicSolve()

#     # TODO
#     println("In file resolution.jl, in method heuristicSolve(), TODO: fix input and output, define the model")
    
# end 

# """
# Solve all the instances contained in "../data" through CPLEX and heuristics

# The results are written in "../res/cplex" and "../res/heuristic"

# Remark: If an instance has previously been solved (either by cplex or the heuristic) it will not be solved again
# """
# function solveDataSet()

#     dataFolder = "../data/"
#     resFolder = "../res/"

#     # Array which contains the name of the resolution methods
#     resolutionMethod = ["cplex"]
#     #resolutionMethod = ["cplex", "heuristique"]

#     # Array which contains the result folder of each resolution method
#     resolutionFolder = resFolder .* resolutionMethod

#     # Create each result folder if it does not exist
#     for folder in resolutionFolder
#         if !isdir(folder)
#             mkdir(folder)
#         end
#     end
            
#     global isOptimal = false
#     global solveTime = -1

#     # For each instance
#     # (for each file in folder dataFolder which ends by ".txt")
#     for file in filter(x->occursin(".txt", x), readdir(dataFolder))  
        
#         println("-- Resolution of ", file)
#         readInputFile(dataFolder * file)

#         # TODO
#         println("In file resolution.jl, in method solveDataSet(), TODO: read value returned by readInputFile()")
        
#         # For each resolution method
#         for methodId in 1:size(resolutionMethod, 1)
            
#             outputFile = resolutionFolder[methodId] * "/" * file

#             # If the instance has not already been solved by this method
#             if !isfile(outputFile)
                
#                 fout = open(outputFile, "w")  

#                 resolutionTime = -1
#                 isOptimal = false
                
#                 # If the method is cplex
#                 if resolutionMethod[methodId] == "cplex"
                    
#                     # TODO 
#                     println("In file resolution.jl, in method solveDataSet(), TODO: fix cplexSolve() arguments and returned values")
                    
#                     # Solve it and get the results
#                     isOptimal, resolutionTime = cplexSolve()
                    
#                     # If a solution is found, write it
#                     if isOptimal
#                         # TODO
#                         println("In file resolution.jl, in method solveDataSet(), TODO: write cplex solution in fout") 
#                     end

#                 # If the method is one of the heuristics
#                 else
                    
#                     isSolved = false

#                     # Start a chronometer 
#                     startingTime = time()
                    
#                     # While the grid is not solved and less than 100 seconds are elapsed
#                     while !isOptimal and resolutionTime < 100
                        
#                         # TODO 
#                         println("In file resolution.jl, in method solveDataSet(), TODO: fix heuristicSolve() arguments and returned values")
                        
#                         # Solve it and get the results
#                         isOptimal, resolutionTime = heuristicSolve()

#                         # Stop the chronometer
#                         resolutionTime = time() - startingTime
                        
#                     end

#                     # Write the solution (if any)
#                     if isOptimal

#                         # TODO
#                         println("In file resolution.jl, in method solveDataSet(), TODO: write the heuristic solution in fout")
                        
#                     end 
#                 end

#                 println(fout, "solveTime = ", resolutionTime) 
#                 println(fout, "isOptimal = ", isOptimal)
                
#                 # TODO
#                 println("In file resolution.jl, in method solveDataSet(), TODO: write the solution in fout") 
#                 close(fout)
#             end


#             # Display the results obtained with the method on the current instance
#             include(outputFile)
#             println(resolutionMethod[methodId], " optimal: ", isOptimal)
#             println(resolutionMethod[methodId], " time: " * string(round(solveTime, sigdigits=2)) * "s\n")
#         end         
#     end 
# end
