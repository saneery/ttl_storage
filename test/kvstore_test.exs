# Тестируем как можно больше кейсов.
defmodule KVstore.Test do
  use ExUnit.Case
  use Plug.Test

  @table Application.get_env(:kvstore, :dets_name)

  alias KVstore.{Router, Storage}

  setup do
    :dets.delete_all_objects(@table)
  end

  @opts Router.init([])

  describe "Create" do
    test "new data" do
      conn = conn(:post, "/create", "key=name&value=elixir")
        |> put_req_header("content-type", "application/x-www-form-urlencoded")
        |> Router.call(@opts)

      assert conn.status == 201
    end

    test "exist data" do
      Storage.create("lang", "erlang")

      conn = conn(:post, "/create", "key=lang&value=erlang")
        |> put_req_header("content-type", "application/x-www-form-urlencoded")
        |> Router.call(@opts)

      assert conn.status == 400
    end
  end

  describe "Read" do
    test "new data" do
      data = %{"key" => "pi", "value" => "3.14"}
      Storage.create(data["key"], data["value"])
      conn = conn(:get, "/read/pi", "")
        |> Router.call(@opts)

      assert conn.status == 200
      assert conn.resp_body == "{key: #{data["key"]}, value: #{data["value"]}}"
    end

    test "expirated data" do
      expiration = :os.system_time(:millisecond) + :timer.seconds(1)
      :dets.insert_new(@table, {"city", "new-york", expiration})
      Process.sleep(:timer.seconds(2))

      conn = conn(:get, "/read/city", "")
        |> Router.call(@opts)

      assert conn.status == 404
    end
  end

  describe "Update" do
    test "exist data" do
      Storage.create("phone", "5553535")
      conn = conn(:put, "/update", "key=phone&value=44444")
        |> put_req_header("content-type", "application/x-www-form-urlencoded")
        |> Router.call(@opts)

      assert conn.status == 200
    end

    test "not exist data" do
      conn = conn(:put, "/update", "key=ip&value=192.168.0.1")
        |> put_req_header("content-type", "application/x-www-form-urlencoded")
        |> Router.call(@opts)

      assert conn.status == 404
    end
  end

  test "Delete" do
    Storage.create("port", "4000")
    conn = conn(:delete, "/delete/port", "")
      |> Router.call(@opts)

    assert conn.status == 200
  end
end
