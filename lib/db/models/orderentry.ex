defmodule Slackbot.OrderEntry do
  use Ecto.Schema

  schema "order_entries" do
    field :value, :string
    many_to_many :order_lists, Slackbot.OrderList, join_through: "order_entries_order_lists"
  end
end
