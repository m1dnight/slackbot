defmodule Bot.Crash do
  use Plugin

  def on_message("crash", _channel) do
    raise "Ermegerd"
    {:noreply}
  end

  def on_message(_m, _channel) do
    {:noreply}
  end
end
