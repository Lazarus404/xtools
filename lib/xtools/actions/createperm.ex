defmodule XTools.Actions.CreatePerm do
  alias XTools.Stun
  require Logger

  @tid 123_456_789_012

  def run(%{xor_peer_address: xpa, username: username, nonce: nonce, realm: realm})
      when not is_nil(nonce) do
    key = authenticate(username, realm)

    Stun.encode(%Stun{
      class: :request,
      method: :createperm,
      transactionid: @tid,
      key: key,
      attrs: %{username: username, nonce: nonce, realm: realm, xor_peer_address: xpa}
    })
  end

  def resolve(msg) do
    case Stun.decode(msg) do
      {:ok, %XTools.Stun{
          class: :success,
          method: :createperm,
          transactionid: @tid,
          fingerprint: true
        }} ->
        {:ok, %{}}

      _ ->
        :error
    end
  end

  defp authenticate(username, realm) do
    key = Application.get_env(:xtools, :turn_key)
    credential = hmac_fun(:sha, key, username) |> Base.encode64()
    key = username <> ":" <> realm <> ":" <> credential
    :crypto.hash(:md5, key)
  end

  if System.otp_release() >= "22" do
    defp hmac_fun(digest, key, message), do: :crypto.mac(:hmac, digest, key, message)
  else
    defp hmac_fun(digest, key, message), do: :crypto.hmac(digest, key, message)
  end
end