defmodule BunnyWeb.TaskController do
  use BunnyWeb, :controller

  def sort(conn, %{"tasks" => tasks} = _params) do
    case Bunny.sort(tasks, :json) do
      {:ok, sorted_tasks} -> json(conn, sorted_tasks)
      {:error, reason} -> conn |> put_status(400) |> json(%{"error" => reason})
    end
  end

  def shell(conn, %{"tasks" => tasks} = _params) do
    case Bunny.sort(tasks, :shell) do
      {:ok, sorted_tasks} -> text(conn, sorted_tasks)
      {:error, reason} -> conn |> put_status(400) |> json(%{"error" => reason})
    end
  end

  def shell(conn, params) do
    # work around when request come as urlencoded
    # happens when client omits JSON header
    # eg: $ curl -d @mytasks.json http://localhost:4000/... | bash
    tasks = Map.keys(params) |> Enum.at(0)
    shell(conn, Jason.decode!(tasks))
  end
end
