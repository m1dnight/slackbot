defmodule Bot.Owner do
  use Plugin

  @owner Application.fetch_env!(:slack, :owner)

  def on_message(<<"owner"::utf8, rest::bitstring>>, _channel) do
    {:ok,"My owner is #{@owner}"}
  end

  def on_message(text, channel) do
    {:noreply}
  end

end
