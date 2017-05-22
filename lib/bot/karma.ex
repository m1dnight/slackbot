defmodule Bot.Karma do
  use Plugin

  def on_message(<<"karma "::utf8, rest::bitstring>>, _channel, _from) do
    case String.split(rest) do
      []          -> 
        {:noreply}
      [subject|_] -> 
        karma = Slackbot.Karma.get_karma(subject)
        case karma do
          {:ok, u, karma} ->
            {:ok,"Points for #{subject}: #{karma}"}
          {:err, _} ->
            {:ok, "I don't know who or what you mean.."}
        end
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
    function = if operator == "++", do: &Slackbot.Karma.increment/1, else: &Slackbot.Karma.decrement/1
    function.(subject) # returns the new karma
    process_karma_list(rest, channel)
  end
end
