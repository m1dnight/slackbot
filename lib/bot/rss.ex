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
    feeds = get_subscribed_feeds()
    Enum.map(feeds, fn(feed) ->
      Bot.Cronjob.schedule({:repeat, Kernel, :send, [self(), {:check, feed}], @interval})
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
    {^feed, last_seen} = get_bookmark(feed)
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
    |> Enum.reverse # This way, if we print more than 1, the newest entry is printed last.
    |> Enum.map(&pretty_print_entry/1)
    # Update the last seen time.
    Timex.now |> Timex.to_date |> store_bookmark(url)
    to_show
  end

  @doc """
  Given an RSS feed url, returns all the listed entries.
  """
  defp get_entries(url) do
    with {:ok, response} <- HTTPoison.get(url),
         {:ok, feed, _}  <- FeederEx.parse(response.body)
    do
      feed.entries
    else
      {:error, e} -> Logger.error e
                     [] # No entries in case of error
      _           -> Logger.error "Unknown error parsing feed #{url}"
                     []
    end
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
    defp pretty_print_entry(entry) do
      "*#{entry.title}* - #{entry.link}"
    end

    @doc """
    Updates the last known entry for a given RSS feed on disk.
    """
    defp store_bookmark(time, feed) do
      bookmarks = List.keystore(get_bookmarks(), feed, 0, {feed, time})
      content = bookmarks
      |> Enum.map(&[:io_lib.print(&1) | ".\n"])
      |> IO.iodata_to_binary
      File.write(data_file(), content)
    end

    @doc """
    Gets the last known RSS entry for this file from disk.
    """
    defp get_bookmark(feed) do
      lasts = get_bookmarks()
      List.keyfind(lasts, feed, 0, {feed, Timex.zero})
    end

    @doc """
    Reads the data from the RSS reader. If none exists, the empty list is
    returned.
    """
    defp get_bookmarks() do
      case :file.consult(data_file()) do
        {:ok, content} -> content
        _              -> []
      end
    end

    @doc """
    Returns a list of feeds the user is subscribed to.
    """
    defp get_subscribed_feeds() do
      case :file.consult(feed_list()) do
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
