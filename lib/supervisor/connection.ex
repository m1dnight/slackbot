defmodule Supervisor.Connection do
  use Supervisor

  def start_link(state \\ []) do
    Supervisor.start_link(__MODULE__, state, [{:name, __MODULE__}])
  end

  def init(_state) do
    slack_token = Application.fetch_env!(:slack, :token)

    children = [
      # The actual Slack connection.
      worker(Slack.Bot, [SlackLogic, [], slack_token, %{:name => Slack.Bot}]),
      # The interface process to the Slack connection.
      worker(SlackManager, [Slack.Bot, slack_token]),
      # The bot plugins.
      worker(Supervisor.Bot, [[]])
    ]

    supervise(children, strategy: :one_for_all)
  end
end
