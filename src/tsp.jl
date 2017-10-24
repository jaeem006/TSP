Pkg.init()  
#Pkg.add("SQLite3")
#using SQLite
Pkg.add("ODBC")
using ODBC
println("So it begins")

ODBC.connect("tsp.db")
println("Ya me conecte!!")
total_cities = 1092 #10
decreasingTRate = 0.85
batchSize = 400
epsilonTemp = 0.0001
epsilonP = 0.007
constantN = 100
epsilonT = 0.00001
epsilonA = 0.01
initInitialTemp = 0.8
acceptancePercentageParameter = 0.87
cities = [6,9,10,12,13,33,34,35,39,40,43,44,46,50,52,62,63,69,73,74,79,83,86,90,93,94,95,101,104,107,109,111,113,114,115,117,119,121,123,133,137,138,141,142,145,149,151,156,158,159,177,180,181,185,189,193,194,203,212,213,221,222,223,231,233,234,235,242,243,245,246,255,256,257,258,261,262,263,266,269,272,275,278,279,280,281,285,289,290,297,298,299,302,303,305,308,310,313,317,319,322,323,324,326,332,333,334,337,339,341,342,345,346,347,358,359,360,365,366,369,371,372,382,395,398,399,400,404,406,407,408,410,412,414,415,419,422,423,430,431,433,437,438,441,442,447,449,452,453,454,456,462,463,464,469,470,473,475,477,478,480,484,492,494,497,498,499,503,508,515,519,520,526,529,534,535,541,543,545,546,552,562,564,565,566,568,574,575,576,582,583,591,593,598,601,606,611,615,620,621,625,626,627,628,630,637,638,639,644,650,654,664,669,673,675,678,679,681,690,694,695,697,700,701,710,711,717,718,719,722,735,740,741,743,757,759,761,766,768,770,772,773,777,780,781,782,785,792,796,797,803,812,814,817,822,823,829,830,832,837,839,840,844,848,853,854,858,860,863,865,871,872,876,877,880,881,890,892,893,895,897,899,900,906,910,915,916,920,922,923,924,935,936,940,943,955,957,960,964,970,973,978,980,981,991,992,995,996,999,1001,1002,1006,1008,1009,1010,1011,1012,1016,1022,1025,1031,1034,1037,1043,1046,1048,1057,1060,1062,1063,1067,1069,1070,1072,1077,1079,1082,1083,1085,1087,1090,1091] #[22,74,109,113,117,137,178,180,200,216,272,299,345,447,492,493,498,505,521,572,607,627,642,679,710,717,747,774,786,829,830,839,853,857,893,921,935,986,1032,1073] #[2,3,5,6,7,9]
cities_length = length(cities)
seed = 450000#1597
conections = rand(0:seed,total_cities, total_cities)
F = 50
final_solution = []

#db = SQLite.DB("tsp.db")
#println("ME CONECTE!!!!")

#query = "SELECT * FROM cities WHERE id = 12;"
#query(db, query)

#db = SQLite("passwd.sqlite")
#create(db, "passwd", readdlm("/etc/passwd", ':'), ["username", "password", "UID", "GID", "comment", "homedir", "shell"])
#query(db, "SELECT username, homedir FROM passwd LIMIT 10;")
#close(db,

function randpath(n)
    path = 1:n |> collect |> shuffle
    push!(path, path[1]) # loop
    return path
end

function solucion_inicial(s)
    n = rand(1:seed)
    for counter = 0:n
        s = vecino(s)
    end
    return s
end 

#used to returs sum of weights, av weigth and punish 
function weight_path(s)
    counter = 0
    stop = length(s)-1
    #caminito = zeros(stop)
    for i = 1:length(s) - 1
        peso = conections[s[i],s[i+1]]
        counter = counter + peso
       #caminito[i] = peso
    end
    return counter
end

function av_weight(s)
    return weight_path(s)/length(s) - 1
end

function castigo(s)
    stop = length(s)-1
    caminito = zeros(stop)
    for i = 1:length(s) - 1
        peso = conections[s[i],s[i+1]]
        caminito[i] = peso
    end
    return F * caminito[indmax(caminito)]
end

function overweight(s)
    p = castigo(s)
    stop = length(s)-1
    caminito = zeros(stop)
    counter = 0
    for i = 1:length(s) - 1
        peso = conections[s[i],s[i+1]]
        if peso == 0
            caminito[i] = p
            counter = counter + p
        else
            caminito[i] = peso
            counter = counter + peso
        end 
    end
    return counter
end

function calculaLote(T, s)
    c = 0 
    r = 0.0
    while c < batchSize
        s1 = vecino(s)
        f_s1 = f_costo(s1)
        f_s = f_costo(s)
        if  f_s1 <= f_s + T
            s = s1
            c = c + 1
            r = r + f_s1
            if f_s1 < f_s
                final_solution = s1
            end
        end
    end
    return r/batchSize, s
end

function vecino(s)
    i,j = rand_positions()
    return swap(s,i,j)
end 

function swap(arr, i, j)
    temp = arr[i]
    arr[i] = arr[j]
    arr[j] = temp
    return arr
end

function rand_positions()
    i = j = 0
    while i == j
        i = rand(1:cities_length)
        j = rand(1:cities_length)
    end
    return i,j
end

function f_costo(s)
    suma = overweight(s)
    return suma / av_weight(s)
    return 
end

function aceptacionPorUmbrales(T, s)
    p = 0
    q = -1
    while T > epsilonT
        p1 = q
        while p <= p1 || q == -1
            p1 = p 
            p, s = calculaLote(T, s)
            q = p
            println(string("nueva solucion: ", s))
            println(string("funcion de costo: ", p))
        end
        T = decreasingTRate * T
        println(string("nueva temperatura : ",T))
    end
    return 
end

function simulated_annealing{T <: Real}(distmat::Matrix{T}; steps = 50*length(distmat),
                                        num_starts = 1,
                                        init_temp = exp(8), final_temp = exp(-6.5),
                                        init_path::Nullable{Vector{Int}} = Nullable{Vector{Int}}())

    
    cool_rate = (final_temp / init_temp)^(1 / (steps - 1))

    function sahelper()
        temp = init_temp / cool_rate
        n = size(distmat, 1)
        path = isnull(init_path) ? randpath(n) : copy(get(init_path))
        cost_cur = pathcost(distmat, path)

        for i in 1:steps
            temp *= cool_rate

            first, last = rand(2:n), rand(2:n)
            if first > last
                first, last = last, first
            end
            cost_other = pathcost_rev(distmat, path, first, last)
            @fastmath accept = cost_other < cost_cur ? true : rand() < exp((cost_cur - cost_other) / temp)
            if accept
                reverse!(path, first, last)
                cost_cur = cost_other
            end
        end

        return path, cost_cur
    end

    path, cost = sahelper()
    for _ in 2:num_starts
        otherpath, othercost = sahelper()
        if othercost < cost
            cost = othercost
            path = otherpath
        end
    end

    return path, cost
end


#r = [1,2,3,4,5,6]
#print(swap(r, 1, 4))
#print(rand_positions())
#path = randpath(cities_length)
#println(cities)
#println(conections)
#println(castigo(cities))
#SOLUTION = solucion_inicial(cities)
#final_solution = SOLUTION
#println(SOLUTION)
#println(weight_path(SOLUTION))
#println(overweight(SOLUTION))
#println(av_weight(SOLUTION))
#println(f_costo(SOLUTION))
#aceptacionPorUmbrales(initInitialTemp, SOLUTION)
#println(string("solucion final: ", final_solution))
#println(string("costo final: ", f_costo(final_solution)))

