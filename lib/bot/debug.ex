defmodule Bot.Debug do
  use Plugin
  require Logger

  def on_message(m) do
    Logger.debug("#{m}")
    {:noreply}
  end

end
