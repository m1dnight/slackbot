defmodule Bot.Rss do
  use Plugin
  require Logger
  @channel "random"
  @interval 2 * 60 * 60 * 1000 # 2 hours

  def initialize() do
    # Read in the feeds we need to read and schedule the updates.
    get_subscribed_feeds()
    |> Enum.map(fn(feed) ->
                  Bot.Cronjob.schedule({:repeat, __MODULE__, :process_feed, [feed], @interval})
                end)
  end

  def on_message(_,_) do
    {:noreply}
  end


  # Takes in a feed and checks for new entries and sends them to the Slack.
  def process_feed(feed) do
    feed
    |> get_bookmark()
    |> get_unseen_since()
    |> Enum.map(fn(e) ->
                  SlackManager.send_message(e, @channel)
                  Process.sleep(1000) # Dont spam too fast.
                end)
  end

  # Turns an RSS entry into a pretty-printed string.
  defp pretty_print_entry(entry) do
    "*#{entry.title}* - #{entry.link}"
  end

  # Returns the newest unseen entries for this RSS feed.
  defp get_unseen_since({url, last}) do
    with {:ok, entries} <- get_entries(url)
    do
      to_show = entries
      |> filter_new(last)
      |> Enum.reverse # Print newest last.
      |> Enum.map(&pretty_print_entry/1)

      Timex.now |> Timex.to_date |> store_bookmark(url)

      Logger.debug "Found #{Enum.count(to_show)} new entries for #{url}"
      to_show
    else
      {:error, e} -> Logger.error "Error getting feed data #{e}"
      [] # Return empty list and carry on.
    end
  end

  # Given an RSS feed url, returns all the listed entries.
  defp get_entries(url) do
    with {:ok, response} <- HTTPoison.get(url),
         {:ok, feed, _}  <- FeederEx.parse(response.body) # In case of an error this seems to kill the entire process, fix this.
    do
      {:ok, feed.entries}
    else
      {:error, e} -> {:error, e}
      _           -> {:error, "Unknown error while parsing feed.."}
    end
  end

  # Given a list of RSS entries and a date (Timex), returns all the entries that
  # are newer.
  defp filter_new(entries, last_known) do
    entries
    |> Enum.filter(fn(e) ->
                     entry_date = e.updated |> Timex.parse!("{RFC1123}") |> Timex.to_date
                     Timex.before?(last_known, entry_date)
                   end)
  end

  #############
  # Bookmarks #
  #############

  # Updates the last known entry for a given RSS feed on disk.
  defp store_bookmark(time, feed) do
    bookmarks = List.keystore(get_bookmarks(), feed, 0, {feed, time})
    content = bookmarks
    |> Enum.map(&[:io_lib.print(&1) | ".\n"])
    |> IO.iodata_to_binary

    File.write(data_file(), content)
  end

  # Gets the last known RSS entry for this file from disk.
  defp get_bookmark(feed) do
    lasts = get_bookmarks()
    List.keyfind(lasts, feed, 0, {feed, Timex.zero})
  end

  ###################
  # Disk operations #
  ###################

  # Reads the data from the RSS reader. If none exists, the empty list is
  # returned.
  defp get_bookmarks() do
    case :file.consult(data_file()) do
      {:ok, content} -> content
      _              -> []
    end
  end

  # Returns a list of feeds the user is subscribed to.
  defp get_subscribed_feeds() do
    case :file.consult(feed_list()) do
      {:ok, content} -> content
      _              -> []
    end
  end
  # The location of the data file on disk.
  defp data_file do
    "data/rss/backup.dat"
  end

  defp feed_list do
    "data/rss/feeds.dat"
  end
end
