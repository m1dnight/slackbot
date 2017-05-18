defmodule SlackLogic do

  @moduledoc """
  This module provides functionalityy to the Slack API. It is the first module
  that touches incoming messages from Slack.
  """
  use Slack

  require Logger

  @doc """
  This function is called whenever a connection to Slack is made.
  """
  def handle_connect(slack, state) do
    Logger.debug "Connected as #{slack.me.name}"
    SlackManager.notify(:connected)
    {:ok, state}
  end

  @doc """
  This function is called whenever a message arrives from Slack.
  These messages are annotated with a type in the map, which are "regular"
  messages sent by users.

  Note that regular messages are pre-processsed to remove aliases of usernames
  which are in the form of some-sort of hashes.
  """
  def handle_event(message = %{type: "message", text: text, user: from}, slack, state) do
    Logger.debug ">> #{text}"
    {:ok, sender}    = SlackManager.dealias_userhash(from)
    {:ok, m}         = SlackManager.dealias_message(text)
    {:ok, {_, chan}} = SlackManager.dehash_channel(message.channel)
    message          = %{message | text: m, channel: chan, user: sender}

    # If this message has our name in it, we send a second notification.
    if String.contains?(message.text, slack.me.name) do
      SlackManager.notify(%{message | type: "mention"})
    end

    # Notify of a regular message.
    SlackManager.notify(message)
    {:ok, state}
  end

  @doc """
  A catch-all function for events which we forward to all subscribers.
  """
  def handle_event(event, _, state) do
    SlackManager.notify(event)
    {:ok, state}
  end

  @doc """
  The close function is called whenever Slack disconnects.
  """
  def handle_close(_reason, _slack, state) do
    SlackManager.notify(:disconnected)
    {:ok, state}
  end


  @doc """
  Info's come from the outside. IT allows us to send messages to the Slack
  process.
  """
  def handle_info({:send_msg, text, channel}, slack, state) do
  Logger.debug "<< #{channel}: #{text}"
    {:ok, {channel_id, _}} = SlackManager.hash_channel(channel)
    send_message(text, channel_id, slack)
    {:ok, state}
  end

  def handle_info(_,_, state) do
    {:ok, state}
  end
end
