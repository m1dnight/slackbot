defmodule Slackbot.MixProject do
  use Mix.Project

  def project do
    [
      app: :slackbot,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Slackbot, []}
    ]
  end

  defp deps do
    [
      {:slack, "~> 0.19.0"},
      {:timex, "~> 3.5"},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false}
    ]
  end
end
