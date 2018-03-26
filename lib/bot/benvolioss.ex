defmodule Plugin.Benvolios do
  use Slackbot.Plugin
  require Logger


  @boss Application.fetch_env!(:slack, :benvolios_owner)
  @channel Application.fetch_env!(:slack, :benvolios_channel)

  def hook_pre(msg = %{:text => t}) do
    # Entire message to lowercase.
    text = String.downcase(t)

    # Compute all permutations of the first word in the string.
    # if it matches "order", turn it into "order".
    words = String.split(text)
    perms = words |> hd |> String.to_charlist() |> shuffle() |> Enum.map(&String.Chars.to_string/1)
    match? = Enum.any?(perms, &(String.equivalent?("order", &1)))

    text = if match? do
      (["order"] ++ (words |> tl)) |> Enum.join(" ")
    else
      text
    end

    # # Lowercase all the message, for easy pattern matching.
    # fmt =
    #   if Map.has_key?(msg, :text) do
    #     lower = String.downcase(msg.text)

    #     # If the first word is a permutation of "order", change it to "order".
    #     words = String.split(lower)
    #     matches? = words|> hd |> String.to_charlist() |> shuffle() |> Enum.map(&String.Chars.to_string/1) |> Enum.any?(fn w -> String.equivalent?(w, "order") end)

    #     if matches? do
    #       text = ["order"] ++ tl(words) |> Enum.join()
    #       %{msg | text: text}
    #     else
    #       %{msg | text: String.downcase(msg.text)}
    #     end
    #   else
    #     msg
    #   end

    {:ok, %{msg | text: text}}
  end

  # The message "order x y z" is used to order a sandwich. "x y z" will be
  # the order.
  def on_message(<<"order "::utf8, rest::bitstring>>, @channel, sender) do
    case String.split(rest) do
      [] ->
        {:noreply}

      [_subject | _] ->
        :ok = handle_order(sender, rest)
        # {:ok, "#{sender} has ordered #{rest}"}
        {:react, "white_check_mark"}
    end
  end

  # The message "forget order" will forget the order for the sender of that
  # mesasge.
  def on_message(<<"forget order"::utf8, _rest::bitstring>>, @channel, sender) do
    Brain.Benvolios.forget_order(sender)
    {:react, "white_check_mark"}
  end

  # "order?" will print out the outstanding order of the sender, if any.
  def on_message(<<"order?"::utf8, _::bitstring>>, @channel, sender) do
    {:ok, order} = Brain.Benvolios.get_order(sender)

    case order do
      nil -> {:ok, "No order registered for #{sender}"}
      order -> {:ok, "You have ordered \"#{order}\""}
    end
  end

  # Prints out all the outstanding orders.
  # Restricted to admins only.
  def on_message(<<"list"::utf8, _::bitstring>>, @channel, @boss) do
    {:ok, orders} = Brain.Benvolios.list()

    case orders do
      nil ->
        {:ok, "No orders yet.."}

      orders ->
        if orders == %{} do
          {:ok, "No orders yet.."}
        else
          res =
            orders
            |> Enum.map(fn {k, v} -> "#{k} : #{v}" end)
            |> Enum.join("\n")

          {:ok, "```#{res}```"}
        end
    end
  end

  # Clears out all the outstanding orders.
  # Restricted to admins only.
  def on_message(<<"clear orders"::utf8, _::bitstring>>, @channel, @boss) do
    :ok = Brain.Benvolios.clear()
    {:react, "white_check_mark"}
  end

  # Prints out help message.
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

  # https://stackoverflow.com/questions/33756396/how-can-i-get-permutations-of-a-list
  def shuffle(list), do: shuffle(list, length(list))
  def shuffle([], _), do: [[]]
  def shuffle(_, 0), do: [[]]

  def shuffle(list, i) do
    for x <- list,
        y <- shuffle(list, i - 1),
        do: [x | y]
  end
end
