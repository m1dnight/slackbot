defmodule Bot.Crash do
  use Plugin

  def on_message("crash", _channel) do
    raise "Ermegerd"
    {:noreply}
  end

  def on_message(_, _) do
    {:noreply}
  end
end
