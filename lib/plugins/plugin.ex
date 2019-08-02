defmodule Slackbot.Plugin do
  @callback handle_message(any, any) :: {:ok, term} | {:react, term, term, term} | {:message, term, term, term}
  @callback handle_mention(any, any) :: {:ok, term} | {:react, term, term, term} | {:message, term, term, term}
  @callback handle_reaction(any, any) :: {:ok, term} | {:react, term, term, term} | {:message, term, term, term}
  @callback handle_connected(any, any) :: {:ok, term} | {:message, term, term, term}
  @callback handle_dm(any, any) :: {:ok, term} | {:reply, term, term, term} | {:react, term, term, term}
end
