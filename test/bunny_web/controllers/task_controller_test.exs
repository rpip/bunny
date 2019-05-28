defmodule BunnyWeb.TaskControllerTest do
  use BunnyWeb.ConnCase

  # test bash script serialization
  # test 400 error circular deps
  # test JSON sorting
  defp parse_file!(filename) do
    Path.join("test/fixtures", filename)
    |> File.read!()
    |> Jason.decode!()
  end

  test "http sort valid tasks", %{conn: conn} do
    request = parse_file!("many_valid.json")

    expected = [
      %{"command" => "touch /tmp/file1", "name" => "task-1"},
      %{"command" => "echo 'Hello World!' > /tmp/file1", "name" => "task-3"},
      %{"command" => "cat /tmp/file1", "name" => "task-2"},
      %{"command" => "rm /tmp/file1", "name" => "task-4"}
    ]

    response =
      conn
      |> post("/", request)
      |> json_response(200)

    assert response == expected
  end

  test "http shell script serialization", %{conn: conn} do
    request = parse_file!("many_valid.json")

    expected = """
    #!/usr/bin/env bash
    touch /tmp/file1
    echo 'Hello World!' > /tmp/file1
    cat /tmp/file1\nrm /tmp/file1
    """

    response =
      conn
      |> post("/sh", request)
      |> text_response(200)

    assert response == String.trim(expected)
  end

  test "http cycles in tasks", %{conn: conn} do
    request = parse_file!("cyclic_tasks.json")

    expected = %{
      "type" => "invalid_request_error",
      "message" => "circular depedencies found",
      "details" => %{
        "task-1" => [],
        "task-2" => [
          "task-3"
        ],
        "task-3" => [
          "task-4"
        ],
        "task-4" => [
          "task-2",
          "task-3"
        ],
        "task-5" => [
          "task-5"
        ]
      }
    }

    response =
      conn
      |> post("/", request)
      |> json_response(400)

    assert response == expected
  end
end
