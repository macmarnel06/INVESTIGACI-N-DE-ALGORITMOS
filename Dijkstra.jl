# =========================================================================
# MÓDULO DEL ALGORITMO DE DIJKSTRA EN JULIA (ENFOQUE FUNCIONAL)
# =========================================================================

module DijkstraAlg

export find_shortest_path

"""
    find_shortest_path(graph::Dict, source)

Calcula las distancias mínimas desde un nodo `source` en un `graph`.
Implementado utilizando inmutabilidad de estados a través de recursión de cola.
"""
function find_shortest_path(graph::Dict{T, Vector{Pair{T, W}}}, source::T) where {T, W <: Number}
    # Inicialización del diccionario de distancias (origen = 0, demás = infinito)
    distances = Dict{T, Any}(node => Inf for node in keys(graph))
    distances[source] = 0.0

    # Lista de nodos no visitados
    unvisited = collect(keys(graph))

    # Invocación al bucle recursivo
    return process_graph(graph, distances, unvisited)
end

# Función recursiva interna (Bucle principal del algoritmo)
function process_graph(graph, distances, unvisited)
    # CASO BASE: Si ya no quedan nodos por visitar, devolvemos el resultado
    if isempty(unvisited)
        return distances
    end

    # Simulación de Cola de Prioridad: Encontrar el nodo no visitado con la menor distancia
    current_node = minimum(node -> distances[node], unvisited)

    # MANEJO DE CASO BORDE: Si el nodo más cercano es inalcanzable (Inf), terminamos
    if distances[current_node] == Inf
        return distances
    end

    # Extracción de vecinos del nodo actual
    neighbors = get(graph, current_node, Pair{eltype(unvisited), Number}[])

    # Fase de Relajación Funcional utilizando `foldl` (equivalente a reduce)
    # Genera un nuevo estado de distancias sin mutar las variables anteriores
    updated_distances = foldl(neighbors, init=distances) do acc, (neighbor, weight)
        new_distance = distances[current_node] + weight
        
        if acc[neighbor] == Inf || new_distance < acc[neighbor]
            # Copiamos y actualizamos el diccionario para mantener la pureza funcional
            new_acc = copy(acc)
            new_acc[neighbor] = new_distance
            return new_acc
        else
            return acc
        end
    end

    # Filtrar el nodo actual de la lista de no visitados (Inmutabilidad conceptual)
    next_unvisited = filter(node -> node != current_node, unvisited)

    # Paso recursivo (Optimizado por el compilador en caso de optimizaciones de cola)
    return process_graph(graph, updated_distances, next_unvisited)
end

end # module

# =========================================================================
# BANCO DE PRUEBAS DE COBERTURA (TEST SUITE)
# =========================================================================

using .DijkstraAlg

# Caso de Prueba 1: Topología de Grafo Estándar Complejo
grafo_produccion = Dict(
    :A => [:B => 6, :C => 2],
    :B => [:D => 1],
    :C => [:B => 3, :D => 5],
    :D => [:E => 3],
    :E => []
)

# Caso de Prueba 2: Caso Borde - Grafo de un Único Nodo Aislado
grafo_mononodo = Dict( :A => [] )

# Caso de Prueba 3: Caso Borde - Grafo Desconectado con Componentes Aislados
grafo_desconectado = Dict(
    :A => [:B => 4],
    :B => [],
    :C => [:D => 2],
    :D => []
)

println("=================================================================")
println("EVALUACIÓN DE CASOS DE PRUEBA EN JULIA")
println("=================================================================")

println("\n>> PRUEBA 1: Grafo Estándar desde Origen ':A'")
# Retorno esperado: Dict(:A => 0.0, :B => 5.0, :C => 2.0, :D => 6.0, :E => 9.0)
display(DijkstraAlg.find_shortest_path(grafo_produccion, :A))

println("\n\n>> PRUEBA 2: Caso Borde - Grafo Mononodo desde ':A'")
# Retorno esperado: Dict(:A => 0.0)
display(DijkstraAlg.find_shortest_path(grafo_mononodo, :A))

println("\n\n>> PRUEBA 3: Caso Borde - Nodos Inalcanzables en Grafo Partido")
# Retorno esperado: Dict(:A => 0.0, :B => 4.0, :C => Inf, :D => Inf)
display(DijkstraAlg.find_shortest_path(grafo_desconectado, :A))
println()
