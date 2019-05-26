defmodule Bunny.Formatter do
  @moduledoc """
  """

  # interpreter for execution under UNIX / Linux systems
  @shebang "#!/usr/bin/env bash"

  def pretty_print(tasks, :json) do
    Enum.map(tasks, fn task -> Map.delete(task, "requires") end)
  end

  def pretty_print(tasks, :shell) do
    commands =
      tasks
      |> Enum.map(&Map.get(&1, "command"))
      |> Enum.join("\n")

    "#{@shebang}\n#{commands}"
  end
end
