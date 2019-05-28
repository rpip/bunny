defmodule Bunny do
  @moduledoc """
  """
  alias Bunny.{Graph, InvalidTaskError}
  alias Bunny.Serializers.{JSON, Shell}

  @type task :: String.t()
  @type dep :: task
  @type dead_path :: [{task, [dep]}]

  @doc """
  Sorts the tasks to create a proper execution order.

  Starts by extracting tasks and depedencies from the collection of tasks,
  and then parsing this graph of paths to graph to evaluate.

  Raises a Bunny.InvalidTaskError if task schema is invalid.
  """
  @spec sort([map]) ::
          {:ok, map}
          | {:error, {:dead_path, [dead_path]}}
          | {:error, {:cyclic, [[task]]}}
  def sort(job) do
    with {:ok, graph} <- build_graph!(job) do
      with {:ok, top_sorted} <- Graph.topsort(graph) do
        job2 = Enum.into(job, %{}, fn task -> {task["name"], task} end)
        sorted_tasks = Enum.map(top_sorted, fn task -> job2[task] end)
        {:ok, sorted_tasks}
      end
    end
  end

  @doc """
  Sorts the tasks and serializes the results in the given format.

  Supported formats are JSON and Shell
  """
  def sort(job, :json) do
    with {:ok, sorted_tasks} <- sort(job) do
      JSON.serialize(sorted_tasks)
    end
  end

  def sort(job, :shell) do
    with {:ok, sorted_tasks} <- sort(job) do
      Shell.serialize(sorted_tasks)
    end
  end

  ## private

  ## Returns a simple tree structure mapping tasks to dependencies.
  def build_graph!(tasks) do
    name_deps =
      Enum.map(tasks, fn task ->
        validate_schema!(task)

        {task["name"], Map.get(task, "requires", [])}
      end)

    case check_dead_paths(name_deps) do
      [] ->
        graph =
          Enum.reduce(
            name_deps,
            Graph.new() |> Graph.add_vertices(Keyword.keys(name_deps)),
            fn {task, deps}, g ->
              Graph.add_edges(g, task, deps)
            end
          )

        {:ok, graph}

      dead_paths ->
        {:error, {:dead_path, dead_paths}}
    end
  end

  defp validate_schema!(task) do
    valid = Enum.all?(["name", "command"], &Map.has_key?(task, &1))
    unless valid, do: raise(InvalidTaskError, task: task)
  end

  # checks for missing/dead requirements
  defp check_dead_paths(graph) do
    nodes = Keyword.keys(graph)

    Enum.map(graph, fn {task, deps} ->
      missing = Enum.filter(deps, &(&1 not in nodes))
      {task, missing}
    end)
    |> Enum.reject(fn {_t, missing} -> missing == [] end)
  end
end

defmodule Bunny.InvalidTaskError do
  defexception [:message, :task]

  def exception(task) do
    msg = "Task is missing name or command fields"
    %__MODULE__{message: msg, task: task}
  end
end
