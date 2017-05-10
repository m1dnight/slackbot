defmodule Bot.Benvolios do
  use Plugin

  def on_message(<<"order "::utf8, rest::bitstring>>, _channel, sender) do
    case String.split(rest) do
      []          -> {:ok, }
      [subject|_] -> {:ok,"#{sender} has ordered #{rest}"}
    end
  end

  def on_message(text, channel, sender) do
    {:noreply}
  end
  ###########
  # Private #
  ###########

  defp parse_order(msg) do


  end

end
