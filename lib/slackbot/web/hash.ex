defmodule Slackbot.Web.Hash do
  @moduledoc """
  Contains a few helper functions to work with the hashes (ids) of
  channels, users, and others.

  Uses the Web api of Slack, so a caching of these calls is needed
  in order to avoid flooding Slack.
  """
  require Logger

  @doc """
  Turns a user's hash into a human readable nickname.

  Example: Slackbot.Web.Hash.user_string_to_hash("cdetroye", slack_token)
           > "U04K740G0"
  """
  def user_hash_to_string(hash, token) do
    info = Slack.Web.Users.info(hash, %{token: token})

    case info do
      %{"error" => e} ->
        {:error, e}

      %{"ok" => true} ->
        username = Map.get(Map.get(info, "user"), "name")
        {:ok, username}
    end
  end

  @doc """
  Turns a user's username into its hash.
  """
  def user_string_to_hash(username, token) do
    info = Slack.Web.Users.list(%{token: token})

    user =
      info
      |> Map.get("members")
      |> Enum.filter(fn m ->
        m["name"] == username
      end)

    case user do
      [] -> {:error, "not found #{username}"}
      [x] -> Map.get(x, "id")
    end
  end

  @doc """
  Turns a channel's id into its human readable form.
  Works for public channels only.
  """
  def channel_hash_to_string(hash, token) do
    info = Slack.Web.Channels.list(%{token: token})

    channel =
      info
      |> Map.get("channels")
      |> Enum.filter(fn c -> c["id"] == hash end)

    case channel do
      [] ->
        {:error, "not found #{hash}"}

      [x] ->
        {:ok, x["name"]}

      _ ->
        {:error, "found multiple channels with same hash! #{inspect(channel)}"}
    end
  end

  @doc """
  Turns a channel's human readable name into it's hash.
  Works only for public channels.
  """
  def channel_string_to_hash(name, token) do
    info = Slack.Web.Channels.list(%{token: token})

    channel =
      info
      |> Map.get("channels")
      |> Enum.filter(fn c -> c["name"] == name end)

    case channel do
      [] ->
        {:error, "not found #{name}"}

      [x] ->
        {:ok, x["id"]}

      _ ->
        {:error, "found multiple channels with same name! #{inspect(channel)}"}
    end
  end

  @doc """
  Turns a group's id into its human readable form.
  """
  def group_hash_to_string(hash, token) do
    %{"groups" => groups} = Slack.Web.Groups.list(%{token: token})

    channel =
      groups
      |> Enum.filter(fn c -> c["id"] == hash end)

    case channel do
      [] ->
        {:error, "not found #{hash}"}

      [x] ->
        {:ok, x["name"]}

      _ ->
        {:error, "found multiple channels with same hash! #{inspect(channel)}"}
    end
  end

  @doc """
  Turns a group's human readable name into it's hash.
  """
  def group_string_to_hash(name, token) do
    %{"groups" => groups} = Slack.Web.Groups.list(%{token: token})

    channel =
      groups
      |> Enum.filter(fn c -> c["name"] == name end)

    case channel do
      [] ->
        {:error, "not found #{name}"}

      [x] ->
        {:ok, x["id"]}

      _ ->
        {:error, "found multiple channels with same name! #{inspect(channel)}"}
    end
  end

  @doc """
  Given a channel ID, checks whether or not this is a private messaging ID.
  """
  def is_dm?(id, token) do
    %{"ims" => ims} = Slack.Web.Im.list(%{token: token})

    im =
      ims
      |> Enum.filter(fn im -> im["id"] == id end)

    im != []
  end

  @doc """
  Returns the type of the channel id.
  E.g., :dm, :group, or :channel.
  """
  def channel_type(id, token) do
    groupname = group_hash_to_string(id, token)

    case groupname do
      {:ok, _name} ->
        {:ok, :group}

      _ ->
        channelname = channel_hash_to_string(id, token)

        case channelname do
          {:ok, _name} ->
            {:ok, :channel}

          _ ->
            if is_dm?(id, token) do
              {:ok, :dm}
            else
              {:error, "not found  #{id}"}
            end
        end
    end
  end
end
