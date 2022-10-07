defmodule XTools.Actions.Allocate do
  alias XTools.Stun
  require Logger
  alias XTools.Auth

  @tid 123_456_789_012

  def run(%{username: username, nonce: nonce, realm: realm}) when not is_nil(nonce) do
    key = Auth.authenticate(username, realm)

    {Stun.encode(%Stun{
       class: :request,
       method: :allocate,
       key: key,
       attrs: %{
         nonce: nonce,
         realm: realm,
         requested_transport: <<17, 0, 0, 0>>,
         username: username
       },
       fingerprint: false,
       transactionid: @tid
     }), key}
  end

  def run(_) do
    {Stun.encode(%Stun{
       class: :request,
       method: :allocate,
       transactionid: @tid
     }), nil}
  end

  def resolve(msg, key) do
    case Stun.decode(msg) do
      {:ok,
       %XTools.Stun{
         class: :error,
         method: :allocate,
         transactionid: @tid,
         integrity: false,
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
         fingerprint: true,
         attrs: %{
           lifetime: <<0, 0, 2, 88>>,
           xor_mapped_address: {xm_ip, xm_port},
           xor_relayed_address: {xr_ip, xr_port},
           message_integrity: _
         }
       }} ->
        {:ok,
         %XTools.Stun{
           class: :success,
           method: :allocate,
           transactionid: @tid,
           integrity: true,
           key: key,
           fingerprint: true,
           attrs: %{
             lifetime: <<0, 0, 2, 88>>,
             xor_mapped_address: {xm_ip, xm_port},
             xor_relayed_address: {xr_ip, xr_port}
           }
         }} = Stun.decode(msg, key)

        {:ok, %{xor_mapped_address: {xm_ip, xm_port}, xor_relayed_address: {xr_ip, xr_port}}}

      e ->
        Logger.debug("#{inspect(e)}")
        :error
    end
  end
end
