defmodule Jorb.Mixfile do
  use Mix.Project

  def project do
    [
      app: :jorb,
      version: "0.3.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Jorb",
      source_url: "https://github.com/appcues/jorb",
      homepage_url: "http://hexdocs.pm/jorb",
      description: "A simple job publisher/processor for Elixir",
      docs: [main: "Jorb", extras: ["README.md"]],
      files: ~w(mix.exs lib LICENSE.md README.md CHANGELOG.md),
      package: [
        maintainers: ["Andy LeClair"],
        licenses: ["MIT"],
        links: %{
          "GitHub" => "https://github.com/appcues/jorb"
        }
      ],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
      ],
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Jorb.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_aws, "~> 2.0"},
      {:ex_aws_sqs, "~> 2.0"},
      {:hackney, "~> 1.9"},
      {:sweet_xml, "~> 0.6"},
      {:poison, "~> 1.0"},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      {:excoveralls, "~> 0.11", only: :test}
    ]
  end
end
