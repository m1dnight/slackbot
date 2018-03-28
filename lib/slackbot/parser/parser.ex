defmodule Slackbot.Parser do
  @moduledoc """
  Parser contains several functions that parses messages from slack into workable structs, and vice versa.
  """
  use GenServer
  require Logger
  alias Slackbot.{Parser}
  alias Slackbot.Web.Hash

  ##########
  # Struct #
  ##########

  defstruct token: nil

  def start_link(token \\ []) do
    GenServer.start_link(__MODULE__, token, name: __MODULE__)
  end

  def init(token \\ []) do
    state = %Parser{token: token}
    {:ok, state}
  end

  #######
  # API #
  #######

  @doc """
  Given a message, parses it and then adds human readable information to it.

  Channel names/Group names are added in their human readable form, and usernames are 
  translated to their human readble equivalent.
  """
  def parse_event(event), do: GenServer.call(__MODULE__, {:parse_event, event})

  #############
  # Callbacks #
  #############

  def handle_call({:parse_event, event}, _from, state) do
    Logger.debug("#{__MODULE__} : Parsing event #{inspect(event)}", ansi_color: :yellow)
    parsed = parse(event, state.token)
    {:reply, parsed, state}
  end

  ###########
  # Helpers #
  ###########

  # Example of a DM. This is the same for private, groups, and DMs.
  # %{
  #   channel: "D3PL9E24E",
  #   source_team: "T04K740FU",
  #   team: "T04K740FU",
  #   text: "joe",
  #   ts: "1522263010.000246",
  #   type: "message",
  #   user: "U04K740G0"
  # }
  defp parse(event = %{type: "message", channel: id, user: uhash}, token) do
    {:ok, uname} = Hash.user_hash_to_string(uhash, token)
    {:ok, type} = Hash.channel_type(id, token)
    # Based on the type, call the right function to resolve the id.
    name =
      case type do
        :dm ->
          {:ok, name} = Hash.user_hash_to_string(event.user, token)
          name

        :group ->
          {:ok, name} = Hash.group_hash_to_string(id, token)
          name

        :channel ->
          {:ok, name} = Hash.channel_hash_to_string(id, token)
          name
      end

    parsed =
      event
      |> Map.put(:msg_type, type)
      |> Map.put(:channelname, name)
      |> Map.put(:username, uname)

    {type, parsed}
  end

  defp parse(event, _token) do
    {:other, event}
  end
end
