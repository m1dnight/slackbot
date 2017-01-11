defmodule Bot.Crash do
  use GenServer
  @moduledoc """
  This is the Crash plugin. It makes the entire supervisor tree crash to
  showcase restarting of the bot.
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
  If the message equals "crash", we crash.
  """
  def handle_info(m = %{type: "message", text: "crash"}, state) do
    raise "Ermegerd"
    {:noreply, state}
  end

  @doc """
  A catch-all for unimportant messages.
  """
  def handle_info(_, state) do
    {:noreply, state}
  end
end
