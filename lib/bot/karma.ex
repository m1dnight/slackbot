defmodule Bot.Karma do
  use GenServer
  @moduledoc """
  This handler manages so-called "karma". A person is given Karma by sending
  a message "person++". This will count as 1 point.
  """
  def start_link(client) do
    GenServer.start_link(__MODULE__, [client])
  end

  def init([client]) do
    SlackManager.add_handler client, self
    {:ok, client}
  end

  ########
  # Info #
  ########

  @doc """
  Consulting of karma happens by sending a message "karma subject"
  """
  def handle_info(message = %{type: "message", text: <<"karma "::utf8, rest::bitstring>>}, client) do
    IO.puts "#{message.text}"
    case String.split(rest) do
      []          -> :nil
      [subject|_] -> SlackManager.send(client, "Points for #{subject}: #{Brain.Karma.get(subject)}", message.channel)
    end
    {:noreply, client}
  end

  @doc """
  Scans every incoming message for karma increases or decreases. If so, handles
  them.
  """
  def handle_info(message = %{type: "message", text: text}, state) do
    ~r/(@(\S+[^:\s])\s|(\S+[^+:\s])|\(([^\(\)]+\W[^\(\)]+)\))(\+\+|--)(\s|$)/u
    |> Regex.scan(text)
    |> process_karma_list(message.channel, state)
    {:noreply, state}
  end

  @doc """
  A catch-all for infos.
  """
  def handle_info(_m, state) do
    {:noreply, state}
  end

  ###########
  # Private #
  ###########

  defp process_karma_list([], _channel, _client) do
  end

  @doc """
  Processes the list of Regex matches from above. Each entry is inserted into
  the big bot's brain.
  """
  defp process_karma_list([[_expression, _match, name, word, phrase, operator, _] | rest], channel, client) do
    subject = [name, word, phrase]
    |> Enum.filter(fn(x) -> String.length(x) > 1 end)
    |> List.first
    |> String.downcase
    function = if operator == "++", do: &Brain.Karma.increment/1, else: &Brain.Karma.decrement/1
    SlackManager.send(client, "Points for #{subject}: #{function.(subject)}", channel)
    process_karma_list(rest, channel, client)
  end
end
