defmodule Bunny.Graph do
  @moduledoc """
  This module defines a simple graph data structure, with
  API for creating, manipulating, and sorting that structure.

  Graph is represented as adjacency list representation. For each node,
  we keep a list of references to the adjoining/neighbouring nodes,
  one for each adjoining edge.

  To avoid conflict with Elixir/Erlang node type, we call the node vertex.

  Vertices means list of nodes.

  ## Example

     iex> alias Bunny.Graph
     iex> g = Graph.new |> Graph.add_vertices([1, 2, 3, 4])
     ...> g = Graph.add_edges(g, 4, [2, 3])
     ...> Graph.vertices(g)
     [1, 2, 3, 4]
  """
  alias __MODULE__

  @type t :: %__MODULE__{}
  @type vertex :: term
  @type edge :: term

  # a map of node ids to referenced nodes
  defstruct vertices: %{}

  def new(), do: %Graph{}

  @doc """
  Like add_vertex/1, but takes a list of vertices to add to the graph

  ## Example

     iex> alias Bunny.Graph
     iex> Graph.new |> Graph.add_vertices(["task-1", "task-2", "task-3", "task-4"])
     %Bunny.Graph{
       vertices: %{
         "task-1" => [],
         "task-2" => [],
         "task-3" => [],
         "task-4" => [],
       }
     }
  """
  @spec add_vertices(t, [vertex]) :: t
  def add_vertices(g = %Graph{}, vertices) do
    Enum.reduce(vertices, g, fn e, g -> add_vertex(g, e) end)
  end

  @doc """
  Adds a new vertex to the graph. no-op if the vertex is already present in the graph

  ## Example

     iex> alias Bunny.Graph
     iex> Graph.new |> Graph.add_vertex("task-1")
     %Bunny.Graph{
       vertices: %{
         "task-1" => [],
       }
     }
  """
  @spec add_vertex(t, vertex) :: t
  def add_vertex(%Graph{vertices: vs}, vertex) do
    %Graph{vertices: Map.put_new(vs, vertex, [])}
  end

  @doc """
  Returns the vertices in the graph.

  ## Example

     iex> alias Bunny.Graph
     iex> Graph.new |> Graph.add_vertex("task-1") |> Graph.vertices
     ["task-1"]
  """
  @spec vertices(t) :: [vertex]
  def vertices(%Graph{vertices: vs}) do
    Map.keys(vs)
  end

  @doc """
  Returns the edges for the given vertex in the graph.

  ## Example

     iex> alias Bunny.Graph
     ...> g = Graph.new |> Graph.add_vertex("task-4")
     ...> Graph.add_edges(g, "task-4", ["task-2", "task-3"])
     ...> |> Graph.edges("task-4")
     ["task-2", "task-3"]
  """
  @spec edges(t, vertex) :: [edge]
  def edges(%Graph{vertices: vs}, vertex) do
    Map.get(vs, vertex)
  end

  @doc """
  Like add_edge/3 but takes a list of edges to add to the given vertex.

  ## Example

     iex> alias Bunny.Graph
     ...> g = Graph.new |> Graph.add_vertex("task-4")
     ...> Graph.add_edges(g, "task-4", ["task-2", "task-3"])
     %Bunny.Graph{
       vertices: %{
         "task-4" => ["task-2", "task-3"],
       }
     }
  """
  @spec add_edges(t, vertex, [edge]) :: t
  def add_edges(g, vertex, edges) do
    Enum.reduce(edges, g, &add_edge(&2, vertex, &1))
  end

  @doc """
  Adds an edge to add to the given vertex in the graph.

  ## Example

     iex> alias Bunny.Graph
     ...> g = Graph.new |> Graph.add_vertex("task-2")
     ...> Graph.add_edge(g, "task-2", "task-3")
     %Bunny.Graph{
       vertices: %{
         "task-2" => ["task-3"],
       }
     }
  """
  @spec add_edge(t, vertex, edge) :: t
  def add_edge(%Graph{vertices: vs}, vertex, edge) do
    v = Map.update(vs, vertex, edge, &(&1 ++ [edge]))
    %Graph{vertices: v}
  end

  @doc """
  Topologically sorts the nodes, and detects cycles using depth-first-search algorithm.

  The heart of the algorithm is in dfs_topsort/1 and visit/6.
  The algorithm loops through each node of the graph,
  in an arbitrary order, initiating a depth-first search that terminates
  when it hits any node that has already been visited since the
  beginning of the topological sort or the node has no outgoing edges.

  To make the algorithm efficient, we keep a separate set of nodes
  that have been visited so far. That way, we visit each vertex at most once,
  and considers each edge at most once.

  To provide meaningful and precise errors, we also track the cycles and
  build up found cycles for every node. This is where we use ETS to store
  stateful data.
  """
  def topsort(g) do
    case dfs_topsort(g) do
      {false, sorted, _} ->
        {:ok, sorted}

      {true, _sorted, found_cycles} ->
        {:error, {:cyclic, found_cycles}}
    end
  end

  @spec dfs_topsort(t) :: {boolean, [vertex], map}
  defp dfs_topsort(g) do
    # cyclic nodes
    cycles = :ets.new(:cycles, [:ordered_set, :protected])
    # initialize
    Enum.each(vertices(g), fn x -> :ets.insert(cycles, {x, []}) end)

    # tracking current path
    path = :ets.new(:path, [:set, :protected])
    # visited nodes
    visited = :ets.new(:visited, [:set, :protected])
    # sorted nodes
    sorted = :ets.new(:set, [:ordered_set, :protected])

    # for each node, recursively visit the node and mark circular deps and non circular deps
    dfs_nodes = Enum.map(vertices(g), &visit(g, &1, cycles, sorted, path, visited))
    found_cycles = :ets.tab2list(cycles) |> Enum.reject(fn {_k, v} -> v == [] end)
    topsorted_nodes = :ets.tab2list(sorted) |> Keyword.values()
    {Enum.any?(dfs_nodes), topsorted_nodes, found_cycles}
  end

  # returns true if the node (vertex) in graph(g) has a cycle.
  defp visit(g, vertex, cycles, sorted, path, visited) do
    if not :ets.member(visited, vertex) do
      :ets.insert(visited, {vertex})
      :ets.insert(path, {vertex})

      visit_recur(g, vertex, cycles, sorted, path, visited)
      post_vist_checks(vertex, cycles, sorted, path)
    end
  end

  defp visit_recur(g, vertex, cycles, sorted, path, visited) do
    for neighbour <- edges(g, vertex) do
      cond do
        :ets.member(path, neighbour) ->
          update_cycles(cycles, vertex, neighbour)

        visit(g, neighbour, cycles, sorted, path, visited) ->
          update_cycles(cycles, vertex, neighbour)

        true ->
          :noop
      end
    end
  end

  defp post_vist_checks(vertex, cycles, sorted, path) do
    [{_, found_cycles}] = :ets.lookup(cycles, vertex)

    cond do
      found_cycles != [] ->
        true

      true ->
        :ets.delete(path, vertex)
        # sorted is an ets ordered_set. use time value for ordering values
        :ets.insert(sorted, {Time.utc_now(), vertex})
        false
    end
  end

  defp update_cycles(cycles, vertex, found_cycle) do
    [{_, val}] = :ets.lookup(cycles, vertex)
    :ets.update_element(cycles, vertex, {2, val ++ [found_cycle]})
  end
end
