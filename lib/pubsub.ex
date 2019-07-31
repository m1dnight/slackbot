defmodule Slackbot.PubSub do
  @moduledoc """
  The PubSub module is responsible to make sure messages are delivered to interest parties.

  Typically a plugin will subscribe to events of interest, and handle them accordingly.

  Possible types: :connected | :message | :mention | :message_out
  """
  def register(type) do
    Registry.register(__MODULE__, type, [])
  end

  def cast_all(type, message) do
    Registry.dispatch(__MODULE__, type, fn entries ->
      for {pid, _} <- entries do
        GenServer.cast(pid, {type, message})
      end
    end)
  end

  def call_all(type, message) do
    Registry.dispatch(__MODULE__, type, fn entries ->
      for {pid, _} <- entries do
        GenServer.call(pid, {type, message})
      end
    end)
  end
end
