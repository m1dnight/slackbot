defmodule Bot.Crash do
  use Plugin

  def on_message("crash", _channel, _from) do
    raise "Ermegerd"
    {:noreply}
  end

  def on_message(_m, _channel, _from) do
    {:noreply}
  end
end
