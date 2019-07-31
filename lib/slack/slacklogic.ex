defmodule Slackbot.ConnectionHandler do
  use Slack
  require Logger
  alias Slackbot.{PubSub, Parser}

  ##############################################################################
  ## Outgoing API

  def send_text(channel, text) do
    send(__MODULE__, {:message, channel, text})
  end

  def react_to(message, emoji) do
    ts = message.id
    token = Application.get_env(:slackbot, :secrets)[:slacktoken]
    c = Parser.channel_readable_to_hash(message.channel, token)

    payload = %{
      timestamp: ts,
      token: token,
      channel: c
    }

    Slack.Web.Reactions.add(emoji, payload)
  end

  ##############################################################################
  ## Incoming callbacks

  def handle_connect(slack, state) do
    PubSub.cast_all(:connected, slack.me.name)
    IO.puts(inspect(self()))
    {:ok, state}
  end

  def handle_event(message = %{type: "message"}, slack, state) do
    message = Parser.parse_message(message, slack.token)
    PubSub.cast_all(:message, message)

    # If this message contains our name, it's also a mention.
    if String.contains?(message.text, slack.me.name) do
      PubSub.cast_all(:mention, message)
    end

    {:ok, state}
  end

  def handle_event(_, _, state), do: {:ok, state}

  def handle_info({:message, channel, text}, slack, state) do
    IO.puts("Sending message #{inspect({:message, text, channel})}")
    send_message(text, channel, slack)
    {:ok, state}
  end

  def handle_info(m, _, state) do
    IO.puts(m)
    {:ok, state}
  end
end
