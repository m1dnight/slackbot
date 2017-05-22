defmodule Slackbot.Repo do
  use Ecto.Repo, otp_app: :slackbot

  def get_karma(username) do
    %Slackbot.Karma{}
  end
  

end
