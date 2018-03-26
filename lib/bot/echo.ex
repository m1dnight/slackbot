defmodule Bot.Echo do
  use Slackbot.Plugin
  require Logger

  def on_message(<<"echo "::utf8, _rest::bitstring>>, _channel, _from) do
    Logger.warn("Kemem")
    {:react, "sunglasses"}
  end

  def on_message(_m, _c, _f) do
    {:noreply}
  end
end
