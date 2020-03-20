defmodule Slackbot.Plugin.Corona do
  @behaviour Slackbot.Plugin
  require Logger

  @impl Slackbot.Plugin
  def handle_message(m = %Slackbot.Message{text: <<"corona"::utf8>>}, state) do
    {:ok, map} = get_status()

    confirmed = map["summaryStats"]["global"]["confirmed"]
    deaths = map["summaryStats"]["global"]["deaths"]
    recoveries = map["summaryStats"]["global"]["recovered"]
    {:message, m.channel_hash, "*Global* confirmed: `#{confirmed}`, deaths: `#{deaths}`, recoveries: `#{recoveries}`", state}
  end

  @impl Slackbot.Plugin
  def handle_message(m = %Slackbot.Message{text: <<"corona"::utf8, where::bitstring>>}, state) do
    {:ok, map} = get_status()
    countries = map["rawData"]

    where = String.downcase(where) |> String.trim()

    init = %{:death => 0, :recovered => 0, :confirmed => 0, :age => nil}

    r =
      countries
      |> Enum.filter(fn datum -> String.downcase(datum["Country/Region"]) == where end)
      |> Enum.reduce(init, fn %{
                                "Confirmed" => c,
                                "Deaths" => d,
                                "Recovered" => r,
                                "Last Update" => u
                              },
                              acc ->
        %{:death => dd, :recovered => rr, :confirmed => cc, :age => aa} = acc

        {:ok, age} = NaiveDateTime.from_iso8601(u)

        %{
          :death => String.to_integer(d) + dd,
          :recovered => String.to_integer(r) + rr,
          :confirmed => String.to_integer(c) + cc,
          :age => age
        }
      end)

    {:message, m.channel_hash,
     "*#{where |> String.split() |> Stream.map(&String.capitalize/1) |> Enum.join(" ")}* confirmed: `#{r.confirmed}`, deaths: `#{
       r.death
     }`, recoveries: `#{r.recovered}` (Updated #{NaiveDateTime.to_string(r.age)} UTC)", state}
  end

  @impl Slackbot.Plugin
  def handle_mention(_message, state) do
    {:ok, state}
  end

  @impl Slackbot.Plugin
  def handle_connected(_nickname, state) do
    {:ok, state}
  end

  @impl Slackbot.Plugin
  def handle_dm(_message, state) do
    {:ok, state}
  end

  @impl Slackbot.Plugin
  def handle_reaction(_, state) do
    {:ok, state}
  end

  ##############################################################################
  def get_status() do
    url = "https://call-cc.be/files/public/corona.json"

    with {:ok, resp} <- HTTPoison.get(url),
         {:ok, map} <- Poison.decode(resp.body) do
      {:ok, map}
    else
      e -> {:error, e}
    end
  end
end
