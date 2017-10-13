# Это точка входа в приложение.
defmodule KVstore do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    children = [
      Plug.Adapters.Cowboy.child_spec(:http, KVstore.Router, []),
      worker(KVstore.Storage, [])
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
