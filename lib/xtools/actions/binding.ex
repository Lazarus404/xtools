defmodule XTools.Actions.Binding do
  alias XTools.Stun
  require Logger

  @tid 123_456_789_012

  def run(_state) do
    Stun.encode(%Stun{
      class: :request,
      method: :binding,
      transactionid: @tid
    })
  end

  def resolve(msg) do
    case Stun.decode(msg) do
      {:ok,
       %XTools.Stun{
         class: :success,
         method: :binding,
         transactionid: @tid,
         integrity: false,
         key: nil,
         fingerprint: true,
         attrs: %{mapped_address: {m_ip, m_port}, xor_mapped_address: {xm_ip, xm_port}}
       }} ->
        {:ok, %{mapped_address: {m_ip, m_port}, xor_mapped_address: {xm_ip, xm_port}}}

      _ ->
        :error
    end
  end
end
