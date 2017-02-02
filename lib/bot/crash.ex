defmodule Bot.Crash do
  use Plugin

  def on_message("crash") do
    raise "Ermegerd"
    {:noreply}
  end

  def on_message(_) do
    {:noreply}
  end
end
