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
		@constraint(m, [j in 1:n], connexions[i,j] == connexions[j,i])
	end



	#Contrainte de non-connexion d'un point avec lui-même

	@constraint(m, [j in 1:n], connexions[j,j] == 0)



	# Contrainte de remplissage des capacités
"""
	A réecrire parce qu'on ne somme pas correctement sur toutes les connexion
	for i in 1:(n-1)
		@constraint(m, sum(connexions[i,j] for j in (i+1):n) == t[i,3])
	end
"""


	# Contrainte de nombre de ponts limité à deux

	for i in 1:n
		for j in 1:n
			@constraint(m, connexions[i,j] <= 2)
		end
	end



	# Contrainte de non-connexion en diagonale

	for i in 1:n
		for j in 1:n
			if ((t[i,1] != t[j,1]) && (t[i,2] != t[j,2]))
				@constraint(m, connexions[i,j] == 0)
			end
		end
	end


	# Contrainte de non-croisement
"""
	for i in 1:n
		for j in 1:n
			for k in 1:n
				for l in 1:n
					#on se place dans le cas où i et j sont alignés horizontalement, k et l verticalement
					#pas de perte de généralité, car, on parcourt toutes les combinaisons de sommets
					if ((t[i,2]==t[j,2])&&(t[k,1]==t[l,1]))
						#on se place dans les cas où les connexions peuvent potentiellement se croiser
						if ((t[i,1]<=t[k,1]) && (t[k,1] <= t[j,1]) && (t[k,2]<=t[i,2]) && (t[i,2]<=t[l,2]))
							@constraint(m, (((connexions[i,j]>=1)||(connexions[k,l]>=1))&&(!((connexions[i,j]>=1)&&(connexions[k,l]>=1))))==true)
						end
					end
				end
			end
		end
	end
"""



	# Contrainte de connexité

	
	# Objectif
	
	println(m)

    # Start a chronometer
    start = time()

    # Solve the model
    optimize!(m)

    # Return:
    # 1 - true if an optimum is found
    # 2 - the resolution time
	# 3 - the solution in itself

	solution = zeros(n,n)
	for i in 1:n
		for j in 1:n
			solution[i,j] = JuMP.value(connexions[i,j])
		end
	end

    return JuMP.primal_status(m) == JuMP.MathOptInterface.FEASIBLE_POINT, time() - start, solution
    
end

trouve, temps, solution = cplexSolve(t)
println(solution)








"""
Heuristically solve an instance
"""

function heuristicSolve(cas::Array{Int, 2}, ponts::Array{Int, 2}, ponts_poss::Array{Int, 2}, nbr_ponts::Array{Int, 1}, solve::Bool, erreur::bool)
    if solve # On a réolu le problème
        return(ponts)
    end
        ###    
    else   
        n = size(t, 1) # Nombre de noeuds à connecter
        ponts_poss = ponts_poss_calc(cas, nbr_ponts)

        # Si qu'une solution, on la met, si pas de solution, erreur
        for i in 1:n
            if (cas[i, 3] < nbr_ponts[i]) # On vérifie que le noeud n'est pas déjà saturé
                position_poss_i = 0
                unique = true
                nbr_poss_i = 0
                for j in 1:n
                    if ponts_poss[i, j] > 0
                        if nbr_poss_i >= 1
                            unique = false # repère si on avait déjà changé une fois (i.e. on n'a plusieurs ponts possibles avec plusieurs autres noeuds)
                        position_poss_i = j
                        nbr_poss_i = nbr_poss_i + ponts_poss[i, j]
                    end
                end

                if unique # ie on a de ponts possible qu'avec un (ou aucun) noeud, mais pas plusieurs
                    if nbr_poss_i == 0 # Aucune possibilité pour le noeud i alors qu'il n'est pas saturé, donc erreur
                        return cas, ponts, ponts_poss, nbr_ponts, false, true
                    
                    elseif nbr_poss_i <= 2 # Une unique possibilité, on la met ()
                        ponts[i, position_poss_i] = ponts_poss[i, position_poss_i] # Avec une valeur de liens calculée
                    else # Une unique possibilité pour mettre plus de deux ponts, erreur
                        return cas, ponts, ponts_poss, nbr_ponts, false, true
                    end
                end
            end
        end

        # Sinon, on essaie de forcer une possibilité







        solve = true
    end
end


function ponts_poss_calc(cas::Array{Int, 2}, nbr_ponts::Array{Int, 1}) # Remplissage de ponts_poss
    
    ponts_poss = zeros(Int, n, n)

    for i in 1:n
        for j in i+1:n
            if (cas[i, 3] < nbr_ponts[i]) && (cas[j, 3] < nbr_ponts[j]) #Les noeuds ne sont pas saturés

                # Ajouter le non croisement !

                if (cas[i,1] == cas[j,1]) || (cas[i,2] == cas[j,2]) # Si même abscisse ou même ordonnée, pont possible (pas de diagonale)
                    if test_non_croisement
                        ponts_poss[i, j] = min(cas[j,3] - nbr_ponts[j], cas[i,3] - nbr_ponts[i], 2) # Pont de taille <= 2 et allant jusqu'à la capacité minimale des deux encore disponible
                        ponts_poss[j, i] = ponts_poss[i, j] # Symétrique
                    end
                end
            end
        end
    end

    return ponts_poss
end


function test_non_croisement(cas::Array{Int, 2}, ponts::Array{Int, 2}, k::Int, l::Int)
    x_k = cas[k, 1]
    y_k = cas[k, 2]
    x_l = cas[l, 1]
    y_l = cas[l, 2]

    x_1 = min(x_k, x_l)
    y_1 = min(y_k, y_l)
    x_2 = max(x_k, x_l)
    y_2 = max(y_k, y_l)
    
    n = size(t, 1)
    
    if x_1 == x_2 && y_1 == y_2 #Point identique
        return false
    end

    if x_1 == x_2
        for i in 1:n
            for j in i+1:n
                if pont[i, j] >= 1 # On regarde parmi les connexions
                    if min(cas[i, 1], cas[j, 1]) <= x_1 && max(cas[i, 1], cas[j, 1]) >= x_2
                        if min(cas[i, 2], cas[j, 2]) >= y_1 && max(cas[i, 2], cas[j, 2]) <= y_2 #on a croisement !
                            return false
                        else
                            return true
                        end

                    else
                        return true
                    end
                end
            end
        end

        return true # Aucune connexion
    end

    if y_1 == y_2
        for i in 1:n
            for j in i+1:n
                if pont[i, j] >= 1 # On regarde parmi les connexions
                    if min(cas[i, 2], cas[j, 2]) <= y_1 && max(cas[i, 2], cas[j, 2]) >= y_2
                        if min(cas[i, 1], cas[j, 1]) >= x_1 && max(cas[i, 1], cas[j, 1]) <= x_2 #on a croisement !
                            return false
                        else
                            return true
                        end

                    else
                        return true
                    end
                end
            end
        end

        return true # Aucune connexion
    end

    return false # Connexion en diagonale
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
