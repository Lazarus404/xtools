defmodule XTools.SockPeer do
  @moduledoc """
  TURN peer
  """
  use GenServer
  require Logger

  @ip Application.get_env(:xtools, :local_ip, {0, 0, 0, 0})
  @port Application.get_env(:xtools, :local_port, 51000)
  @rip Application.get_env(:xtools, :remote_ip, {0, 0, 0, 0})
  @rport Application.get_env(:xtools, :remote_port, 51000)
  @channel_number 0x4000
  @data "1234567890"

  #####
  # External API

  @doc """
  Standard OTP module startup
  """
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    Logger.debug("Peer init")

    {:ok, socket} =
      :gen_udp.open(@port, [
        {:ip, @ip},
        {:active, :once},
        {:buffer, 1024 * 1024 * 1024},
        {:recbuf, 1024 * 1024 * 1024},
        {:sndbuf, 1024 * 1024 * 1024},
        :binary
      ])

    :ok = Socket.packet!(socket, :raw)
    Socket.Protocol.options(socket, mode: :once)
    {:ok, %{socket: socket, address: {@rip, @rport}}}
  end

  def handle_call(:get_address, _from, %{address: address} = state), do: {:reply, address, state}

  def handle_call(:get_socket, _from, %{socket: socket} = state), do: {:reply, socket, state}

  # peer connection
  def handle_info(
        {:udp, socket, ip, port, <<@channel_number::16, len::16, @data::binary>> = packet},
        %{
          socket: socket
        } = state
      ) do
    Logger.info("[peer] channel data received on peer socket")
    Socket.Protocol.options(socket, mode: :once)
    ^len = byte_size(@data)
    :gen_udp.send(socket, ip, port, packet)
    {:noreply, state}
  end

  def handle_info(
        {:udp, socket, ip, port, "1234567890" = packet},
        %{
          socket: socket
        } = state
      ) do
    Logger.info("[peer] data received on peer socket")
    Socket.Protocol.options(socket, mode: :once)
    :gen_udp.send(socket, ip, port, packet)
    {:noreply, state}
  end

  def handle_info(
        {:udp, socket, ip, port, packet},
        %{
          socket: socket
        } = state
      ) do
    Logger.info("[peer] unknown data received on peer socket #{inspect(packet)}")
    Socket.Protocol.options(socket, mode: :once)
    {:noreply, state}
  end

  def handle_info(
        info,
        %{
          socket: socket
        } = state
      ) do
    Logger.info("[peer] data received on peer socket #{inspect(info)}")
    Socket.Protocol.options(socket, mode: :once)
    {:noreply, state}
  end

  def terminate(reason, state) do
    Logger.info("[peer] TCP client closed: #{inspect(reason)}")
    :ok
  end
end
