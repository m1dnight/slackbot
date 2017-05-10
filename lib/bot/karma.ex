defmodule Bot.Karma do
  use Plugin

  def on_message(<<"karma "::utf8, rest::bitstring>>, _channel, _from) do
    case String.split(rest) do
      []          -> {:noreply}
      [subject|_] -> {:ok,"Points for #{subject}: #{Brain.Karma.get(subject)}"}
    end
  end

  def on_message(text, channel, _from) do
    ~r/(@(\S+[^:\s])\s|(\S+[^+:\s])|\(([^\(\)]+\W[^\(\)]+)\))(\+\+|--)(\s|$)/u
    |> Regex.scan(text)
    |> process_karma_list(channel)
    {:noreply}
  end

  ###########
  # Private #
  ###########

  # Processes the list of Regex matches from above. Each entry is inserted into
  # the big bot's brain.
  defp process_karma_list([], _channel) do
    :nil
  end

  defp process_karma_list([[_expression, _match, name, word, phrase, operator, _] | rest], channel) do
    subject = [name, word, phrase]
    |> Enum.filter(fn(x) -> String.length(x) > 1 end)
    |> List.first
    |> String.downcase
    function = if operator == "++", do: &Brain.Karma.increment/1, else: &Brain.Karma.decrement/1
    function.(subject) # returns the new karma
    process_karma_list(rest, channel)
  end
end
