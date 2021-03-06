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

t_1 = [
    1 1 2 ;
    1 3 2 ;
    7 1 3 ;
    5 3 3 ;
    2 5 2 ;
    4 5 4 ;
    5 6 2 ;
    2 7 2 ;
    4 7 6 ;
    7 7 4 ]

t_2 = [
    1 1 2 ;
    4 1 1 ;
    7 1 3 ;
    1 3 5 ;
    7 3 4 ;
    2 4 1 ;
    4 4 3 ;
    6 4 2 ;
    7 5 2 ;
    1 6 4 ;
    4 6 4 ;
    6 6 2 ;
    5 7 2 ;
    7 7 3]



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

	for i in 1:(n-1)
		@constraint(m, sum(connexions[i,j] for j in 1:n) == t[i,3])
	end



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
							@constraint(m, min((0.3*connexions[i,j]+connexions[k,l]),(0.3*connexions[i,j]+connexions[k,l])) < 1)
							#(((connexions[i,j]==1)||(connexions[k,l]==1))&&(!((connexions[i,j]==1)&&(connexions[k,l]==1))))==true
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
disp_sol(solution, t)
@show(solve)






"""
Heuristically solve an instance
"""
function affich(message::String, affich_bool::Bool) # Jute pour éviter d'avoir un affichage immense
    if affich_bool
        println(message)
    end
end

