defmodule Slackbot.OrderEntry do
  use Ecto.Schema

  import Ecto.Query
  import Ecto.Changeset

  alias Slackbot.OrderEntry
  alias Slackbot.OrderList
  alias Slackbot.Repo

  schema "order_entries" do
    field :value, :string
    field :user, :string
    many_to_many :order_lists,
                 Slackbot.OrderList,
                 join_through: "order_entries_order_lists",
                 on_delete:  :delete_all
    timestamps
  end

  def changeset(orderentry, params \\ %{}) do
    orderentry
    |> Repo.preload(:order_lists)
    |> cast(params, [:value, :user])
    |> cast_assoc(:order_lists)
  end

  #################
  # API Functions #
  #################

  def new_order(username, value) do
    order = %OrderEntry{value: value, user: username}
    order = Repo.insert! order |> Repo.preload(:order_lists)
    order
  end
end
