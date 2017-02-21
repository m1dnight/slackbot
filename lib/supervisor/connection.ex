defmodule Supervisor.Connection do
  use Supervisor

  def start_link(state \\ []) do
    Supervisor.start_link(__MODULE__, state, [{:name, __MODULE__}])
  end

  def init(_state) do
    slack_token = read_slack_config()
    children =
      [
        # The actual Slack connection.
        worker(Slack.Bot, [SlackLogic, [], slack_token, %{:name => SlackConnection}]),
        # The interface process to the Slack connection.
        worker(SlackManager, [SlackConnection, slack_token]),
        # The bot plugins.
        worker(Supervisor.Bot, [[]])
      ]
      supervise(children, strategy: :one_for_all)
    end

    # Reads the configuration from a config file.
    defp read_slack_config(filename \\ "ohaibot_slack.conf") do
      if File.exists?(filename) do
        {:ok, [token]} = :file.consult(filename)
        token
      else
        nil
      end
    end
  end
