defmodule Slackbot.Application do
  @moduledoc false
  use Application
  import Supervisor.Spec

  def start(_type, _args) do
    slack_token = Application.fetch_env!(:slack, :token)

    children = [
      # The Slack connection and our callbacks.
      worker(Slack.Bot, [Slackbot.Connection.Slack, [], slack_token, %{}]),
      # The Parser will take in all messages and turn them into workable data.
      worker(Slackbot.Parser, [slack_token]),
      # Finally, we start the plugins.
      supervisor(Slackbot.Plugin.Supervisor, [])
    ]

    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end
end
