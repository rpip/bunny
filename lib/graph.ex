defmodule Bunny.Graph do
  @moduledoc """

  """

  @type t :: [{Bunny.task(), [Bunny.dep()]}]

  @doc """
  Translates the keyword tree structure to vertices and edges,
  and then topologically sorts the nodes/vertices and edges.
  """
  @spec topsort(t) :: {:ok, [Bunny.task()]} | {:error, {:cyclic, [Bunny.task()]}}
  def topsort(graph) do
    g = :digraph.new()

    Enum.each(graph, fn {task, deps} ->
      :digraph.add_vertex(g, task)
      Enum.each(deps, fn dep -> add_edge(g, task, dep) end)
    end)

    if sorted = :digraph_utils.topsort(g) do
      {:ok, Enum.reverse(sorted)}
    else
      circular_deps =
        :digraph.vertices(g)
        |> Enum.map(fn v -> :digraph.get_short_cycle(g, v) end)
        |> Enum.reject(&is_boolean/1)

      {:error, {:cyclic, circular_deps}}
    end
  end

  defp add_edge(g, task, dep) do
    :digraph.add_vertex(g, dep)
    :digraph.add_edge(g, task, dep)
  end
end
