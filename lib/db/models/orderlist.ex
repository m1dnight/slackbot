defmodule Slackbot.OrderList do
  use Ecto.Schema

  schema "order_lists" do
    field :week, :string
    many_to_many :order_entries, Slackbot.OrderEntry, join_through: "order_entries_order_lists"
  end
end
