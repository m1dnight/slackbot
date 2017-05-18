defmodule Supervisor.Bot do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, [opts], [{:name, __MODULE__}])
  end

  def init(opts) do
    children = [
      worker(Bot.Karma,       [opts]),
      worker(Bot.ChuckNorris, [opts]),
      worker(Bot.Resto,       [opts]),
      worker(Bot.Cronjob,     [opts]),
      worker(Bot.Rss,         [opts]),
      worker(Bot.Benvolios,   [opts]),
      worker(Bot.Misc,        [opts])
      ]
    supervise(children, strategy: :one_for_one)
  end
end
