defmodule Bot.Benvolios do
  use Plugin

  @boss Application.fetch_env!(:slack, :benvolios_owner)

  @channel Application.fetch_env!(:slack, :benvolios_channel)

  def on_message(<<cmd::utf8, " "::utf8, rest::bitstring>>, @channel, sender) do
    IO.inspect cmd
    cased = String.downcase(cmd)

    case cased do
      "order " -> case String.split(rest) do
                    []          -> {:noreply}
                    [_subject|_] -> :ok = handle_order(sender, rest)
                                  {:ok,"#{sender} has ordered #{rest}"}
                  end
      _ -> {:noreply}
  end
end
  def on_message(<<"forget order"::utf8, _rest::bitstring>>, @channel, sender) do
    Brain.Benvolios.forget_order(sender)
    {:noreply}
  end

  def on_message(<<"order?"::utf8, _::bitstring>>, @channel, sender) do
    {:ok, order} = Brain.Benvolios.get_order(sender)
    case order do
      :nil  -> {:ok, "No order registered for #{sender}"}
      order -> {:ok, "You have ordered #{order}"}
    end
  end

  def on_message(<<"list"::utf8, _::bitstring>>, @channel, @boss) do
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

  def on_message(<<"clear orders"::utf8, _::bitstring>>, @channel, @boss) do
    :ok = Brain.Benvolios.clear()
    {:noreply}
  end

  def on_message(<<"help"::utf8>>, _channel, _sender) do
    res = """
    ```
    order        : Order something.
                   Example: "order legumax white bread".
    forget order : Forgets your current order.
                   Example: "forget order"
    order?       : Shows what you have ordered at this point.
                   Example: "order?"
    list         : Lists the current orders.
                   Example: "list"
    clear orders : Forgets all the orders.
                   Example: "clear orders"
    ```
    Ps: Only the admin can execute `list` and `clear orders`
    
    """
    {:ok, res}
  end

  def on_message(_text, _hannel, _sender) do
    {:noreply}
  end

  ###########
  # Private #
  ###########

  defp handle_order(orderer, order) do
    Brain.Benvolios.save_order(orderer, order)
  end

end
