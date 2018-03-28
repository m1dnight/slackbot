defmodule Slackbot.Plugin do
  @moduledoc """
  This module defines the behaviour for a plugin. 

  Each plugin is used in its own GenServer and is supervised. 

  A Plugin can define multiple callbacks:

  - init/1:


  """
  require Logger
  use GenServer
  alias Slackbot.Plugin
  alias Slackbot.Connection.{Pubsub, Slack}

  #########
  # State #
  #########

  defstruct plugin_state: nil, module: nil

  #############
  # Callbacks #
  #############

  # Each Plugin should implement an on_message function.
  @callback on_message(message :: term, channel :: term, from :: term) :: any

  # Optional callback to execute when a DM is sent to the bot.
  @callback on_dm(message :: term, from :: term) :: any

  # Optional callback to execute when the plugin starts.
  @callback initialize() :: any

  # Optional callback to pre-hook into a message.
  @callback hook_pre(message :: term) :: any

  ###############
  # Using Macro #
  ###############

  defmacro __using__(_) do
    quote location: :keep do
      def init(s) do
        {:ok, s}
      end

      defoverridable init: 1

      def on_message(msg, chan, from) do
        {:noreply}
      end

      defoverridable on_message: 3

      def on_dm(msg, from) do
        {:noreply}
      end

      defoverridable on_dm: 2

      def hook_pre(msg) do
        {:ok, msg}
      end

      defoverridable hook_pre: 1
    end
  end

  ###################
  # GenServer Stuff #
  ###################

  @doc """
  This function is called when a programmer starts his module:
  Slackbot.Plugin.start_link(MyPlugin, initial_state)
  """
  def start_link({module, args}, options \\ []) do
    GenServer.start_link(__MODULE__, {module, args}, options)
  end

  @doc """
  This function is called by the GenServer process. Here we call the init function f the module provided
  by the programmer.
  """
  def init({mod, args}) do
    # We want to receive messages in this process.
    Pubsub.subscribe(:messages)
    Pubsub.subscribe(:dms)

    case mod.init(args) do
      {:ok, state} ->
        {:ok, %Plugin{plugin_state: state, module: mod}}

      _ ->
        {:stop, {:bad_return_value, :error}}
    end
  end

  #######################
  # GenServer callbacks #
  #######################

  def handle_info({:dm, m = %{type: "message", msg_type: :dm}}, state) do
    Logger.debug("#{state.module} : <-- #{inspect(m)}", ansi_color: :blue)
    {:ok, m} = state.module.hook_pre(m)
    resp = state.module.on_dm(m.text, m.username)
    handle_reply(state, m, resp)
    {:noreply, state}
  end

  def handle_info({:message, m = %{type: "message"}}, state) do
    Logger.debug("#{state.module} : <-- #{inspect(m)}", ansi_color: :blue)
    {:ok, m} = state.module.hook_pre(m)
    resp = state.module.on_message(m.text, m.channelname, m.username)
    handle_reply(state, m, resp)
    {:noreply, state}
  end

  def handle_info(_m, state) do
    {:noreply, state}
  end

  ###########
  # Helpers #
  ###########

  defp handle_reply(state, message, response) do
    case response do
      {:noreply} ->
        :noop

      {:reply, reply} ->
        Slack.send_message("#{reply}", message.channel)
        :ok

      {:react, emoji} ->
        Slack.react(message, emoji)
        :ok

      {:error, _reason} ->
        Logger.error("#{__MODULE__} : Error in plugin #{inspect(state.module)}")
    end
  end
end
