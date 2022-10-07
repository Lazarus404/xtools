defmodule XTools.Supervisor do
  use Supervisor
  require Logger

  alias XTools.{SockImpl, SockPeer}

  def start_link(listen) do
    Supervisor.start_link(__MODULE__, [listen], name: __MODULE__)
  end

  def init([listen]) do
    children =
      listen
      |> Enum.map(fn data ->
        start_listener(data)
      end)
      |> Enum.reject(&is_nil/1)

    Supervisor.init(
      [
        worker(SockPeer, [])
      ] ++ children,
      strategy: :one_for_one
    )
  end

  defp start_listener(url) do
    try do
      worker(SockImpl, [url], id: url, restart: :transient)
    rescue
      e ->
        nil
    end
  end

  defp terminate(reason, state) do
    state
  end
end
