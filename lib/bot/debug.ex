defmodule Bot.Debug do
  use Plugin

  def on_message("::channel", channel, _from) do
    {:ok, "Current channel name: #{channel}"}
  end

  def on_message(_m, _channel, _from) do
    {:noreply}
  end
end
