# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX
using JuMP

#include("generation.jl")
include("io.jl")

TOL = 0.00001

"""
Solve an instance with CPLEX
"""

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

    # Modèle et variables de calcul (ok en principe)
        m = Model(with_optimizer(CPLEX.Optimizer))

        n = Int(size(t, 1)) - 1
        n_domino = floor(Int, (((n+1) * (n+2)) * 0.5))
        #@show n, n_domino

    # Variables d'optimisation (ok en principe)
        # domino[i, j, :] = [valeur, (j-1), (j+1), (i-1), (i+1)]
        @variable(m, domino[1:n+1, 1:n+2, 1:5] >= 0, Int)
        @variable(m, dominos_poss[1:3, 1:n_domino] >= 0, Int) #28 dominos différents pour n = 6
    
    
    # Contraintes des dominos possibles (ok en principe)
        debut = 1
        n_domino_i = n + 1
        for i in 0:n #boucle sur les chiffres des dominos
            for j in debut:(debut + n_domino_i - 1)
                @constraint(m, dominos_poss[1, j] == i) #on a n_domino_i premiers chiffres constants
                @constraint(m, dominos_poss[2, j] == j - debut + i) #chacun associés avec des chiffres variables
            end
            debut = debut + n_domino_i
            n_domino_i = n_domino_i - 1
            #@show debut:(debut + n_domino_i - 1)
            if n_domino_i == 0
                break
            end
        end

    # Contrainte d'initialisation (ok en principe)
        for i in 1:n+1
            for j in 1:n+2
                @constraint(m, domino[i, j, 1] == t[i, j]) # Lecture de valeur générée
                #print(" ", t[i,j])
            end
            #print("\n")
        end


    # Contrainte de non superposition (ok en principe)
        for i in 1:n+1
            for j in 1:n+2
                @constraint(m, sum(domino[i, j, k] for k in 2:5) == 1) # Exactement un seul domino par case
            end
        end


    # domino[i, j, :] = [valeur, (j-1), (j+1), (i-1), (i+1)]

    # Contraintes de dominotage des deux chiffres du domino : Les deux chiffres du domino sont dominotés ensemble
        # Contraintes intérieures
            for i in 2:n
                for j in 2:n+1
                    @constraint(m, domino[i, j, 2] == domino[i, j-1, 3]) 
                    @constraint(m, domino[i, j, 3] == domino[i, j+1, 2]) 
                    @constraint(m, domino[i, j, 4] == domino[i-1, j, 5])
                    @constraint(m, domino[i, j, 5] == domino[i+1, j, 4])
                end
            end
      
        # domino[i, j, :] = [valeur, (j-1), (j+1), (i-1), (i+1)]

        # Contraintes Bords haut et bas
            for j in 2:n+1
                # Bord haut
                @constraint(m, domino[1, j, 2] == domino[1, j-1, 3]) 
                @constraint(m, domino[1, j, 3] == domino[1, j+1, 2])
                @constraint(m, domino[1, j, 4] == 0) # le domino en (0,j) n'existe pas, on ne peut pas se lier à lui
                @constraint(m, domino[1, j, 5] == domino[2, j, 4])

                # Bord bas
                @constraint(m, domino[n+1, j, 2] == domino[n+1, j-1, 3])
                @constraint(m, domino[n+1, j, 3] == domino[n+1, j+1, 2])
                @constraint(m, domino[n+1, j, 4] == domino[n, j, 5])
                @constraint(m, domino[n+1, j, 5] == 0) # le domino en (n+2,j) n'existe pas, on ne peut pas se lier à lui
            end


        # domino[i, j, :] = [valeur, (j-1), (j+1), (i-1), (i+1)]

        # Contraintes Bords droit et gauche
            for i in 2:n
                # Bord gauche
                @constraint(m, domino[i, 1, 2] == 0)
                @constraint(m, domino[i, 1, 3] == domino[i, 2, 2])
                @constraint(m, domino[i, 1, 4] == domino[i-1, 1, 5])
                @constraint(m, domino[i, 1, 5] == domino[i+1, 1, 4]) 

                # Bord droit
                @constraint(m, domino[i, n+2, 2] == domino[i, n+1, 3])
                @constraint(m, domino[i, n+2, 3] == 0)
                @constraint(m, domino[i, n+2, 4] == domino[i-1, n+2, 5])
                @constraint(m, domino[i, n+2, 5] == domino[i+1, n+2, 4])
            end

        # domino[i, j, :] = [valeur, (j-1), (j+1), (i-1), (i+1)]

        # Coins hauts
            # Haut gauche
            @constraint(m, domino[1, 1, 2] == 0)
            @constraint(m, domino[1, 1, 3] == domino[1, 2, 2]) 
            @constraint(m, domino[1, 1, 4] == 0)
            @constraint(m, domino[1, 1, 5] == domino[2, 1, 4])

            # Haut droit
            @constraint(m, domino[1, n+2, 2] == domino[1, n+1, 3]) 
            @constraint(m, domino[1, n+2, 3] == 0)
            @constraint(m, domino[1, n+2, 4] == 0)
            @constraint(m, domino[1, n+2, 5] == domino[2, n+2, 4])

        # Coins bas
            # Bas gauche
            @constraint(m, domino[n+1, 1, 2] == 0)
            @constraint(m, domino[n+1, 1, 3] == domino[n+1, 2, 2]) 
            @constraint(m, domino[n+1, 1, 4] == domino[n, 1, 5])
            @constraint(m, domino[n+1, 1, 5] == 0)

            # Bas droit
            @constraint(m, domino[n+1, n+2, 2] == domino[n+1, n+1, 3])
            @constraint(m, domino[n+1, n+2, 3] == 0)
            @constraint(m, domino[n+1, n+2, 4] == domino[n, n+2, 5])
            @constraint(m, domino[n+1, n+2, 5] == 0)
    # Fin de contrainte

    # Contrainte de comptage d'un domino (semble être calculée une fois pour toute... traduction par CPLEX : "0 >= 1.0"........)
    @constraint(m, [i in 1:n_domino], 0.5 * 
        sum(
            sum(
                reduce(+, 
                1 for k in 2:5 
                if (((domino[l,j,1] == dominos_poss[1, i]) && (
                        (k == 2 && j > 1 && domino[l,j-1,1] == dominos_poss[2, i] && domino[l,j,k] == 1 )
                        || (k == 3 && j < n+2 && domino[l,j+1,1] == dominos_poss[2, i] && domino[l,j,k] == 1 )
                        || (k == 4 && l > 1 && domino[l-1,j,1] == dominos_poss[2, i] && domino[l,j,k] == 1 ) 
                        || (k == 5 && l < n+1 && domino[l+1,j,1] == dominos_poss[2, i] && domino[l,j,k] == 1 ) ))

                    || (
                        (domino[l,j,1] == dominos_poss[2, i]) && (
                            (k == 2 && j > 1 && domino[l,j-1,1] == dominos_poss[1, i] && domino[l,j,k] == 1 ) 
                            || (k == 3 && j < n+2 && domino[l,j+1,1] == dominos_poss[1, i] && domino[l,j,k] == 1 ) 
                            || (k == 4 && l > 1 && domino[l-1,j,1] == dominos_poss[1, i] && domino[l,j,k] == 1 ) 
                            || (k == 5 && l < n+1 && domino[l+1,j,1] == dominos_poss[1, i] && domino[l,j,k] == 1 ) )
                        )); init = 0) 
            for l in 1:n+1) 
        for j in 1:n+2)
    >= 1)
    
    # Contrainte de non répétition d'un domino
        for i in 1:n_domino
            # non répétition d'un domino :
            #@constraint(m, dominos_poss[3, i] <= 1)
            @constraint(m, sum(sum(sum( domino[l,j,k] for k in 2:5 if ((domino[l,j,k] == 1) && (((domino[l,j,1] == dominos_poss[1, i]) && ((k == 2 && j > 1 && domino[l,j-1,1] == dominos_poss[2, i]) || (k == 3 && j < n+2 && domino[l,j+1,1] == dominos_poss[2, i]) || (k == 4 && l > 1 && domino[l-1,j,1] == dominos_poss[2, i]) || (k == 5 && l < n+1 && domino[l+1,j,1] == dominos_poss[2, i]) )) || (   (domino[l,j,1] == dominos_poss[2, i]) && ((k == 2 && j > 1 && domino[l,j-1,1] == dominos_poss[1, i]) || (k == 3 && j < n+2 && domino[l,j+1,1] == dominos_poss[1, i]) || (k == 4 && l > 1 && domino[l-1,j,1] == dominos_poss[1, i]) || (k == 5 && l < n+1 && domino[l+1,j,1] == dominos_poss[1, i]) ))))) for j in 1:n+2 ) for l in 1:n+1) <= 1)
            # non répétition d'un domino ET tous les dominos sont représentés
            #@constraint(m, sum(sum(sum( domino[l,j,k] for k in 2:5 if ((domino[l,j,k] == 1) && (((domino[l,j,1] == dominos_poss[1, i]) && ((k == 2 && j > 1 && domino[l,j-1,1] == dominos_poss[2, i]) || (k == 3 && j < n+2 && domino[l,j+1,1] == dominos_poss[2, i]) || (k == 4 && l > 1 && domino[l-1,j,1] == dominos_poss[2, i]) || (k == 5 && l < n+1 && domino[l+1,j,1] == dominos_poss[2, i]) )) || (   (domino[l,j,1] == dominos_poss[2, i]) && ((k == 2 && j > 1 && domino[l,j-1,1] == dominos_poss[1, i]) || (k == 3 && j < n+2 && domino[l,j+1,1] == dominos_poss[1, i]) || (k == 4 && l > 1 && domino[l-1,j,1] == dominos_poss[1, i]) || (k == 5 && l < n+1 && domino[l+1,j,1] == dominos_poss[1, i]) ))))) for j in 1:n+2 ) for l in 1:n+1) == 1)
        end
    
    
    print(m)

    #objectif Pas nécessaire
    @objective(m, Max, sum(dominos_poss[3,i] for i in 1:n_domino))

    #Start a chronometer
    start = time()

    # Solve the model
    optimize!(m)

    # Return:
        # 1 - true if an optimum is found
        # 2 - the resolution time

        domino_val = zeros(n+1, n+2, 5)
        for i in 1:n+1
            for j in 1:n+2
                for k in 1:5
                    domino_val[i,j,k] = JuMP.value(domino[i,j,k])
                end
            end
        end

        dominos_poss_val = zeros(3, n_domino)
        for i in 1:n_domino
            for k in 1:2
                dominos_poss_val[k,i] = JuMP.value(dominos_poss[k,i])
            end
            #dominos_poss_val[3,i] = sum(sum(sum(  domino_val[l,j,k] for k in 2:5 if ((domino[l,j,k] == 1) && (((domino_val[l,j,1] == dominos_poss_val[1, i]) && ((k == 2 && j > 1 && domino_val[l,j-1,1] == dominos_poss_val[2, i]) || (k == 3 && j < n+2 && domino_val[l,j+1,1] == dominos_poss_val[2, i]) || (k == 4 && l > 1 && domino_val[l-1,j,1] == dominos_poss_val[2, i]) || (k == 5 && l < n+1 && domino_val[l+1,j,1] == dominos_poss_val[2, i]) )) || (   (domino_val[l,j,1] == dominos_poss_val[2, i]) && ((k == 2 && j > 1 && domino_val[l,j-1,1] == dominos_poss_val[1, i]) || (k == 3 && j < n+1 && domino_val[l,j+1,1] == dominos_poss_val[1, i]) || (k == 4 && l > 1 && domino_val[l-1,j,1] == dominos_poss_val[1, i]) || (k == 5 && l < n+1 && domino_val[l+1,j,1] == dominos_poss_val[1, i]) )))) for j in 1:n+2 ) for l in 1:n+1))
        end
        




    return solution, dominos_poss_val
    
end


solution, domi = cplexSolve(t_3)
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
