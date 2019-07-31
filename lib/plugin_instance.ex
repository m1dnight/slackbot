defmodule Slackbot.PluginInstance do
  @moduledoc """
  A GenServer that runs a given Plugin.
  """
  use GenServer
  require Logger
  alias Slackbot.ConnectionHandler

  def start_link(module, state) do
    GenServer.start_link(__MODULE__, {module, state})
  end

  def init({module, state}) do
    Slackbot.PubSub.register(:message)
    Slackbot.PubSub.register(:connected)
    Slackbot.PubSub.register(:mention)

    {:ok, %{:module => module, :state => state}}
  end

  #############
  # Callbacks #
  #############

  def handle_cast({:message, m}, state) do
    state =
      case state.module.handle_message(m, state) do
        {:ok, state} ->
          state

        {:react, message, emoji, state} ->
          ConnectionHandler.react_to(message, emoji)
          state

        {:message, channel, text, state} ->
          ConnectionHandler.send_text(channel, text)
          state
      end

    {:noreply, state}
  end

  def handle_cast({:mention, m}, state) do

    state =
      case state.module.handle_mention(m, state) do
        {:ok, state} ->
          state

        {:react, message, emoji, state} ->
          ConnectionHandler.react_to(message, emoji)
          state

        {:message, channel, text, state} ->
          ConnectionHandler.send_text(channel, text)
          state
      end

    {:noreply, state}
  end

  def handle_cast({:connected, username}, state) do
    state =
      case state.module.handle_connected(username, state) do
        {:ok, state} -> state
        {:message, _channel, _text, state} -> state
      end

    {:noreply, state}
  end

  def handle_cast(m, state) do
    {:noreply, state}
  end

  def handle_info(m, state) do
    {:noreply, state}
  end
end
