defmodule SlackManager do
  @moduledoc """
  This module wraps around the SlackLogic module. It allows processes to
  subscribe to events from Slack. This module manages these subscribers.
  """
  use GenServer
  require Logger

  @doc """
  The state of the SlackManager process.
  """
  defmodule State do
    defstruct client: :nil, handlers: MapSet.new(), token: :nil, aliases: %{}
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
  def handle_cast({:send_msg, msg, channel}, state) do
    send(state.client, {:send_msg, msg, channel})
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

  def handle_call({:hash_channel, channelname}, _from, state = %{aliases: aliasmap}) do
    {hash, channelname} = hash_channel(channelname, state)
    # Store this alias in memory.
    new_state = %{state | aliases: Map.put(aliasmap, channelname, hash)}
    {:reply, {:ok, {hash, channelname}}, new_state}
  end

  def handle_call({:dehash_channel, channelhash}, _from, state = %{aliases: aliasmap}) do
    {hash, channelname} = dehash_channel(channelhash, state)
    new_state = %{state | aliases: Map.put(aliasmap, channelname, hash)}
    {:reply, {:ok, {hash, channelname}}, new_state}
  end

  ###########
  # Web API #
  ###########

  # Dealiases a single hash. Expects a hash in the form of "ABCDEF".
  defp dealias_userhash(input, state) do
    info = Slack.Web.Users.info(input, %{token: state.token})
    Map.get(Map.get(info, "user"), "name")
  end

  # Aliases a channelanme. E.g. alias_channel("random") => "ABCDEF"
  defp hash_channel(channelname, state = %{aliases: aliasmap}) do
    case aliasmap[channelname] do
      :nil -> hash_channel_slack(channelname, state)
      hash -> {hash, channelname}
    end
  end
  # Fetches the hash from a channel name via the Slack API.
  defp hash_channel_slack(channelname, state) do
    Logger.debug "Hashing #{channelname} through the API."
    res = Slack.Web.Channels.list(%{token: state.token})
    res["channels"]
    |> Enum.map(fn(c) ->
                  {c["id"], c["name"]}
                end)
    |> List.keyfind(channelname, 1, {:nil, channelname})
  end

  # Turns a channel hashname into the channel name.
  defp dehash_channel(hash, state = %{aliases: aliasmap}) do
    values = Map.to_list aliasmap
    {hash, name} = List.keyfind(values, hash, 1, {hash, :nil})
    case name do
      :nil -> dehash_channel_slack(hash, state)
      hash -> {hash, name}
    end
  end

  # Turns a channel hashname into the channel name via the Slack API.
  defp dehash_channel_slack(hash, state) do
    Logger.debug "Dehashing #{hash} through the API."
    res = Slack.Web.Channels.list(%{token: state.token})
    res["channels"]
    |> Enum.map(fn(c) -> {c["id"], c["name"]} end)
    |> List.keyfind(hash, 0, {hash, :nil})
  end

  #############
  # Interface #
  #############

  def add_handler(pid) do
    GenServer.cast(SlackManager, {:add_handler, pid})
  end

  def remove_handler(pid) do
    GenServer.cast(SlackManager, {:remove_handler, pid})
  end

  def notify(m) do
    GenServer.cast(SlackManager, {:notify, m})
  end

  def dealias_message(m) do
    GenServer.call(SlackManager, {:dealias, m})
  end

  def hash_channel(channel) do
    GenServer.call(SlackManager, {:hash_channel, channel})
  end

  def dehash_channel(hash) do
    GenServer.call(SlackManager, {:dehash_channel, hash})
  end

  def send_message(m, channel) do
    GenServer.cast(SlackManager, {:send_msg, m, channel})
  end
end
