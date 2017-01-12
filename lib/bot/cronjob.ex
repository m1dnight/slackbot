defmodule Bot.Cronjob do
  use GenServer
  @moduledoc """
  The Cronjob plugin allows other processes to schedule a task to happen
  periodically. It does not immediately interact with the user.
  """
  def start_link(client) do
    GenServer.start_link(__MODULE__, [client], name: __MODULE__)
  end

  def init([client]) do
    #SlackManager.add_handler client, self
    {:ok, client}
  end

  ########
  # Info #
  ########

  @doc """
  Any process can send a message to register a function to be called after a
  certain period.
  """
  def handle_info({:schedule_once, module, function, args, delay}, state) do
    schedule({:once, module, function, args, delay})
    {:noreply, state}
  end

  def handle_info({:schedule, module, function, args, interval}, state) do
    schedule({:repeat, module, function, args, interval})
    {:noreply, state}
  end

  @doc """
  Each task execution happens when we receive a message that we sent to
  ourselves by means of schedule/1 and schedule_once/1.
  """
  def handle_info({:repeat, module, function, args, interval}, state) do
    apply(module, function, args)
    schedule({:repeat, module, function, args, interval})
    {:noreply, state}
  end

  def handle_info({:once, module, function, args, interval}, state) do
    apply(module, function, args)
    {:noreply, state}
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

  def schedule({repetition, module, function, args, delay}) do
    Process.send_after(self(), {repetition, module, function, args, delay}, delay)
  end
end
