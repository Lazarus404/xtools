defmodule XTools.Actions.ChannelBind do
  alias XTools.Stun
  require Logger
  alias XTools.Auth

  @tid 123_456_789_012
  @channel_number 0x4000

  def run(%{xor_peer_address: xpa, username: username, nonce: nonce, realm: realm})
      when not is_nil(nonce) do
    key = Auth.authenticate(username, realm)

    {Stun.encode(%Stun{
       class: :request,
       method: :channelbind,
       transactionid: @tid,
       key: key,
       attrs: %{
         username: username,
         nonce: nonce,
         realm: realm,
         xor_peer_address: xpa,
         channel_number: <<@channel_number::16, 0::16>>
       }
     }), key}
  end

  def resolve(msg, key) do
    case Stun.decode(msg, key) do
      {:ok,
       %XTools.Stun{
         class: :success,
         method: :channelbind,
         transactionid: @tid,
         fingerprint: true,
         attrs: %{message_integrity: _}
       }} ->
        {:ok, %{}}

      _ ->
        :error
    end
  end
end
