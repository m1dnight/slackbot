defmodule Slackbot.Parser do
  alias Slackbot.Message

  @moduledoc """
  The Parser module is responsible to aprse incoming and outgoing data.

  Incoming slack messages might have usernames in the shape of "<UZYX>",
  and this module is used to translate them to their human-readable counterparts.
  """

  ##############################################################################
  ## Parsers

  # %{
  #   channel: "C04K740NY",
  #   client_msg_id: "2fc53025-7718-4ffb-9906-4887a2278a5b",
  #   event_ts: "1564650139.009600",
  #   source_team: "T04K740FU",
  #   suppress_notification: false,
  #   team: "T04K740FU",
  #   text: "test <@U04K740G0>test",
  #   ts: "1564650139.009600",
  #   type: "message",
  #   user: "U04K740G0",
  #   user_team: "T04K740FU"
  # }
  def parse_message(%{type: "message", ts: ts, text: text, user: from, channel: channel}, token) do
    IO.puts(channel)
    username = username_hash_to_readable(from, token)
    text = dehash_string(text, token)
    channel = channel_hash_to_readable(channel, token)
    timestamp = parse_timestamp(ts)

    %Message{from: username, text: text, channel: channel, timestamp: timestamp, id: ts}
  end

  def parse_timestamp(ts) do
    ts
    |> String.split(".")
    |> hd()
    |> String.to_integer()
    |> Timex.from_unix()
  end

  ##############################################################################
  ## Find / Replace

  defp dehash_string(str, token) do
    ~r/\<@([a-zA-Z0-9]+)\>/
    |> Regex.replace(str, fn _, x ->
      username_hash_to_readable("#{x}", token)
    end)
  end

  ##############################################################################
  ## Channels

  defp channel_hash_to_readable(hash, token) do
    name =
      if cache_lookup({:channel_hash, hash}) do
        cache_lookup({:channel_hash, hash})
      else
        channels = Slack.Web.Channels.list(%{token: token})
        groups = Slack.Web.Groups.list(%{token: token})

        {_hash, name} =
          Enum.concat(groups["groups"], channels["channels"])
          |> Enum.map(fn c -> {c["id"], c["name"]} end)
          |> List.keyfind(hash, 0, {hash, nil})

        "##{name}"
      end

    cache_put({:channel_hash, hash}, name)

    name
  end

  def channel_readable_to_hash(readable, token) do
    readable = normalize(readable)

    if cache_lookup({:channel_readable, readable}) do
      cache_lookup({:channel_readable, readable})
    else
      channels = Slack.Web.Channels.list(%{token: token})
      groups = Slack.Web.Groups.list(%{token: token})
      IO.puts("Got channels and groups ")

      {hash, readable} =
        Enum.concat(groups["groups"], channels["channels"])
        |> Enum.map(fn c ->
          {c["id"], c["name"]}
        end)
        |> List.keyfind(readable, 1, {nil, readable})

      cache_put({:channel_readable, readable}, hash)

      hash
    end
  end

  ##############################################################################
  ## Usernames

  defp username_hash_to_readable(hash, token) do
    username =
      if cache_lookup({:user_hash, hash}) do
        cache_lookup({:user_hash, hash})
      else
        info = Slack.Web.Users.info(hash, %{token: token})

        if info do
          Map.get(Map.get(info, "user"), "name")
        else
          nil
        end
      end

    # if username do
    #   cache_put({:user_hash, hash}, username)
    # end

    username
  end

  ##############################################################################
  ## Util

  def normalize(<<"#"::utf8, rest::bitstring>>) do
    rest
  end

  def normalize(x), do: x

  ##############################################################################
  ## Cache

  def ensure_cache() do
    if :undefined == :ets.whereis(:parser_cache) do
      create_cache()
    end
  end

  def create_cache() do
    :ets.new(:parser_cache, [:public, :named_table, keypos: 1])
  end

  def cache_put(key, value) do
    ensure_cache()
    :ets.insert(:parser_cache, {key, value})
  end

  def cache_lookup(key) do
    ensure_cache()

    case :ets.lookup(:parser_cache, key) do
      [{^key, v}] ->
        v

      _ ->
        nil
    end
  end
end