function heuristicSolve(cas::Array{Int, 2}, ponts::Array{Int, 2}, ponts_poss::Array{Int, 2}, nbr_ponts::Array{Int, 1}, testes_heuris::Array{Int, 2}, solve::Bool, erreur::Bool, affich_heuris::Bool)
    affich_ponts_poss = false
    
    affich("\nAPPEL : heuristicSolve", affich_heuris)
    if solve # On a réolu le problème
        return cas, ponts, ponts_poss, nbr_ponts, testes_heuris, true, false, affich_heuris
        
    else   
        # Temporaire !
        if erreur
            return cas, ponts, ponts_poss, nbr_ponts, testes_heuris, false, true, affich_heuris
        end

        n = size(cas, 1) # Nombre de noeuds à connecter

        ponts_poss = ponts_poss_calc(cas, ponts, nbr_ponts, testes_heuris, affich_ponts_poss) # Calcul des possibilités

        ajout = true # Pour le premier passage

        # Est ce qu'on peut ajouter un pont certain ?
            while ajout # Tant qu'on a réussi à en jouter lors du passage précédent, on continue
                ajout = false # Au cas où on n'en ajoute pas
                for i in 1:n # On parcourt tous les noeuds
                    #@show i, nbr_ponts[i]
                    if (cas[i, 3] > nbr_ponts[i]) # On vérifie que le noeud n'est pas déjà saturé
                        #affich("Noeud " *string(i) * " non saturé", affich_heuris)

                        # Ajout/détection d'erreur en cas de possibilité unique
                            position_poss_i = 0
                            unique = true
                            nbr_poss_i = 0
                            for j in 1:n
                                if ponts_poss[i, j] > 0
                                    if nbr_poss_i >= 1
                                        unique = false # repère si on avait déjà changé une fois (i.e. on n'a plusieurs ponts possibles avec plusieurs autres noeuds)
                                    end
                                    position_poss_i = j
                                    nbr_poss_i = nbr_poss_i + ponts_poss[i, j]
                                end
                            end

                            if unique # ie on a de ponts possible qu'avec un (ou aucun) noeud, mais pas plusieurs
                                if nbr_poss_i == 0 # Aucune possibilité pour le noeud i alors qu'il n'est pas saturé, donc erreur
                                    #@show nbr_ponts[i], i
                                    affich("    ERREUR : 0 possibilités pour " * string(cas[i, 3] - nbr_ponts[i]) * " ponts à mettre pour le noeud " * string(cas[i, :]), affich_heuris)
                                    return cas, ponts, ponts_poss, nbr_ponts, testes_heuris, false, true, affich_heuris
                                
                                elseif nbr_poss_i <= 2 # Une unique possibilité, on la met ()
                                    ponts[i, position_poss_i] = ponts_poss[i, position_poss_i] # Avec une valeur de liens calculée
                                    ponts[position_poss_i, i] = ponts_poss[i, position_poss_i] # symétrie

                                    nbr_ponts[i] += ponts_poss[i, position_poss_i] # On a ajouté un pont au noeud i
                                    nbr_ponts[position_poss_i] += ponts_poss[i, position_poss_i] # Et on a ajouté un pont au noeud position_poss_i
                                    
                                    ponts_poss = ponts_poss_calc(cas, ponts, nbr_ponts, testes_heuris, affich_ponts_poss) # Calcul des possibilités (renouvelé à chaque fois qu'il y a modification)
                                    ajout = true # Pour bien recommencer le while
                                    affich("    AJOUT : unique possibilité pour le noeud " * string(cas[i, :]), affich_heuris)
                                end

                                if cas[i, 3] - nbr_ponts[i] > 2 || cas[i, 3] - nbr_ponts[i] > cas[position_poss_i, 3] # Une unique possibilité pour mettre plus de deux ponts, erreur
                                    affich("    ERREUR : " * string(cas[i, 3] - nbr_ponts[i]) * " ponts à mettre pour le noeud " * string(cas[i, :]) * " avec 2 ou " * string(cas[position_poss_i, 3]) * " possibilités", affich_heuris)
                                    return cas, ponts, ponts_poss, nbr_ponts, testes_heuris, false, true, affich_heuris
                                end
                            end

                        # Ajout en cas de possibilités saturées
                            if sum(ponts_poss[i, j] for j in 1:n) == cas[i, 3] - nbr_ponts[i] # Le noeud est saturé, les possibilités sont donc nécessaires.
                                affich("    AJOUT : possibilités saturées pour le noeud " * string(cas[i, :]), affich_heuris)
                                for j in 1:n
                                    #@show cas[j, :]
                                    #@show ponts_poss[i, j]
                                    if ponts_poss[i, j] >= 1
                                        ponts[i, j] = ponts_poss[i, j]
                                        ponts[j, i] = ponts_poss[i, j]
                                        nbr_ponts[i] += ponts_poss[i, j] # On a ajouté un pont au noeud i
                                        nbr_ponts[j] += ponts_poss[i, j] # Et on a ajouté un pont au noeud j
                                        ponts_poss = ponts_poss_calc(cas, ponts, nbr_ponts, testes_heuris, affich_ponts_poss) # Calcul des possibilités (renouvelé à chaque fois qu'il y a modification)
                                        ajout = true # Pour bien recommencer le while
                                        
                                        #@show cas[i, 3] - nbr_ponts[i]
                                    end
                                end
                            end


                    elseif (cas[i, 3] < nbr_ponts[i]) # Surcharge sur le noeud i : erreur
                        affich(string("    ERREUR  : " * nbr_ponts[i]) * " ponts pour le noeud " * string(cas[i, :]) * " de capacité " * string(cas[i, 3]), affich_heuris)
                        return cas, ponts, ponts_poss, nbr_ponts, testes_heuris, false, true, affich_heuris
                    end
                end
                affich("    Fin de while", affich_heuris)
            end
        
        
        
        # Est-ce qu'on est arrivé au bout ??? Est-ce qu'on force ???
            solve = true
            pos_non_sat = 0
            for i in 1:n
                if nbr_ponts[i] < cas[i, 3] # Tous les ponts sont faits ?
                    solve = false
                    pos_non_sat = i
                    break
                end
            end

            if solve
                return heuristicSolve(cas, ponts, ponts_poss, nbr_ponts, testes_heuris, solve, false, affich_heuris)
            else
                # Sinon, on essaie de forcer une possibilité
                    ponts_poss = ponts_poss_calc(cas, ponts, nbr_ponts, testes_heuris, affich_ponts_poss) # Calcul des possibilités, au cazou
                    j = 1
                    while ponts_poss[pos_non_sat,j] == 0  &&  j <= n+1  &&  testes_heuris[pos_non_sat, j] != 0 # On n'est pas censé boucler ici, en principe...
                        j += 1    
                    end

                    if j == n+1
                        println("   Problème de saturation dans l'heuristique !")
                    
                    else
                        ponts[pos_non_sat,j] += 1 # On force une seule possibilité, pour voir
                        nbr_ponts[pos_non_sat] += 1 # On la compte
                        nbr_ponts[j] += 1

                        # Puis on résout, et on voit si on obtient une erreur
                        @show(cas, ponts, ponts_poss, nbr_ponts, testes_heuris, solve, erreur, affich_heuris)
                        cas, ponts, ponts_poss, nbr_ponts, testes_heuris, solve, erreur, affich_heuris = heuristicSolve(cas, ponts, ponts_poss, nbr_ponts, testes_heuris, solve, false, affich_heuris)
                        
                        if erreur # si oui on revient sur nos pas
                            ponts[pos_non_sat,j] -= 1 # On enlève la possibilité puisqu'elle a mené à une erreur
                            nbr_ponts[pos_non_sat] -= 1
                            nbr_ponts[j] -= 1
                            ponts_poss[pos_non_sat,j] = 0
                            testes_heuris[pos_non_sat, j] = 0
                            testes_heuris[j, pos_non_sat] = 0
                        end

                        #Si non on a gagné
                        return heuristicSolve(cas, ponts, ponts_poss, nbr_ponts, testes_heuris, solve, erreur, affich_heuris)
                    end
                
                        
                    
            end
        
    end
