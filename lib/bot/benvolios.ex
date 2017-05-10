defmodule Bot.Benvolios do
  use Plugin

  @boss slack_token = Application.fetch_env!(:slack, :benvolios_owner)

  def on_message(<<"order "::utf8, rest::bitstring>>, _channel, sender) do
    case String.split(rest) do
      []          -> {:noreply}
      [subject|_] -> :ok = handle_order(sender, rest)
                     {:ok,"#{sender} has ordered #{rest}"}
    end
  end

  def on_message(<<"order?"::utf8, _::bitstring>>, _channel, sender) do
    {:ok, order} = Brain.Benvolios.get_order(sender)
    case order do
      :nil  -> {:ok, "No order registered for #{sender}"}
      order -> {:ok, "You have ordered #{order}"}
    end
  end

  def on_message(<<"list"::utf8, _::bitstring>>, _channel, sender) when sender == @boss do
    {:ok, orders} = Brain.Benvolios.list()
    IO.inspect orders

    case orders do
      :nil   -> {:ok, "No orders yet.."}
      orders -> if orders == %{} do
                  {:ok, "No orders yet.."}
                else
                  res = orders
                  |> Enum.map(fn {k,v} -> "#{k} : #{v}" end)
                  |> Enum.join("\n")
                  {:ok, res}
                end
    end
  end

  def on_message(<<"clear orders"::utf8, _::bitstring>>, _channel, sender) when sender == @boss do
    :ok = Brain.Benvolios.clear()
    {:noreply}
  end

  def on_message(text, channel, sender) do
    {:noreply}
  end
  ###########
  # Private #
  ###########

  defp handle_order(orderer, order) do
    Brain.Benvolios.save_order(orderer, order)
  end

end
