defmodule Slackbot.Application.Supervisor do
  @moduledoc false
  use Supervisor
  require Logger

  def start_link(arg \\ []) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(_args) do
    Logger.debug "Starting #{__MODULE__}"

    slack_token = Application.fetch_env!(:slack, :token)
    children = [
      # The Slack connection and our callbacks.
      supervisor(Slackbot.Connection.Supervisor, []),

      # The Parser will take in all messages and turn them into workable data.
      worker(Slackbot.Parser, [slack_token]),

      # Finally, we start the plugins.
      supervisor(Slackbot.Plugin.Supervisor, [])
    ]

    opts = [strategy: :one_for_one]
    Supervisor.init(children, opts)
  end
end
