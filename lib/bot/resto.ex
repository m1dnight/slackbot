defmodule Bot.Resto do
  use Plugin
  require Logger
  @url 'https://call-cc.be/files/vub-resto/etterbeek.nl.json'

  def on_message(<<"fret"::utf8, _::bitstring>>, _channel) do
    menu = get_menu()
    msg = case menu do
      :nil -> "Geen fret vandaag. Opinio is misschien open."
      _    -> menu
    end
    {:ok, "#{msg}"}
  end

  def on_message(_m, _channel) do
    {:noreply}
  end

  ###########
  # Private #
  ###########

  @doc """
  Returns the menu of today by retrieving information online.
  """
  def get_menu() do
    # Get the data from the webservcer.
    get_data()
    |> extract_today()
    |> parse_menu()
  end

  # Grabs the JSON data from the web, and parses it into a map.
  defp get_data() do
    {:ok, {{_, 200, 'OK'}, _, body}} = :httpc.request(:get, {@url, []}, [], [body_format: :binary])
    {:ok, menus} = Poison.decode(body)
    menus
  end

  # Given a parsed JSON map, returns the menu of today, if there is one. If not,
  # returns nil.
  defp extract_today(data) do
    data
    |> Enum.find(fn(x) -> x["date"] == "#{Timex.today}" end)
  end

  # Given a single map that contains all the menus for that day, returns a string
  # for that day that's printable. E.g.:
  #
  # %{"date" => "2017-01-11",
  # "menus" => [%{"color" => "#fdb85b", "dish" => "Kervelsoep", "name" => "Soep"},
  # %{"color" => "#68b6f3", "dish" => "Cordon Bleu met erwtjes en worteltjes",
  # "name" => "Menu 1"},
  # %{"color" => "#cc93d5",
  # "dish" => "Ovenschotel met kippengehakt, appelmoes en aardappelblokjes",
  # "name" => "Menu 2"},
  # %{"color" => "#f0eb93",
  # "dish" => "Tongrolletjes met spinazie en Nantua saus", "name" => "Vis"},
  # %{"color" => "#87b164", "dish" => "Groentekrustie met bloemkool in kaassaus",
  # "name" => "Veggie"},
  # %{"color" => "#de694a", "dish" => "Lasagne Bolognaise",
  # "name" => "Pasta bar"},
  # %{"color" => "#6c4c42", "dish" => "Wintergroentewok met volle rijst",
  # "name" => "Wok"}]}
  #
  # becomes
  #
  # "Soep: Kervelsoep - Menu 1: Cordon Bleu met erwtjes en worteltjes -
  # Menu 2: Ovenschotel met kippengehakt, appelmoes en aardappelblokjes -
  # Vis: Tongrolletjes met spinazie en Nantua saus - Veggie: Groentekrustie met
  # bloemkool in kaassaus - Pasta bar: Lasagne Bolognaise - Wok: Wintergroentewok
  # met volle rijst"
  defp parse_menu(:nil) do
    :nil
  end

  defp parse_menu(map) do
    map["menus"]
    |> Enum.map(fn(m) -> "_*#{m["name"]}*_: #{m["dish"]}" end)
    |> Enum.join(" - ")
  end
end
