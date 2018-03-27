defmodule Slackbot.Mixfile do
  use Mix.Project

  def project do
    [app: Slackbot,
     version: "0.0.1",
     elixir: "~> 1.5",
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger, :httpoison, :slack, :timex],
     mod: {Slackbot, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
     {:slack,         "~> 0.13.0"},
     {:poison,        "~> 3.1.0"},
     {:timex,         "~> 3.2.1"},
     {:feeder_ex,     "~> 1.1.0"},
     {:html_entities, "~> 0.4.0"},
     {:cronex,        git: "https://github.com/rhumbertgz/cronex.git"}
   ]
  end
end
