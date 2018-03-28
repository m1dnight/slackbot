defmodule Slackbot.Connection.Slack do
  @moduledoc """
  Contains all the callbacks for the Slack dependency. 

  Delegates all the message handling down to the Parser.
  """
  use Slack
  require Logger
  alias Slackbot.Connection.Pubsub

  #######
  # API #
  #######

  @doc """
  Sends a message over Slack to the given channel.
  """
  def send_message(text, channel) do
    send(__MODULE__, {:send_msg, text, channel})
  end

  @doc """
  Reacts with the given emoji to the given message.
  """
  def react(m, emoji) do
    send(__MODULE__, {:react, m, emoji})
  end

  @doc """
  Reacts with the given emoji to the given message.
  """
  def direct_message(user, text) do
    send(__MODULE__, {:send_msg, text, user})
  end

  ############
  # Handlers #
  ############

  defp connect_handler(_slack, _state) do
    Logger.info("#{__MODULE__} : Connect!", ansi_color: :magenta)
  end

  defp event_handler(_slack, _state, event) do
    Logger.debug("#{__MODULE__} : --> #{inspect(event)}", ansi_color: :magenta)

    {type, parsed} = Slackbot.Parser.parse_event(event)

    case type do
      :dm ->
        Pubsub.broadcast(:dms, {:dm, parsed})

      :group ->
        Pubsub.broadcast(:messages, {:message, parsed})

      :channel ->
        Pubsub.broadcast(:messages, {:message, parsed})

      _ ->
        Pubsub.broadcast(:events, {:event, parsed})
    end
  end

  defp close_handler(_slack, _state, reason) do
    Logger.info("#{__MODULE__} : Disconnect (#{inspect(reason)})!", ansi_color: :magenta)
  end

  defp send_handler(slack, _state, message, channel) do
    Logger.debug(
      "#{__MODULE__} : <-- #{inspect(message)} (#{inspect(channel)})",
      ansi_color: :magenta
    )

    send_message(message, channel, slack)
  end

  defp react_handler(slack, _state, message, emoji) do
    timestamp = message.ts
    channel = message.channel
    token = slack.token

    Slack.Web.Reactions.add(emoji, %{timestamp: timestamp, token: token, channel: channel})
  end

  #############
  # Callbacks #
  #############

  def handle_connect(slack, state) do
    Process.register(self(), __MODULE__)
    connect_handler(slack, state)
    {:ok, state}
  end

  def handle_event(event, slack, state) do
    event_handler(slack, state, event)
    {:ok, state}
  end

  def handle_close(reason, slack, state) do
    close_handler(slack, state, reason)
    {:ok, state}
  end

  def handle_info({:send_msg, message, channel}, slack, state) do
    send_handler(slack, state, message, channel)
    {:ok, state}
  end

  def handle_info({:react, message, emoji}, slack, state) do
    react_handler(slack, state, message, emoji)
    {:ok, state}
  end
end
