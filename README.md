# Jorb

[![Coach Z](http://www.hrwiki.org/w/images/3/3e/Old_homestar_jorb.PNG)](https://www.youtube.com/watch?v=8C4ayBHTES0)
> I uh, I say you did a great _jorb_ out there

Jorb is a simple Elixir library for publishing jobs to SQS and running them later

## Example

First, define a job module:

  ```elixir
  defmodule Demo.Jobs.TestJob do
     use Jorb.Job

     def queue_name, do: "test"
     def perform(name) do
       IO.puts("Hello #{name}")
     end
  end
  ```

Then, queue jobs to be performed later with `perform_async`

```elixir
  Demo.Jobs.TestJob.perform_async("Andy")
```

## Configuring

Jorb uses [ExAws](https://github.com/ex-aws/ex_aws) under the hood to push/pull from SQS,
so configure your AWS keys like you would for ExAws.

There are a few config options that need to be set for Jorb to run correctly. Here is the default config:

```elixir
config :jorb,
  application: :jorb,
  fetching_processes: 4,
  fetching_timer: 1000,
  namespace: "Elixir.Jorb.Jobs."
```

* application: this is the name of your app (the same one from `mix.exs`)
* fetching_processes: this is how many processes are pulling from SQS simultaneously PER QUEUE
* fetching_timer: this is how often the fetchers poll SQS
* namespace: this is the namespace that your jobs (things `use`ing `Jorb.Job`) live in.

It is important that your jobs share a namespace, so that `Jorb` can automatically find out the
names of the queues that need to be pulled from.


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `jorb` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:jorb, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/jorb](https://hexdocs.pm/jorb).

## Authorship & License

Jorb is copyright 2018 Appcues, Inc.

Jorb is licensed under the MIT license

_A Jorb Well Done_ is by The Brothers Chaps
