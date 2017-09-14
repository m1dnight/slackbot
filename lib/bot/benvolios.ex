defmodule Bot.Benvolios do
  use Plugin

  @boss    Application.fetch_env!(:slack, :benvolios_owner)
  @channel Application.fetch_env!(:slack, :benvolios_channel)

  # The message "order x y z" is used to order a sandwich. "x y z" will be
  # the order.
  def on_message(<<"order "::utf8, rest::bitstring>>, @channel, sender) do
    case String.split(rest) do
      []          -> {:noreply}
      [_subject|_] -> :ok = handle_order(sender, rest)
                     {:ok,"#{sender} has ordered #{rest}"}
    end
  end

  # The message "forget order" will forget the order for the sender of that
  # mesasge.
  def on_message(<<"forget order"::utf8, _rest::bitstring>>, @channel, sender) do
    Brain.Benvolios.forget_order(sender)
    {:noreply}
  end

  # "order?" will print out the outstanding order of the sender, if any.
  def on_message(<<"order?"::utf8, _::bitstring>>, @channel, sender) do
    {:ok, order} = Brain.Benvolios.get_order(sender)
    case order do
      :nil  -> {:ok, "No order registered for #{sender}"}
      order -> {:ok, "You have ordered \"#{order}\""}
    end
  end

  # Prints out all the outstanding orders.
  # Restricted to admins only.
  def on_message(<<"list"::utf8, _::bitstring>>, @channel, @boss) do
    {:ok, orders} = Brain.Benvolios.list()

    case orders do
      :nil   -> {:ok, "No orders yet.."}
      orders -> if orders == %{} do
                  {:ok, "No orders yet.."}
                else
                  res = orders
                  |> Enum.map(fn {k,v} -> "#{k} : #{v}" end)
                  |> Enum.join("\n")
                  {:ok, "```#{res}```"}
                end
    end
  end

  # Clears out all the outstanding orders.
  # Restricted to admins only.
  def on_message(<<"clear orders"::utf8, _::bitstring>>, @channel, @boss) do
    :ok = Brain.Benvolios.clear()
    {:noreply}
  end

  # Prints out help message.
  def on_message(<<"help"::utf8>>, @channel, _sender) do
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
