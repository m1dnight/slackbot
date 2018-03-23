defmodule Bot.ChuckNorris do
  use Plugin
  require Logger
  @url 'http://api.icndb.com/jokes/random'

  def on_message(<<"joke?"::utf8, _::bitstring>>, _channel, _from) do
    j = joke()

    case j do
      {:error, e} ->
        IO.puts("Error getting joke #{e}")
        {:noreply}

      {:ok, text} ->
        {:ok, "#{text}"}
    end
  end

  def on_message(_m, _channel, _from) do
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
         {:ok, joke} <- extract_text(data),
         decoded <- HtmlEntities.decode(joke) do
      {:ok, decoded}
    else
      err -> {:error, err}
    end
  end

  defp get_data() do
    {:ok, {{_, 200, 'OK'}, _, body}} = :httpc.request(:get, {@url, []}, [], body_format: :binary)
    # = {:ok, joke}
    Poison.decode(body)
  end

  defp extract_text(%{"value" => %{"joke" => text}}) do
    {:ok, text}
  end

  defp extract_text(_), do: {:error, "Can not parse response"}
end
