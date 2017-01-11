defmodule Bot.Markov do
  @moduledoc """
  This module is a simple interface to the Markov engine.
  """
  def start_link(client) do
    GenServer.start_link(__MODULE__, [client], name: __MODULE__)
  end

  def init([client]) do
    :random.seed(:os.timestamp)
    SlackManager.add_handler client, self
    {:ok, client}
  end

  ########
  # Info #
  ########

  @doc """
  If a message starts with Markov we have to generate a sentence.
  """
  def handle_info(message = %{type: "message", text: <<"markov "::utf8, start_word::bitstring>>}, client) do
    phrase = Brain.Markov.generate_phrase(start_word, 12 + :random.uniform(10))
    SlackManager.send client, phrase, message.channel
    {:noreply, client}
  end

  @doc """
  If we receive a regular message we process it for later sentence generation.
  """
  def handle_info(message = %{type: "message"}, client) do
    Brain.Markov.parse(message.text)
    {:noreply, client}
  end

  @doc """
  If we receive a message that mentions us we say something stupid.
  """
  def handle_info(message = %{type: "mention"}, client) do
    starting_phrase = ["I think", "I am", "I know", "I read", "you don't", "you should" ] |> Enum.shuffle |> hd
    SlackManager.send client, Brain.Markov.generate_phrase(starting_phrase, 15 + :random.uniform(10)), message.channel
    {:noreply, client}
  end

  # Catch-all for messages you don't care about
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
