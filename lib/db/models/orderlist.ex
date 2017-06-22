defmodule Slackbot.OrderList do
  use Ecto.Schema

  import Ecto.Query
  import Ecto.Changeset

  alias Slackbot.OrderEntry
  alias Slackbot.OrderList
  alias Slackbot.Repo

  schema "order_lists" do
    field :week, :integer
    field :open, :boolean
    many_to_many :order_entries, Slackbot.OrderEntry, join_through: "order_entries_order_lists"
    timestamps
  end

  def changeset(orderlist, params \\ %{}) do
    orderlist
    |> Repo.preload(:order_entries)
    |> cast(params, [:week, :open])
    |> cast_assoc(:order_entries)
    |> validate_required([:week])
    |> unique_constraint(:week)
  end

  #################
  # Api Functions #
  #################

  def close_orderlist(orderlist) do
    orderlist_cs = changeset(orderlist, %{open: false})
    orderlist = Repo.update! orderlist_cs
    orderlist
  end

  

  def current_orders() do
    case existing_order?() do
      # No order at all
      false ->
        {:ok, []}
      # Order is closed for the week
      orderlist ->
        {:ok, orderlist.order_entries}
    end
  end

  def store_order(order_entry) do
    case {existing_order?(), open_order?()} do
      # No order at all
      {false, false} ->
        orderlist = start_new_order()
        add_order_to_current(orderlist, order_entry)
        {:ok, "updated"}
      # Order is closed for the week
      {x, false} ->
        {:error, "week closed"}
      # Order and open
      {orderlist, _open} ->
        add_order_to_current(orderlist, order_entry)
        {:ok, "updated"}
    end
  end

  #####################
  # Private Functions #
  #####################

  defp add_order_to_current(orderlist, orderentry) do
    orderlist_cs = changeset(orderlist)
    orderlist_cs = Ecto.Changeset.put_assoc(orderlist_cs, :order_entries, [orderentry])
    orderlist = Repo.update! orderlist_cs
    orderlist
  end

  defp start_new_order() do
    {_, weeknum, _} = Timex.now |> Timex.iso_triplet
    orderlist = %OrderList{week: weeknum, open: true}
    orderlist = Repo.insert! orderlist |> Repo.preload(:order_entries)
    orderlist
  end

  defp open_order?() do
    {_, weeknum, _} = Timex.now |> Timex.iso_triplet
    case Repo.one(from ol in OrderList, where: ol.open == true) |> Repo.preload(:order_entries) do
      nil -> false
      x   -> x
    end
  end

  defp existing_order?() do
    {_, weeknum, _} = Timex.now |> Timex.iso_triplet
    case Repo.one(from ol in OrderList, where: ol.week == ^weeknum) |> Repo.preload(:order_entries) do
      nil -> false
      x   -> x
    end
  end
end
