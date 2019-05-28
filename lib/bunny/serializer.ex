defmodule Bunny.Serializer do
  @moduledoc """
  This module defines the Serializer behavior for graphs.
  """
  @callback serialize(Graph.t()) :: {:ok, binary} | {:error, term}

  defmacro __using__(_) do
    quote do
      @behaviour Bunny.Serializer
    end
  end
end
