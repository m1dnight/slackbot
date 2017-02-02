defmodule Supervisor.Bot do
  use Supervisor

  def start_link(state) do
    Supervisor.start_link(__MODULE__, state)
  end

  def init(conn_pid) do
    children = [
      worker(Bot.Crash,   [conn_pid]),
      worker(Bot.Karma,   [conn_pid]),
      #worker(Bot.Debug,   [conn_pid]),
      worker(Bot.Resto,   [conn_pid]),
      worker(Bot.Cronjob, [conn_pid]),
      worker(Bot.Rss,     [conn_pid])
      ]
    supervise(children, strategy: :one_for_one)
  end
end