end


function ponts_poss_calc(cas::Array{Int, 2}, ponts::Array{Int, 2}, nbr_ponts::Array{Int, 1}, testes_heuris::Array{Int, 2}, affich_ponts_poss::Bool) # Remplissage de ponts_poss
    affich("\n    APPEL : ponts_poss_calc", affich_ponts_poss)
    ponts_poss = zeros(Int, n, n)

    for i in 1:n
        for j in i+1:n
            if (cas[i, 3] > nbr_ponts[i]) && (cas[j, 3] > nbr_ponts[j]) && ponts[i, j] < 2 #Les noeuds ne sont pas saturés, le pont non plus
                #affich("ponts_poss_calc : non saturation", affich_ponts_poss)

                if (cas[i,1] == cas[j,1]) || (cas[i,2] == cas[j,2]) # Si même abscisse ou même ordonnée, pont possible (pas de diagonale)
                    affich("        Pont possible pour les noeuds : " * string(cas[i, :]) * " et " * string(cas[j, :]) * " de valeur max = " * string(min(cas[j,3] - nbr_ponts[j], cas[i,3] - nbr_ponts[i], 2 - ponts[i, j], 2)), affich_ponts_poss)
                    
                    if arete_possible(cas, ponts, i, j, false) # True : le passage est libre ! False : il y aurait croisement
                        ponts_poss[i, j] = min(cas[j,3] - nbr_ponts[j], cas[i,3] - nbr_ponts[i], 2 - ponts[i, j], 2) # Pont de taille <= 2 et allant jusqu'à la capacité minimale des deux encore disponible
                        ponts_poss[j, i] = ponts_poss[i, j] # Symétrique
                    end
                end
            end
            ponts_poss[i, j] = min(ponts_poss[i, j], testes_heuris[i, j])
            ponts_poss[j, i] = min(ponts_poss[i, j], testes_heuris[i, j])
        end
    end
    affich("    FIN : ponts_poss_calc\n", affich_ponts_poss)
    return ponts_poss
end


