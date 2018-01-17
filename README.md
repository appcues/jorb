# Jorb

> I uh, I say you did a great _jorb_ out there

Jorb is a simple Elixir library for running publishing jobs to SQS to run them later

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
