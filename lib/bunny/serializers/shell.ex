defmodule Bunny.Serializers.Shell do
  use Bunny.Serializer

  # interpreter for execution under UNIX / Linux systems
  @shebang "#!/usr/bin/env bash"

  @spec serialize(map) :: {:ok, String.t()}
  def serialize(tasks) do
    commands =
      tasks
      |> Enum.map(&Map.get(&1, "command"))
      |> Enum.join("\n")

    {:ok, "#{@shebang}\n#{commands}"}
  end
end
