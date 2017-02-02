defmodule Bot.Debug do
  use GenServer
  require Logger
  @moduledoc """
  This module will print out all the events that are received from Slack.
  """
  def start_link(client) do
    GenServer.start_link(__MODULE__, [client])
  end

  def init([client]) do
    Bot.Cronjob.schedule({:repeat, IO, :puts, ["cron"], 2000})
    {:ok, client}
  end

  ########
  # Info #
  ########

  @doc """
  A catch-all for unimportant messages.
  """
  def handle_info(i, state) do
    Logger.debug("#{:io_lib.format("~p~n", [i])}")
    {:noreply, state}
  end

end
