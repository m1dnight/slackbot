defmodule SlackManager do
  @moduledoc """
  This module wraps around the SlackLogic module. It allows processes to
  subscribe to events from Slack. This module manages these subscribers.
  """
  use GenServer

  @doc """
  The state of the SlackManager process.
  """
  defmodule State do
    defstruct client: :nil, handlers: MapSet.new(), token: :nil
  end

  def start_link(client,token) do
    GenServer.start_link(__MODULE__, [client,token], name: __MODULE__)
  end

  def init([client,token]) do
    {:ok, %State{client: client, token: token}}
  end

  #########
  # Casts #
  #########

  @doc """
  Notifies all subscribers with the given message.
  """
  def handle_cast({:notify, m}, state) do
    for handler <- state.handlers, do: send(handler, m)
    {:noreply, state}
  end

  @doc """
  Remove a subscriber.
  """
  def handle_cast({:remove_handler, pid}, state) do
    handlers = MapSet.delete(state.handlers, pid)
    {:noreply, %{state | handlers: handlers}}
  end

  @doc """
  Adds a subscriber.
  """
  def handle_cast({:add_handler, pid}, state) do
    handlers = MapSet.put(state.handlers, pid)
    {:noreply, %{state | handlers: handlers}}
  end

  @doc """
  Sends a message over Slack to the given channel.
  """
  def handle_cast({:send, msg, channel}, state) do
    send(state.client, {:send, msg, channel})
    {:noreply, state}
  end

  #########
  # Calls #
  #########

  @doc """
  Takes in a message and tranlates all the hashes of usernames to actual
  usernames. E.g., <@dfkljdflkjdf> to "SLACKBOT".
  """
  def handle_call({:dealias, m}, _from, state) do
    dealiased = ~r/\<@([a-zA-Z0-9]+)\>/
    |> Regex.replace(m, fn _, x -> dealias_userhash("#{x}", state) end)
    {:reply, {:ok, dealiased}, state}
  end

  ###########
  # Web API #
  ###########

  @doc """
  Dealiases a single hash. Expects a hash in the form of "ABCDEF".
  """
  defp dealias_userhash(input, state) do
    info = Slack.Web.Users.info(input, %{token: state.token})
    Map.get(Map.get(info, "user"), "name")
  end

  #############
  # Interface #
  #############

  def add_handler(client, pid) do
    GenServer.cast(client, {:add_handler, pid})
  end

  def remove_handler(client, pid) do
    GenServer.cast(client, {:remove_handler, pid})
  end

  def notify(m) do
    GenServer.cast(SlackManager, {:notify, m})
  end

  def dealias_message(client, m) do
    GenServer.call(client, {:dealias, m})
  end

  def send(client, m, channel) do
    GenServer.cast(client, {:send, m, channel})
  end
end
