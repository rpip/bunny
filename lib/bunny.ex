defmodule Bunny do
  @moduledoc """
  """
  alias Bunny.{Graph, InvalidTaskError}

  @type task :: String.t()
  @type dep :: task
  @type dead_path :: [{task, [dep]}]
  @type job :: [map]

  def parse_file!(fpath) do
    File.read!(fpath)
    |> Jason.decode!()
    |> Map.get("tasks")
    |> sort
  end

  @doc """
  Sorts the tasks to create a proper execution order.

  Starts by extracting tasks and depedencies from the collection of tasks,
  and then parsing this graph of paths to graph to evaluate.

  Raises a Bunny.InvalidTaskError if task schema is invalid.
  """
  @spec sort(job) ::
          {:ok, map}
          | {:error, {:dead_paths, [dead_path]}}
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

  ## private

  ## Returns a simple tree strcuture mapping tasks to dependencies.
  defp build_graph!(tasks) do
    graph =
      Enum.map(tasks, fn task ->
        validate_schema!(task)

        {task["name"], Map.get(task, "requires", [])}
      end)

    case check_dead_paths(graph) do
      [] -> {:ok, graph}
      dead_paths -> {:error, {:dead_paths, dead_paths}}
    end
  end

  defp validate_schema!(task) do
    valid = Enum.all?(["name", "command"], &Map.has_key?(task, &1))
    unless valid, do: raise(InvalidTaskError, task: task)
  end

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
