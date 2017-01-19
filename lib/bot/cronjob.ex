defmodule Bot.Cronjob do
  use GenServer
  require Logger

  @moduledoc """
  The Cronjob plugin allows other processes to schedule a task to happen
  periodically. It does not immediately interact with the user.
  """
  def start_link(client) do
    GenServer.start_link(__MODULE__, [client], name: __MODULE__)
  end

  def init([client]) do
    {:ok, client}
  end

  ########
  # Info #
  ########

  @doc """
  These messages arrive by using the schedule/1 function.
  {:repeat,..} is a message to repeat a command indefinitely.
  """
  def handle_info({:repeat, module, function, args, interval}, state) do
    apply(module, function, args)
    schedule({:repeat, module, function, args, interval})
    {:noreply, state}
  end
  @doc """
  Executes the function just like repeat, but only does so once.
  """
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

  @doc """
  To schedule a task to be run you call schedule/1.
  A message is sent after delay to the cronjob process, which will in turn
  execute the function provided in the message.

  repetition:
    :repeat -> Repeats forever.
    :once   -> Executed once.

  To schedule a job as a client, one might call:

  Bot.Cronjob.schedule({:repeat, IO, :puts, ["hello"], 1000})

  After 1 second the cronjob will print out "hello", and do so again after a
  second.
  """
  def schedule({repetition, module, function, args, delay}) do
    Process.send_after(Bot.Cronjob, {repetition, module, function, args, delay}, delay)
  end
end
