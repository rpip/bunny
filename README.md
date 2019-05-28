# Bunny

HTTP job processing service.

Sorts the tasks to create a proper execution order

# How it works

Topologically sorts the nodes, and detects cycles using depth-first-search algorithm.

See Bunny.Graph.topsort/1

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
[master][yao@moonboots:~/dev/bunny]
```

## Deployment

### Run with docker

``` shell
$ docker-compose up
```

You can also directly build the image and run the container

### Deploy locally

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Also see

  * [Wikipedia page on topological sorting](https://en.wikipedia.org/wiki/Topological_sorting)
  * [Article on topologicla sorting with Python](https://algocoding.wordpress.com/2015/04/05/topological-sorting-python/)
  * [Erlang digraph](http://erlang.org/doc/man/digraph.html)
