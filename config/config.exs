use Mix.Config

config :slackbot, :secrets,
  slacktoken: System.get_env("SLACKTOKEN"),
  datafile: System.get_env("DATAFILE")
