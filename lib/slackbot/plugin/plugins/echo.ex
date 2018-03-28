defmodule Slackbot.Plugin.Echo do
  use Slackbot.Plugin
  require Logger

  def hook_pre(msg) do
    if Map.has_key?(msg, :text) do
      {:ok, %{msg | text: String.downcase(msg.text)}}
    else
      {:ok, msg}
    end
  end

  ####################################
  # Messages in channels, or groups. #
  ####################################

  def on_message(<<"dm?"::utf8, _rest::bitstring>>, _channel, _from) do
    {:reply, "probably not"}
  end

  def on_message(<<"reply "::utf8, rest::bitstring>>, _channel, _from) do
    {:reply, rest}
  end

  def on_message(<<"emoji "::utf8, rest::bitstring>>, _channel, _from) do
    {:react, rest}
  end

  def on_message(_m, _c, _f) do
    {:noreply}
  end

  ###################
  # Direct Messages #
  ###################

  def on_dm(<<"dm?"::utf8, _rest::bitstring>>, _from) do
    {:reply, "yep"}
  end

  def on_dm(<<"reply "::utf8, rest::bitstring>>, _from) do
    {:reply, rest}
  end

  def on_dm(<<"emoji "::utf8, rest::bitstring>>, _from) do
    {:react, rest}
  end

  def on_dm(_m, _from) do
    {:noreply}
  end


end
