defmodule Bot.ChuckNorris do
  use Plugin
  require Logger
  @url 'http://api.icndb.com/jokes/random'

  def on_message(<<"joke?"::utf8, _::bitstring>>, _channel) do
    j = joke()
    case j do
      {:error, e} -> IO.puts "Error getting joke #{e}"
                     {:noreply}
      {:ok, text} -> {:ok, "#{text}"}
    end
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
  def joke() do
    # Get the data from the webservcer.
    with {:ok, data} <- get_data(),
         {:ok, joke} <- extract_text(data)
    do
      {:ok, joke}
    else
      err -> {:error, err}
    end
  end

  defp get_data() do
    {:ok, {{_, 200, 'OK'}, _, body}} = :httpc.request(:get, {@url, []}, [], [body_format: :binary])
    Poison.decode(body) # = {:ok, joke}
  end

  defp extract_text(%{"value" => %{"joke" => text}}) do
    {:ok, text}
  end
  defp extract_text(_), do: {:error, "Can not parse response"}
end