# True : le passage est libre ! False : il y aurait croisement
function arete_possible(cas::Array{Int, 2}, ponts::Array{Int, 2}, k::Int, l::Int, affich_arete_poss::Bool)
    affich("\n        APPEL : arete_possible", affich_arete_poss)

    x_1 = min(cas[k, 1], cas[l, 1])
    y_1 = min(cas[k, 2], cas[l, 2])
    
    x_2 = max(cas[k, 1], cas[l, 1])
    y_2 = max(cas[k, 2], cas[l, 2])
    
    n = size(cas, 1)
    
    if x_1 == x_2 && y_1 == y_2 #Point identique
        affich("            Points identiques\n", affich_arete_poss)
        affich("        FIN : arete_possible\n", affich_arete_poss)
        return false
    end

    if x_1 == x_2
        for i in 1:n
            # Un noeud sur le chemin
            if cas[i, 1] == x_1  &&  y_1 < cas[i, 2]  &&  cas[i, 2] < y_2
                affich("            Croisement : l'arête " * string(cas[k, :]) * " <-> " * string(cas[l, :]) * " passe par le noeud " * string(cas[i, :]), affich_arete_poss)
                affich("        FIN : arete_possible\n", affich_arete_poss)
                return false
            end

            for j in i+1:n
                # L'autre noeud sur le chemin
                if cas[j, 1] == x_1  &&  y_1 < cas[j, 2]  &&  cas[j, 2] < y_2  
                    affich("            Croisement : l'arête " * string(cas[k, :]) * " <-> " * string(cas[l, :]) * " passe par le noeud " * string(cas[j, :]), affich_arete_poss)
                    affich("        FIN : arete_possible\n", affich_arete_poss)
                    return false
                end


                if ponts[i, j] >= 1 # On regarde parmi les connexions
                    if (min(cas[i, 1], cas[j, 1]) < x_1)  &&  (max(cas[i, 1], cas[j, 1]) > x_2)
                        if cas[i, 2] == cas[j, 2]  &&  y_1 < min(cas[i, 2], cas[j, 2]) && max(cas[i, 2], cas[j, 2]) < y_2 #on a croisement !
                            affich("            Croise-t-on une autre arête ? Oui", affich_arete_poss)
                            affich("            Croisement : l'arête " * string(cas[k, :]) * " <-> " * string(cas[l, :]) * " avec " * string(cas[i, :]) * " <-> " * string(cas[j, :]), affich_arete_poss)
                            affich("        FIN : arete_possible\n", affich_arete_poss)
                            return false
                        end
                    end
                end
            end
        end
        
        affich("            Croise-t-on une autre arête ? Non", affich_arete_poss)
        affich("        FIN : arete_possible\n", affich_arete_poss)
        return true

    end

    if y_1 == y_2
        for i in 1:n
            # Un noeud sur le chemin
            if cas[i, 2] == y_1  &&  x_1 < cas[i, 1]  &&  cas[i, 1] < x_2
                affich("            Croisement de l'arête " * string(cas[k, :]) * " <-> " * string(cas[l, :]) * " passe par le noeud " * string(cas[i, :]), affich_arete_poss)
                affich("        FIN : arete_possible\n", affich_arete_poss)
                return false
            end

            for j in i+1:n
                # L'autre noeud sur le chemin
                if cas[j, 1] == y_1  &&  x_1 < cas[j, 1]  &&  cas[j, 1] < x_2
                    affich("            Croisement de l'arête " * string(cas[k, :]) * " <-> " * string(cas[l, :]) * " passe par le noeud " * string(cas[j, :]), affich_arete_poss)
                    affich("        FIN : arete_possible\n", affich_arete_poss)
                    return false
                end

                if ponts[i, j] >= 1 # On regarde parmi les connexions
                    # Premier cas : toutes inégalités strictes
                    if min(cas[i, 2], cas[j, 2]) < y_1 && max(cas[i, 2], cas[j, 2]) > y_1
                        if x_1 < min(cas[i, 1], cas[j, 1]) && max(cas[i, 1], cas[j, 1]) < x_2 #on a croisement !
                            affich("            Croise-t-on une autre arête ? Oui", affich_arete_poss)
                            affich("            Croisement de l'arête " * string(cas[k, :]) * " <-> " * string(cas[l, :]) * " avec " * string(cas[i, :]) * " <-> " * string(cas[j, :]), affich_arete_poss)
                            affich("        FIN : arete_possible\n", affich_arete_poss)
                            return false
                        end
                    end
                end
            end
        end
        affich("            Croise-t-on une autre arête ? Non", affich_arete_poss)
        affich("        FIN : arete_possible\n", affich_arete_poss)
        return true
    end

    affich("            Croise-t-on une autre arête ? Non, mais on considère une arête en diagonale, impossible", affich_arete_poss)
    affich("        FIN : arete_possible\n", affich_arete_poss)
    return false # Connexion en diagonale
end




"""
cas = t_2
n = size(cas, 1)
cas, ponts, ponts_poss, nbr_ponts, testes_heuris, solve, erreur = heuristicSolve(cas, zeros(Int, n, n), zeros(Int, n, n), zeros(Int, n), 2 * ones(Int, n, n), false, false, true)
#for i in 1:n
#    println(ponts_poss[i, :])
#end

println(ponts)
disp_sol(ponts, cas)
@show(solve)

"""




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




function exploration(ind::Int64, sommet::Int64, cas::Array{Int, 2}, ponts::Array{Float64, 2}, comp_conx::Array{Float64,1})
	n = size(cas, 1)
	comp_conx[sommet] = ind
	test= true

	for i in 1:n
		if ((ponts[sommet, i] > 0)&&(comp_conx[i] == 0))
			#i est un successeur non marqué de sommet : on va ajouter à la composante connexe courante
			exploration(ind,i, cas, ponts, comp_conx)
		end
	end
	#on a exploré la composante conenxe de sommet
end
	



function connexifie(cas::Array{Int, 2}, ponts::Array{Float64, 2})
"""
Cette fonction vise à rendre connexe un graphe donné
"""
	n = size(cas, 1)
	
	
	#chaque sommet finira dans une composante connexe identifiée par 1,2,...
	comp_conx = zeros(n)
	

	curr_ind = Int64(0)
	for i in 1:n
		if comp_conx[i] == 0
			curr_ind = curr_ind+1
			exploration(curr_ind, i, cas, ponts, comp_conx)
			println("on a exploré une composante connexe")
			println(comp_conx)
			println(curr_ind)
		end
	end
	#on a identifié toutes les composantes connexes	
	#on va tenter de connexifier le graphe si leur nobr est supérieur à 1

	return curr_ind, comp_conx
end



nb_comp_conx, composantes = connexifie(t,solution)
println("resultats")
println(nb_comp_conx)
println(composantes)	
	
		
			
		

	




