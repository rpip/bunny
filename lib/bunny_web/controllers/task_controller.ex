defmodule BunnyWeb.TaskController do
  use BunnyWeb, :controller

  def sort(conn, %{"tasks" => tasks} = _params) do
    case Bunny.sort(tasks, :json) do
      {:ok, sorted_tasks} ->
        json(conn, sorted_tasks)

      {:error, reason} ->
        conn
        |> put_status(400)
        |> json(format_error(reason))
    end
  end

  def sort(conn, params) do
    # work around file POST request is sent as urlencoded
    # happens when client omits JSON header
    # eg: $ curl -d @mytasks.json http://localhost:4000
    sort(conn, decode_stream!(params))
  end

  def shell(conn, %{"tasks" => tasks} = _params) do
    case Bunny.sort(tasks, :shell) do
      {:ok, sorted_tasks} ->
        text(conn, sorted_tasks)

      {:error, reason} ->
        conn
        |> put_status(400)
        |> json(format_error(reason))
    end
  end

  def shell(conn, params) do
    # work around file POST request is sent as urlencoded
    # happens when client omits JSON header
    # eg: $ curl -d @mytasks.json http://localhost:4000/sh | bash
    shell(conn, decode_stream!(params))
  end

  defp decode_stream!(params) do
    Map.keys(params) |> Enum.at(0) |> Jason.decode!()
  end

  defp format_error({:cyclic, cyclic_tasks}) do
    %{
      type: :invalid_request_error,
      message: "circular depedencies found",
      details: Map.new(cyclic_tasks)
    }
  end
end
