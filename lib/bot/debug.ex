defmodule Bot.Debug do
  use GenServer
  @moduledoc """
  This module will print out all the events that are received from Slack.
  """
  def start_link(client) do
    GenServer.start_link(__MODULE__, [client])
  end

  def init([client]) do
    SlackManager.add_handler client, self
    {:ok, client}
  end

  ########
  # Info #
  ########

  @doc """
  A catch-all for unimportant messages.
  """
  def handle_info(i, state) do
    debug("#{:io_lib.format("~p~n", [i])}")
    {:noreply, state}
  end

  ###########
  # Private #
  ###########

  defp debug(msg) do
    IO.puts IO.ANSI.yellow() <> msg <> IO.ANSI.reset()
  end

end