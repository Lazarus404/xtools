defmodule XTools.SockImpl do
  use GenServer
  use Bitwise
  require Logger

  alias XTools.SockPeer

  @stun_magic_cookie 0x2112A442
  @buf_size 1024 * 1024 * 16
  @stack_delay 1000

  @doc """
  Standard OTP module startup
  """
  def start_link(url) do
    GenServer.start_link(__MODULE__, [url])
  end

  @doc """
  Initialises connection
  """
  def init([url]) do
    with %URI{} = uri <- URI.parse(url),
         {:ok, socket} <- connect(uri),
         :ok <- Socket.packet!(socket, :raw),
         :ok <- Socket.Protocol.options(socket, mode: :once),
         peer <- Process.whereis(SockPeer),
         true <- Process.alive?(peer),
         {pip, pport} <- GenServer.call(peer, :get_address),
         {ms, s, _us} <- :erlang.timestamp(),
         ts <- ms * 1_000_000 + s,
         username <- "#{ts + 86400}:#{UUID.uuid1()}" do
      Process.flag(:trap_exit, true)

      {:ok,
       %{
         socket: socket,
         key: nil,
         turn_state: %{
           uri: uri,
           username: username,
           xor_peer_address: {pip, pport}
         },
         actions: Application.get_env(:xtools, :pipes)
       }, 0}
    else
      _ ->
        Logger.debug("could not open socket on #{url}")
        {:stop, :normal}
    end
  end

  def handle_info(
        :timeout,
        %{
          socket: socket,
          actions: [],
          turn_state: %{
            uri: uri
          }
        } = state
      ) do
    Socket.Protocol.close(socket)
    Logger.info("Task list complete for #{to_string(uri)}")
    {:stop, :shutdown, state}
  end

  def handle_info(
        :timeout,
        %{
          socket: socket,
          turn_state: %{uri: uri} = turn_state,
          actions: [action | _]
        } = state
      ) do
    Logger.debug("calling run on #{inspect(action)}")
    {res, key} = action.run(turn_state)
    state = if not is_nil(key), do: Map.put(state, :key, key), else: state
    send(socket, uri, res)
    {:noreply, state, @stack_delay}
  end

  # client UDP connection handler
  def handle_info(
        {:udp, socket, ip, port, packet},
        %{
          socket: socket,
          key: key,
          turn_state: turn_state,
          actions: [action | rest]
        } = state
      ) do
    Logger.debug("calling resolve for #{inspect(action)}")
    Socket.Protocol.options(socket, mode: :once)

    with {:ok, resp} <- action.resolve(packet, key) do
      {:noreply, %{state | turn_state: Map.merge(turn_state, resp), actions: rest}, @stack_delay}
    else
      {:error, new_state} ->
        {:noreply, %{state | turn_state: Map.merge(turn_state, new_state)}, @stack_delay}

      :error ->
        {:noreply, state, @stack_delay}
    end
  end

  # client TCP connection handler
  def handle_info(
        {:tcp, socket, packet},
        %{
          socket: socket,
          key: key,
          turn_state: turn_state,
          actions: [action | rest]
        } = state
      ) do
    Logger.debug("calling resolve for #{inspect(action)}")
    Socket.Protocol.options(socket, mode: :once)

    with {:ok, resp} <- action.resolve(packet, key) do
      {:noreply, %{state | turn_state: Map.merge(turn_state, resp), actions: rest}, @stack_delay}
    else
      {:error, new_state} ->
        {:noreply, %{state | turn_state: Map.merge(turn_state, new_state)}, @stack_delay}

      :error ->
        {:noreply, state, @stack_delay}
    end
  end

  def handle_info(info, state) do
    Logger.debug("#{inspect(info)}")
    {:noreply, state, @stack_delay}
  end

  def terminate(reason, state) do
    Logger.debug("#{inspect(reason)}")
    {:stop, state}
  end

  defp connect(%URI{scheme: "udp"}) do
    Socket.UDP.open()
  end

  defp connect(url) do
    Socket.connect(url)
  end

  defp send(socket, %URI{scheme: "udp", host: host, port: port}, msg) do
    :gen_udp.send(socket, to_charlist(host), port, msg)
  end

  defp send(socket, _, msg) do
    :gen_tcp.send(socket, msg)
  end
end
