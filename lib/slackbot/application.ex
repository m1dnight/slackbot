defmodule Slackbot.Application do
  @moduledoc false
  use Application
  use Supervisor
  require Logger

  def start(_type, _args) do
    Logger.debug("Starting #{__MODULE__}")

    children = [
      # The root supervisor.
      supervisor(Slackbot.Application.Supervisor, [])
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
