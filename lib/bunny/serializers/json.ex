defmodule Bunny.Serializers.JSON do
  use Bunny.Serializer

  @spec serialize(map) :: {:ok, map}
  def serialize(tasks) do
    trimmed = Enum.map(tasks, fn task -> Map.delete(task, "requires") end)
    {:ok, trimmed}
  end
end
