defmodule Bot.Misc do
  use Plugin

  @owner Application.fetch_env!(:slack, :owner)
  @github Application.fetch_env!(:slack, :github)
  def on_message(<<"!owner"::utf8, _rest::bitstring>>, _channel, _from) do
    {:ok, "My owner is #{@owner}"}
  end

  def on_message(<<"!bug "::utf8, target::bitstring>>, channel, from) do
    {:ok,
     "#{target}, seems like are not happy with the current operations of the bot. If you feel like this hinders you in any way, feel free to write a patch and submit it on GitHub. You can find the repository at #{
       @github
     }"}
  end

  def on_message("!channel", channel, _from) do
    {:ok, "Current channel name: #{channel}"}
  end

  def on_message("crash", _channel, _from) do
    raise "Ermegerd"
    {:noreply}
  end

  def on_message(_m, _channel, _from) do
    {:noreply}
  end
end
