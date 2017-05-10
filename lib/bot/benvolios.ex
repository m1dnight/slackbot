defmodule Bot.Benvolios do
  use Plugin

  def on_message(<<"order "::utf8, rest::bitstring>>, _channel, _sender) do
    case String.split(rest) do
      []          -> {:ok, }
      [subject|_] -> {:ok,"Points for #{subject}: #{Brain.Karma.get(subject)}"}
    end
  end

  def on_message(text, channel) do
    {:noreply}
  end
  ###########
  # Private #
  ###########

  defp parse_order(msg) do


  end

end
