# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :logger,
  handle_otp_reports: false,
  handle_sasl_reports: false

config :slackbot, Slackbot.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "slackbot_dev",
  username: "slackbot_dev",
  password: "slackbot_dev",
  hostname: "localhost"

config :slackbot, ecto_repos: [Slackbot.Repo]

import_config "#{Mix.env}.secret.exs"
