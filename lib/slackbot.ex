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

defmodule Test do
  alias Slackbot.OrderEntry
  alias Slackbot.OrderList
  alias Slackbot.Repo

  def test() do
    order     = %OrderEntry{value: "een broodje"}
    orderlist = %OrderList{week: "23"}

    IO.inspect order
    IO.inspect orderlist

    order = Repo.insert! order |> Repo.preload(:order_lists)
    orderlist = Repo.insert! orderlist |> Repo.preload(:order_entries)

    IO.inspect order
    IO.inspect orderlist

    orderlist_cs = Ecto.Changeset.change(orderlist)

    orderlist_added = Ecto.Changeset.put_assoc(orderlist_cs, :order_entries, [order])

  end
end
