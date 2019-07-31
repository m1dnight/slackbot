defmodule SlackbotTest do
  use ExUnit.Case
  doctest Slackbot

  test "greets the world" do
    assert Slackbot.hello() == :world
  end
end
