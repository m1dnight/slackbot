defmodule Slackbot.Plugin do
  require Logger
  alias Slackbot.Plugin
  use GenServer

  #########
  # State #
  #########

  defstruct plugin_state: nil, module: nil

  #############
  # Callbacks #
  #############

  # Each Plugin should implement an on_message function.
  @callback on_message(message :: term, channel :: term, from :: term) :: any

  # Optional callback to execute when the plugin starts.
  @callback initialize() :: any

  ###############
  # Using Macro #
  ###############

  defmacro __using__(_) do
    quote location: :keep do
      require Logger

      def init(s) do
        {:ok, s}
      end

      defoverridable init: 1

      def on_message(msg, chan, from) do
        Logger.debug("#{__MODULE__} << #{inspect(msg)}")
        {:noreply}
      end

      defoverridable on_message: 3
    end
  end

  ###################
  # GenServer Stuff #
  ###################

  def child_spec(arg) do
    default = %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, arg}
    }

    Supervisor.child_spec(default, [])
  end

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
    SlackManager.add_handler(self())

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

  def handle_call(m, from, state) do
    {:reply, :response, state}
  end

  def handle_cast(m, state) do
    {:noreply, state}
  end

  @doc """
  A regular message in a channel has the following form.
  %{
    channel: "general",
    source_team: "T04K740FU",
    team: "T04K740FU",
    text: "foobar",
    ts: "1521811286.000369",
    type: "message",
    user: "cdetroye"
  }
  """
  def handle_info(%{type: "message"} = m, state) do
    resp = state.module.on_message(m.text, m.channel, m.user)

    case resp do
      {:noreply} ->
        :noop

      {:ok, reply} ->
        SlackManager.send_message("#{reply}", m.channel)

      {:react, emoji} ->
        SlackManager.react(m, emoji)

      {:error, _reason} ->
        Logger.error("Error in plugin #{inspect(state.module)}")
    end

    {:noreply, state}
  end

  def handle_info(m, state) do
    {:noreply, state}
  end

  #######
  # API #
  #######
end
