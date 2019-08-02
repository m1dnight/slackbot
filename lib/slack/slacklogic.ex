defmodule Slackbot.ConnectionHandler do
  use Slack
  require Logger
  alias Slackbot.{PubSub, Parser, Message, DM}

  ##############################################################################
  ## Outgoing API

  def send_text(channel, text) do
    send(__MODULE__, {:message, channel, text})
  end

  def react_to(message, emoji) do
    ts = message.id
    token = Application.get_env(:slackbot, :secrets)[:slacktoken]

    payload = %{
      timestamp: ts,
      token: token,
      channel: message.channel_hash
    }

    Slack.Web.Reactions.add(emoji, payload)
  end

  ##############################################################################
  ## Incoming callbacks

  def handle_connect(slack, state) do
    PubSub.cast_all(:connected, slack.me.name)
    {:ok, state}
  end

  def handle_event(message = %{type: "message"}, slack, state) do
    message = Parser.parse_message(message, slack.token)

    case message do
      {:ok, message = %Message{}} ->
        PubSub.cast_all(:message, message)
        # If this message contains our name, it's also a mention.
        if String.contains?(message.text, slack.me.name) do
          PubSub.cast_all(:mention, message)
        end

      {:ok, message = %DM{}} ->
        PubSub.cast_all(:dm, message)

      {:error, e} ->
        Logger.error(inspect(e))
    end

    {:ok, state}
  end

  def handle_event(event = %{type: "reaction_added"}, slack, state) do
    reaction = Parser.parse_reaction(event, slack.token)
    PubSub.cast_all(:reaction, reaction)
    {:ok, state}
  end

  def handle_event(_event, _, state) do
    {:ok, state}
  end

  def handle_info({:message, channel, text}, slack, state) do
    IO.puts("Sending message")
    send_message(text, channel, slack)
    {:ok, state}
  end

  def handle_info(_m, _, state) do
    {:ok, state}
  end
end
