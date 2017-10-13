# Этот модуль должен реализовать механизмы CRUD для хранения данных. Если одного модуля будет мало, то допускается создание модулей с префиксом "Storage" в названии.
defmodule KVstore.Storage do
  use GenServer

  @table Application.get_env(:kvstore, :dets_name)
  @ttl :timer.minutes(1)

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def create(key, value) do
    expiration = :os.system_time(:millisecond) + @ttl
    case :dets.insert_new(@table, {key, value, expiration}) do
      false ->
        {:error, "value with this key exist"}
      true ->
        {:ok, {key, value}}
    end
  end

  def read(key) do
    case :dets.lookup(@table, key) do
      [result| _] -> check_exp(result)
      [] -> nil
    end
  end

  def update(key, value) do
    case :dets.lookup(@table, key) do
      [result| _] ->
        case check_exp(result) do
          nil ->
            nil
          {key, _} ->
            expiration = :os.system_time(:millisecond) + @ttl
            :dets.insert(@table, {key, value, expiration})
            {:ok, {key, value}}
        end
      [] ->
        nil
    end
  end

  def delete(key) do
    case :dets.delete(@table, key) do
      :ok ->
        :ok
      _ ->
        :error
    end
  end

  def check_exp({key, value, exp}) do
    cond do
      exp > :os.system_time(:millisecond) -> {key, value}
      :else ->
        :dets.delete(@table, key)
        nil
    end
  end

  def init(_) do
    {:ok, table} = :dets.open_file(@table, [type: :set])
  end

  def terminate(_, _) do
    :dets.close(@table)
    :normal
  end
end
