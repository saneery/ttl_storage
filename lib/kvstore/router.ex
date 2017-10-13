# Для веб сервера нужен маршрутизатор, место ему именно тут.
defmodule KVstore.Router do
  use Plug.Router
  alias KVstore.Storage

  plug :match
  plug Plug.Parsers, parsers: [:urlencoded]
  plug :dispatch

  post "/create" do
    %{"key" => key, "value" => value} = conn.params
    case Storage.create(key, value) do
      {:error, reason} ->
        conn
        |> send_resp(400, reason)
      {:ok, _} ->
        conn
        |> send_resp(201, "")
    end
  end

  get "/read/:key" do
    case Storage.read(key) do
      nil ->
        conn
        |> send_resp(404, "")
      {key, value} ->
        conn
        |> send_resp(200, "{key: #{key}, value: #{value}}")
    end
  end

  put "/update" do
    %{"key" => key, "value" => value} = conn.params
    case Storage.update(key, value) do
      nil ->
        conn
        |> send_resp(404, "")
      {:ok, _} ->
        conn
        |> send_resp(200, "")
    end
  end

  delete "/delete/:key" do
    case Storage.delete(key) do
      :ok ->
        conn
        |> send_resp(200, "")
      :error ->
        conn
        |> send_resp(422, "")
    end
  end
end
