# Bunny

HTTP job processing service.

A job is a collection of tasks, where each task has a name and a shell command.
Tasks may depend on other tasks and require that those are executed beforehand.
The service takes care of sorting the tasks to create a proper execution order.

# How it works

Topologically sorts the nodes, and detects cycles using depth-first-search algorithm.

The core is in lib/bunny, separate from the web interface.

Error messages are meaningful and precise to catch and report many edges cases:

  - self reference tasks/nodes
  - cycles / loop in tasks: e.g: A -> B -> A -> B, A -> B -> C -> B
  - missing / dead references
    - detect all cycles and include them in the error message.

Uses ETS tables to collect found cycles and track the state of the search.

See [Bunny.Graph](./lib/bunny/graph.ex)

## Examples

### Sort and return JSON

``` shell
$ curl -d @test/fixtures/many_valid.json http://localhost:4000
[
  {
    "command": "touch /tmp/file1",
    "name": "task-1"
  },
  {
    "command": "echo 'Hello World!' > /tmp/file1",
    "name": "task-3"
  },
  {
    "command": "cat /tmp/file1",
    "name": "task-2"
  },
  {
    "command": "rm /tmp/file1",
    "name": "task-4"
  }
]
```

### Sort task and serialize to shell script
``` shell
$ curl -d @test/fixtures/many_valid.json http://localhost:4000/sh
#!/usr/bin/env bash
touch /tmp/file1
echo 'Hello World!' > /tmp/file1
cat /tmp/file1
rm /tmp/file1
```

### Detects a cyclic errors

``` shell
$ curl -d @test/fixtures/cyclic_tasks.json http://localhost:4000
{
    "message": "circular depedencies found",
    "type": "invalid_request_error",
    "details": {
        "task-2": [
            "task-3"
        ],
        "task-3": [
            "task-4"
        ],
        "task-4": [
            "task-2",
            "task-3"
        ],
        "task-5": [
            "task-5"
        ]
    }
}
```

## How to run

### Run with docker

``` shell
$ docker-compose up
```

You can also directly build the image and run the container

### Generate and run production release

Use `./run.sh` to build the production release. Starts in console mode

``` shell
$ ./run.sh
==> Getting deps
...
==> Generating release
...
==> Starting server
Erlang/OTP 20 [erts-9.1.2] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

01:05:27.789 [info] Running BunnyWeb.Endpoint with cowboy 2.6.3 at :::4000 (http)
01:05:27.790 [info] Access BunnyWeb.Endpoint at http://localhost:4000
Interactive Elixir (1.8.0) - press Ctrl+C to exit (type h() ENTER for help)
iex(bunny@127.0.0.1)>
```

### setup locally

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Also see

  * [Wikipedia page on topological sorting](https://en.wikipedia.org/wiki/Topological_sorting)
  * [Article on topologicla sorting with Python](https://algocoding.wordpress.com/2015/04/05/topological-sorting-python/)
  * [Erlang digraph](http://erlang.org/doc/man/digraph.html)
