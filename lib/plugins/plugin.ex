defmodule Slackbot.Plugin do
  @callback handle_message(any, any) :: {:ok, term} | {:react, term, term} | {:message, term, term, term}
  @callback handle_mention(any, any) :: {:ok, term} | {:react, term, term} | {:message, term, term, term}
  @callback handle_connected(any, any) :: {:ok, term} | {:message, term, term, term}
end
