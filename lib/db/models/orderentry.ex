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
    many_to_many :order_lists, Slackbot.OrderList, join_through: "order_entries_order_lists"
    timestamps
  end

  def changeset(orderentry, params \\ %{}) do
    orderentry
    |> Repo.preload(:order_lists)
    |> cast(params, [:value])
    |> cast_assoc(:order_lists)
  end

  #################
  # API Functions #
  #################

  def new_order(value) do
    order = %OrderEntry{value: value}
    order = Repo.insert! order |> Repo.preload(:order_lists)
    order
  end
end
