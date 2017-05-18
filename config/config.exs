# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :logger,
  handle_otp_reports: true,
  handle_sasl_reports: true

import_config "#{Mix.env}.secret.exs"
