defmodule XTools.Actions.Indication do
  alias XTools.Stun
  require Logger

  @tid 123_456_789_012
  @data "1234567890"
  @rip Application.get_env(:xtools, :remote_ip, {0, 0, 0, 0})
  @rport Application.get_env(:xtools, :remote_port, 51000)

  def run(%{xor_peer_address: xpa, username: username, nonce: nonce, realm: realm}) do
    Stun.encode(%Stun{
      class: :indication,
      method: :send,
      transactionid: @tid,
      attrs: %{data: @data, xor_peer_address: xpa}
    })
  end

  def resolve(msg) do
    case Stun.decode(msg) do
      {:ok,
        %XTools.Stun{
          class: :indication,
          method: :data,
          transactionid: _,
          fingerprint: true,
          attrs: %{
            data: @data,
            xor_peer_address: {@rip, @rport}
          }
        }} ->
        {:ok, %{}}

      _ ->
        :error
    end
  end
end
