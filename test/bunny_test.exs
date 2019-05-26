defmodule BunnyTest do
  use ExUnit.Case

  defp parse_file!(fpath) do
    File.read!(fpath)
    |> Jason.decode!()
    |> Map.get("tasks")
  end

  test "cyclic tasks" do
    tasks = parse_file!("test/fixtures/cyclic_tasks.json")

    cyclic_tasks = [
      ["task-3", "task-4", "task-3"],
      ["task-5", "task-5"],
      ["task-2", "task-3", "task-4", "task-2"],
      ["task-4", "task-3", "task-4"]
    ]

    assert {:error, {:cyclic, cyclic_tasks}} == Bunny.sort(tasks)
  end

  test "invalid task schema" do
    tasks = parse_file!("test/fixtures/missing_command_name.json")

    assert_raise(Bunny.InvalidTaskError, fn ->
      Bunny.sort(tasks)
    end)
  end

  test "missing task dependency" do
    tasks = parse_file!("test/fixtures/missing_task.json")

    missing_deps = ["task-3"]
    expected = {:error, {:dead_path, [{"task-2", missing_deps}, {"task-4", missing_deps}]}}

    assert expected == Bunny.sort(tasks)
  end

  test "one task valid" do
    tasks = parse_file!("test/fixtures/one_valid.json")
    sorted_tasks = [%{"command" => "touch /tmp/file1", "name" => "task-1"}]

    assert {:ok, sorted_tasks} == Bunny.sort(tasks)
  end

  test "many tasks valid" do
    sorted_tasks = [
      %{"command" => "touch /tmp/file1", "name" => "task-1"},
      %{
        "command" => "echo 'Hello World!' > /tmp/file1",
        "name" => "task-3",
        "requires" => ["task-1"]
      },
      %{
        "command" => "cat /tmp/file1",
        "name" => "task-2",
        "requires" => ["task-3"]
      },
      %{
        "command" => "rm /tmp/file1",
        "name" => "task-4",
        "requires" => ["task-2", "task-3"]
      }
    ]

    tasks = parse_file!("test/fixtures/many_valid.json")
    assert {:ok, sorted_tasks} == Bunny.sort(tasks)
  end

  test "pretty print json" do
    tasks = parse_file!("test/fixtures/many_valid.json")

    expected = [
      %{"command" => "touch /tmp/file1", "name" => "task-1"},
      %{"command" => "echo 'Hello World!' > /tmp/file1", "name" => "task-3"},
      %{"command" => "cat /tmp/file1", "name" => "task-2"},
      %{"command" => "rm /tmp/file1", "name" => "task-4"}
    ]

    assert {:ok, expected} == Bunny.sort(tasks, :json)
  end

  test "pretty print bash" do
    tasks = parse_file!("test/fixtures/many_valid.json")

    expected = """
    #!/usr/bin/env bash
    touch /tmp/file1
    echo 'Hello World!' > /tmp/file1
    cat /tmp/file1\nrm /tmp/file1
    """

    assert {:ok, String.trim(expected)} == Bunny.sort(tasks, :bash)
  end
end
