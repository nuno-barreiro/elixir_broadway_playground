defmodule ElixirBroadwayPlayground.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_broadway_playground,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      config_path: "./config/config.exs",
      lockfile: "./mix.lock",
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {ElixirBroadwayPlayground.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:broadway, "~> 1.0"},
      {:broadway_sqs, "~> 0.7"},
      {:bypass, "~> 2.1"},
      {:ex_aws, "~> 2.4"},
      {:ex_aws_sqs, "~> 3.4"},
      {:httpoison, "~> 1.8"},
      {:jason, "~> 1.4.0"},
      {:mimic, "~> 1.7"}
    ]
  end
end
