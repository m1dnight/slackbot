defmodule Slackbot.Plugin.Echo do
  @behaviour Slackbot.Plugin
  require Logger

  @impl Slackbot.Plugin
  def handle_reaction(_reaction, state) do
    {:ok, state}
  end

  @impl Slackbot.Plugin
  def handle_message(message, state) do
    Logger.debug("Echo: Message: #{inspect(message)}")

    case message.text do
      "react" ->
        {:react, message, "sunglasses", state}

      "echo" ->
        {:message, message.channel, "echo", state}

      _ ->
        {:ok, state}
    end
  end

  @impl Slackbot.Plugin
  def handle_mention(message, state) do
    Logger.debug("Echo: Mention: #{inspect(message)}")
    {:message, message.channel, message.text, state}
  end

  @impl Slackbot.Plugin
  def handle_connected(nickname, state) do
    Logger.debug("Echo: Connected: #{inspect(nickname)}")
    {:ok, state}
  end
end
