# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :logger,
  handle_otp_reports: false,
  handle_sasl_reports: false

import_config "#{Mix.env}.secret.exs"
