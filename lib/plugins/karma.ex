defmodule Slackbot.Plugin.Karma do
  @behaviour Slackbot.Plugin
  require Logger

  @impl Slackbot.Plugin
  def handle_reaction(reaction, state) do
    # If a message gets a red card, we decrease karma by one.
    state =
      case reaction.emoji do
        "-1" -> Map.update(state, reaction.message.from, 1, fn k -> k - 1 end)
        "+1" -> Map.update(state, reaction.message.from, 1, fn k -> k + 1 end)
        _ -> state
      end

    {:ok, state}
  end

  @impl Slackbot.Plugin
  def handle_message(m = %Slackbot.Message{text: <<"karma?"::utf8>>}, state) do
    karma = Map.get(state, m.from, 0)

    {:message, m.channel, "#{m.from}: #{karma}", state}
  end

  @impl Slackbot.Plugin
  def handle_message(m = %Slackbot.Message{text: <<"karma "::utf8, thing::bitstring>>}, state) do
    karma = Map.get(state, thing, 0)

    {:message, m.channel, "#{thing}: #{karma}", state}
  end

  @impl Slackbot.Plugin
  def handle_message(message, state) do
    state_ =
      ~r/(@(\S+[^:\s])\s|(\S+[^+:\s])|\(([^\(\)]+\W[^\(\)]+)\))(\+\+|--)(\s|$)/u
      |> Regex.scan(message.text)
      |> Enum.reduce(state, fn [_, name, _, _, _, action, _], state ->
        case action do
          "++" ->
            Map.update(state, name, 1, fn k -> k + 1 end)

          "--" ->
            Map.update(state, name, -1, fn k -> k - 1 end)
        end
      end)

    {:ok, state_}
  end

  @impl Slackbot.Plugin
  def handle_mention(_message, state) do
    {:ok, state}
  end

  @impl Slackbot.Plugin
  def handle_connected(_nickname, state) do
    {:ok, state}
  end
end
