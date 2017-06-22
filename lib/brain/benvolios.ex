defmodule Brain.Benvolios do
  require Logger

  def save_order(orderer, order) do
    order = Slackbot.OrderEntry.new_order(orderer, order)
    Slackbot.OrderList.store_order(order)
  end

  def forget_order(orderer) do
    Slackbot.OrderList.delete_current_order_by(orderer)
  end

  def get_order(orderer) do
    order = Slackbot.OrderList.current_order_by(orderer)
    case order do
      nil   -> nil
      order -> order.value
    end
  end

  def list() do
    Slackbot.OrderList.current_orders()
    |> Enum.map(fn(e) -> %{orderer: e.user, value: e.value} end)
  end

  def clear() do
    Slackbot.OrderList.close_orderlist()
  end

end
