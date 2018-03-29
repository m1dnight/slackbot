defmodule Slackbot.Connection.Supervisor do
  @moduledoc false
  use Supervisor

  def start_link(arg \\ []) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(_args) do
    require Logger
    Logger.debug("Starting #{__MODULE__}")

    # To not hit the ratelimiter of Slack, we wait 5 seconds before initializing the connection again.
    :timer.sleep(5000)

    slack_token = Application.fetch_env!(:slack, :token)

    children = [
      # The Slack connection and our callbacks.
      # This connection dies frequently, so we need to manage that it is restart every time.
      worker(Slack.Bot, [Slackbot.Connection.Slack, [], slack_token, %{}], restart: :permanent)
    ]

    opts = [strategy: :one_for_one]
    Supervisor.init(children, opts)
  end
end
