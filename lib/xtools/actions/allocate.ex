defmodule XTools.Actions.Allocate do
  alias XTools.Stun
  require Logger

  @tid 123_456_789_012
  @username "1665139498077:webrtc"
  @password "4ISAEthhv0iuU7cW7IJn8v7yfnY="

  def run(%{username: username, nonce: nonce, realm: realm}) when not is_nil(nonce) do
    key = authenticate(username, realm)

    Stun.encode(%Stun{
      class: :request,
      method: :allocate,
      key: key,
      attrs: %{nonce: nonce, realm: realm, requested_transport: <<17, 0, 0, 0>>, username: username},
      fingerprint: false,
      transactionid: @tid
    })
  end

  def run(_) do
    Stun.encode(%Stun{
      class: :request,
      method: :allocate,
      transactionid: @tid
    })
  end

  def resolve(msg) do
    case Stun.decode(msg) do
      {:ok,
       %XTools.Stun{
         class: :error,
         method: :allocate,
         transactionid: @tid,
         integrity: false,
         key: nil,
         fingerprint: true,
         attrs: %{error_code: {401, "Unauthorized"}, nonce: nonce, realm: realm}
       }} ->
        {:error, %{nonce: nonce, realm: realm}}

      {:ok,
       %XTools.Stun{
         class: :success,
         method: :allocate,
         transactionid: @tid,
         integrity: false,
         key: nil,
         fingerprint: true,
         attrs: %{
           lifetime: <<0, 0, 2, 88>>,
           xor_mapped_address: {xm_ip, xm_port},
           xor_relayed_address: {xr_ip, xr_port}
         }
       }} ->
        {:ok, %{xor_mapped_address: {xm_ip, xm_port}, xor_relayed_address: {xr_ip, xr_port}}}

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
