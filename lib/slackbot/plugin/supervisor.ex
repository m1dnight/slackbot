defmodule Slackbot.Plugin.Supervisor do
  use Supervisor
  alias Slackbot.Plugin.{Echo}

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, [opts], [{:name, __MODULE__}])
  end

  def init(_opts) do
    children = [
      worker(Slackbot.Plugin, [{Echo, %{}}])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
