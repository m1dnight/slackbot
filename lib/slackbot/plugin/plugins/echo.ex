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

  def on_message(<<"dm?"::utf8, _rest::bitstring>>, _channel, _from, _m) do
    {:reply, "probably not"}
  end

  def on_message(<<"reply "::utf8, rest::bitstring>>, _channel, _from, _m) do
    {:reply, rest}
  end

  def on_message(<<"emoji "::utf8, rest::bitstring>>, _channel, _from, _m) do
    {:react, rest}
  end

  def on_message(<<"channel type"::utf8, _rest::bitstring>>, _channel, _from, m) do
    IO.puts "sending channel stuff"
    {:reply, inspect m}
  end

  def on_message(_text, _c, _f, _m) do
    {:noreply}
  end

  ###################
  # Direct Messages #
  ###################

  def on_dm(<<"dm?"::utf8, _rest::bitstring>>, _from, _m) do
    {:reply, "yep"}
  end

  def on_dm(<<"reply "::utf8, rest::bitstring>>, _from, _m) do
    {:reply, rest}
  end

  def on_dm(<<"emoji "::utf8, rest::bitstring>>, _from, _m) do
    {:react, rest}
  end

  def on_dm(_text, _from, _m) do
    {:noreply}
  end


end
