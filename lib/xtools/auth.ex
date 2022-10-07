defmodule XTools.Auth do
  def authenticate(username, realm) do
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
