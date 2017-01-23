defmodule Bot.Rss do
  use GenServer
  require Logger
  @channel "random"
  @moduledoc """
  This plugin follows RSS feeds and notifies the Slack channel in case of an
  update.
  """
  @interval 5 * 60 * 1000 # 5 minutes.

  def start_link(client) do
    GenServer.start_link(__MODULE__, [client])
  end

  def init([client]) do
    # Gets the actual ID of the channel before kicking of the RSS feed.
    {:ok, {id, _channel}} = SlackManager.channel_hash(client, @channel)

    # Read in the feeds we need to read and schedule the updates.
    feeds = get_feeds()
    Enum.map(feeds, fn(feed) ->
      Bot.Cronjob.schedule({:repeat, Kernel, :send, [self, {:check, feed}], @interval})
    end)

    {:ok, {client, id}}
  end

  ########
  # Info #
  ########

  @doc """
  Check the given RSS feed.
  """
  def handle_info({:check, feed}, {client, channelid}) do
    Logger.debug "RSS checking feed: #{feed}"
    {^feed, last_seen} = get_last(feed)
    unseen = get_unseen_since(feed, last_seen)
    Enum.map(unseen,
    fn(e) ->
      SlackManager.send(client, e, channelid)
      Process.sleep(1000) # Dont spam too fast.
    end)
    {:noreply, {client, channelid}}
  end

  @doc """
  A catch-all for unimportant messages.
  """
  def handle_info(_, state) do
    {:noreply, state}
  end

  ###########
  # Private #
  ###########

  @doc """
  Returns the newest unseen entries for this RSS feed.
  """
  def get_unseen_since(url, last) do
    to_show = url
    |> get_entries
    |> filter_new(last)
    |> Enum.map(&pretty_print/1)
    # Update the last seen time.
    Timex.now |> Timex.to_date |> store_last(url)
    to_show
  end

  @doc """
  Given an RSS feed url, returns all the listed entries.
  """
  defp get_entries(url) do
    {:ok, %HTTPoison.Response{body: body}} = HTTPoison.get(url)
    {:ok, feed, _} = FeederEx.parse(body)
    feed.entries
  end

  @doc """
  Given a list of RSS entries and a date (Timex), returns all the entries that
  are newer.
  """
  defp filter_new(entries, last_known) do
    entries
    |> Enum.filter(fn(e) ->
      (e.updated
      |> Timex.parse!("{RFC1123}")
      |> Timex.to_date)
      > last_known end)
    end

    @doc """
    Turns an RSS entry into a pretty-printed string.
    """
    defp pretty_print(entry) do
      "*#{entry.title}* - #{entry.link}"
    end

    @doc """
    Updates the last known entry for a given RSS feed on disk.
    """
    defp store_last(time, feed) do
      lasts = read_data()
      new_lasts = List.keystore(lasts, feed, 0, {feed, time})
      content = new_lasts
      |> Enum.map(&[:io_lib.print(&1) | ".\n"])
      |> IO.iodata_to_binary
      File.write(data_file, content)
    end

    @doc """
    Gets the last known RSS entry for this file from disk.
    """
    defp get_last(feed) do
      lasts = read_data()
      List.keyfind(lasts, feed, 0, {feed, Timex.zero})
    end

    @doc """
    Reads the data from the RSS reader. If none exists, the empty list is
    returned.
    """
    defp read_data() do
      case :file.consult(data_file) do
        {:ok, content} -> content
        _              -> []
      end
    end

    @doc """
    Returns a list of feeds the user is subscribed to.
    """
    defp get_feeds() do
      case :file.consult(feed_list) do
        {:ok, content} -> content
        _              -> []
      end
    end
    @doc """
    The location of the data file on disk.
    """
    defp data_file do
      "data/rss/backup.dat"
    end

    defp feed_list do
      "data/rss/feeds.dat"
    end
  end
