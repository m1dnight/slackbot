defmodule Slackbot.Repo.Migrations.CreateKarma do
  use Ecto.Migration

  def change do
    create table(:karma) do
      add :username, :string
      add :karma,    :integer
    end
    create unique_index(:karma, [:username])
  end



end
