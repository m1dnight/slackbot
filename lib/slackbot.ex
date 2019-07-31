defmodule Slackbot do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    slack_token = Application.get_env(:slackbot, :secrets)[:slacktoken]

    children = [
      worker(Registry, [[keys: :duplicate, name: Slackbot.PubSub, partitions: System.schedulers_online()]]),
      worker(Slackbot.PluginInstance, [Slackbot.Plugin.Echo, %{}]),
      worker(Slack.Bot, [Slackbot.ConnectionHandler, [], slack_token, %{:name => Slackbot.ConnectionHandler}], restart: :permanent)
    ]

    opts = [strategy: :one_for_one, name: Slackbot.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
