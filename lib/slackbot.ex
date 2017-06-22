defmodule Slackbot do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Define workers and child supervisors to be supervised
      # - The Slack connection
      supervisor(Supervisor.Connection, []),
      # - The data of the bot (karma etc)
      supervisor(Supervisor.Brain, []),
      # Database
      supervisor(Slackbot.Repo, [])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Slackbot.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

# alias Slackbot.Repo ; alias Slackbot.OrderEntry ; alias Slackbot.Repo
defmodule Test do
  alias Slackbot.OrderEntry
  alias Slackbot.OrderList
  alias Slackbot.Repo

  import Ecto.Query

  def put_testdata() do
    order     = %OrderEntry{value: "een broodje"}
    orderlist = %OrderList{week: 25}

    order = Repo.insert! order |> Repo.preload(:order_lists)
    orderlist = Repo.insert! orderlist |> Repo.preload(:order_entries)
  end
end
