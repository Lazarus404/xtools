defmodule XTools.Actions.ChannelData do
  alias XTools.Stun
  require Logger

  @tid 123_456_789_012
  @data "1234567890"
  @channel_number 0x4000

  def run(%{uri: uri, xor_peer_address: xpa, username: username, nonce: nonce, realm: realm})
      when not is_nil(nonce) do
    len = byte_size(@data)
    {build_channel_data(@data, @channel_number, uri.scheme), nil}
  end

  def resolve(msg, _) do
    case msg do
      <<@channel_number::16, len::16, data::binary-size(len), _padding::binary>>
      when data == @data ->
        {:ok, %{}}

      _ ->
        :error
    end
  end

  defp build_channel_data(packet, channel_number, proto) do
    len = byte_size(packet)
    # we need to pad if TCP is used by the client
    if 0 == rem(len, 4) or :udp == proto do
      <<channel_number::16, len::16>> <> packet
    else
      padding_bytes = (4 - rem(len, 4)) * 8
      <<channel_number::16, len::16>> <> packet <> <<0::size(padding_bytes)>>
    end
  end
end
