defmodule BunnyWeb.TaskController do
  use BunnyWeb, :controller

  def sort(conn, %{"tasks" => tasks} = params) do
    case Bunny.sort(tasks) do
      {:ok, sorted_tasks} -> json(conn, sorted_tasks)
      {:error, reason} -> conn |> put_status(400) |> json(%{"error" => reason})
    end
  end
end
