defmodule XTools.Actions.CreatePerm do
  alias XTools.Stun
  require Logger
  alias XTools.Auth

  @tid 123_456_789_012

  def run(%{xor_peer_address: xpa, username: username, nonce: nonce, realm: realm})
      when not is_nil(nonce) do
    key = Auth.authenticate(username, realm)

    {Stun.encode(%Stun{
       class: :request,
       method: :createperm,
       transactionid: @tid,
       key: key,
       attrs: %{username: username, nonce: nonce, realm: realm, xor_peer_address: xpa}
     }), key}
  end

  def resolve(msg, key) do
    case Stun.decode(msg, key) do
      {:ok,
       %XTools.Stun{
         class: :success,
         method: :createperm,
         transactionid: @tid,
         key: key,
         integrity: true,
         fingerprint: true,
         attrs: %{
           nonce: _,
           realm: _,
           username: _,
           xor_peer_address: {{192, 168, 1, 194}, 51000}
         }
       }} ->
        {:ok, %{}}

      _ ->
        :error
    end
  end
end
