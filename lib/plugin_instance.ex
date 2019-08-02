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
    Slackbot.PubSub.register(:reaction)
    Slackbot.PubSub.register(:dm)

    # Check if the plugin has stored state.
    plugin_state =
      case Storage.read(module) do
        {:error, :not_found} ->
          Storage.store(module, state)
          state

        {:ok, state} ->
          state
      end

    {:ok, %{:module => module, :plugin_state => plugin_state}}
  end

  def child_spec(arg) do
    default = %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, arg}
    }

    Supervisor.child_spec(default, [])
  end

  #############
  # Callbacks #
  #############

  def handle_cast({:dm, m}, state) do
    plugin_state =
      case state.module.handle_dm(m, state.plugin_state) do
        {:ok, plugin_state} ->
          plugin_state

        {:message, channel, text, plugin_state} ->
          ConnectionHandler.send_text(channel, text)
          plugin_state

        {:react, message, emoji, plugin_state} ->
          ConnectionHandler.react_to(message, emoji)
          plugin_state
      end

    Storage.store(state.module, plugin_state)
    state = %{state | plugin_state: plugin_state}
    {:noreply, state}
  end

  def handle_cast({:reaction, r}, state) do
    plugin_state =
      case state.module.handle_reaction(r, state.plugin_state) do
        {:ok, plugin_state} ->
          plugin_state

        {:message, channel, text, plugin_state} ->
          ConnectionHandler.send_text(channel, text)
          plugin_state

        {:react, message, emoji, plugin_state} ->
          ConnectionHandler.react_to(message, emoji)
          plugin_state
      end

    Storage.store(state.module, plugin_state)
    state = %{state | plugin_state: plugin_state}
    {:noreply, state}
  end

  def handle_cast({:message, m}, state) do
    plugin_state =
      case state.module.handle_message(m, state.plugin_state) do
        {:ok, plugin_state} ->
          plugin_state

        {:react, message, emoji, plugin_state} ->
          ConnectionHandler.react_to(message, emoji)
          plugin_state

        {:message, channel, text, plugin_state} ->
          ConnectionHandler.send_text(channel, text)
          plugin_state
      end

    Storage.store(state.module, plugin_state)
    state = %{state | plugin_state: plugin_state}
    {:noreply, state}
  end

  def handle_cast({:mention, m}, state) do
    plugin_state =
      case state.module.handle_mention(m, state.plugin_state) do
        {:ok, plugin_state} ->
          plugin_state

        {:react, message, emoji, plugin_state} ->
          ConnectionHandler.react_to(message, emoji)
          plugin_state

        {:message, channel, text, plugin_state} ->
          ConnectionHandler.send_text(channel, text)
          plugin_state
      end

    Storage.store(state.module, plugin_state)
    state = %{state | plugin_state: plugin_state}
    {:noreply, state}
  end

  def handle_cast({:connected, username}, state) do
    plugin_state =
      case state.module.handle_connected(username, state.plugin_state) do
        {:ok, plugin_state} ->
          plugin_state

        {:message, channel, text, plugin_state} ->
          ConnectionHandler.send_text(channel, text)
          plugin_state
      end

    Storage.store(state.module, plugin_state)
    state = %{state | plugin_state: plugin_state}

    {:noreply, state}
  end

  def handle_cast(_m, state) do
    {:noreply, state}
  end

  def handle_info(_m, state) do
    {:noreply, state}
  end
end
