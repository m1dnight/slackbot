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
    defstruct client: :nil, handlers: MapSet.new(), token: :nil, aliases: %{}, channels: %{}
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
                |> Regex.replace(m,
                     fn _, x ->
                       {:ok, username} = dealias_userhash("#{x}", state)
                       username
                     end)
    {:reply, {:ok, dealiased}, state}
  end

  def handle_call({:dealias_user, m}, _from, state = %{aliases: aliasmap}) do
    {:ok, dealiased} = dealias_userhash(m, state)
    new_state = %{state | aliases: Map.put(aliasmap, m, dealiased)}
    {:reply, {:ok, dealiased}, new_state}
  end

  def handle_call({:hash_channel, channelname}, _from, state = %{aliases: aliasmap}) do
    {hash, channelname} = hash_channel(channelname, state)
    # Store this alias in memory.
    new_state = %{state | aliases: Map.put(aliasmap, channelname, hash)}
    {:reply, {:ok, {hash, channelname}}, new_state}
  end

  def handle_call({:dehash_channel, channelhash}, _from, state = %{channels: cs}) do
    Logger.debug "Dehashing channel #{channelhash}"
    case Map.get(cs, channelhash) do
      :nil -> {:hash, hash, :name, name} = dehash_channel_slack(channelhash, state)
              new_state = %{state | channels: Map.put(cs, hash, name)}
              {:reply, {:ok, {hash, name}}, new_state}
      name -> {:reply, {:ok, {channelhash, name}}, state}
    end
  end

  ###########
  # Web API #
  ###########

  ## HASHING

  # Aliases a channelanme. E.g. alias_channel("random") => "ABCDEF"
  defp hash_channel(channelname, state = %{aliases: aliasmap}) do
    case aliasmap[channelname] do
      :nil -> hash_channel_slack(channelname, state)
      hash -> {hash, channelname}
    end
  end

  # Fetches the hash from a channel name via the Slack API.
  defp hash_channel_slack(channelname, state) do
    Logger.debug "Hashing channel #{channelname} through the API."
    channels = Slack.Web.Channels.list(%{token: state.token})
    groups   = Slack.Web.Groups.list(%{token: state.token})
    Enum.concat(groups["groups"], channels["channels"])
    |> Enum.map(fn(c) ->
                  {c["id"], c["name"]}
                end)
    |> List.keyfind(channelname, 1, {:nil, channelname})
  end

  ## DEHASHING

  # Dealiases a single hash. Expects a hash in the form of "ABCDEF".
  defp dealias_userhash(user_hash, state = %{aliases: aliasmap}) do
    case aliasmap[user_hash] do
      :nil     -> dealias_userhash_slack(user_hash, state)
      username -> {:ok, username}
    end
  end

  defp dealias_userhash_slack(user_hash, state) do
    Logger.debug "Dehashing user #{user_hash} through the API."
    info = Slack.Web.Users.info(user_hash, %{token: state.token})
    username = Map.get(Map.get(info, "user"), "name")
    {:ok, username}
  end

  # Turns a channel hashname into the channel name via the Slack API.
  defp dehash_channel_slack(hash, state) do
    Logger.debug "Dehashing channel #{hash} through the API."
    channels = Slack.Web.Channels.list(%{token: state.token})
    groups   = Slack.Web.Groups.list(%{token: state.token})
    {hash, name} = Enum.concat(groups["groups"], channels["channels"])
    |> Enum.map(fn(c) -> {c["id"], c["name"]} end)
    |> List.keyfind(hash, 0, {hash, :nil})

    Logger.debug "API result: #{hash} resolved to #{name}"
    {:hash, hash, :name, name}
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

  def dealias_userhash(m) do
    GenServer.call(SlackManager, {:dealias_user, m})
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
