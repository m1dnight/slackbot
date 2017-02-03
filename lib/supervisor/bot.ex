defmodule Supervisor.Bot do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, [opts])
  end

  def init(opts) do
    children = [
      worker(Bot.Crash,   [opts]),
      worker(Bot.Karma,   [opts])
      #worker(Bot.Debug,  []),
      #worker(Bot.Resto,   []),
      #worker(Bot.Cronjob, []),
      #worker(Bot.Rss,     [])
      ]
    supervise(children, strategy: :one_for_one)
  end
end
