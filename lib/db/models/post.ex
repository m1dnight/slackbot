defmodule Slackbot.Post do
  use Ecto.Schema

  schema "posts" do
    field :header, :string
    field :body, :string
    many_to_many :tags, Slackbot.Tag, join_through: "posts_tags"
  end
end