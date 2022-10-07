import Config

config :logger,
  level: :debug

url = "<turn_url>"

config :xtools,
  listen: [
    # "udp://#{url}:80",
    # "tcp://#{url}:80",
    "udp://#{url}:3478",
    "tcp://#{url}:3478"
    "udp://#{url}:443",
    "tcp://#{url}:443",
    "udp://#{url}:5349",
    "tcp://#{url}:5349"
  ],
  turn_key: "<secret_key>",
  local_ip: {192, 168, 1, 194},
  local_port: 51000,
  remote_ip: {147, 185, 221, 211},
  remote_port: 14580,
  pipes: [
    XTools.Actions.Binding,
    XTools.Actions.Allocate,
    XTools.Actions.CreatePerm,
    XTools.Actions.Indication,
    XTools.Actions.ChannelBind,
    XTools.Actions.ChannelData
  ]

if Mix.env() == "dev" do
  config :peerage,
    via: Peerage.Via.List,
    node_list: [:"xturn@0.0.0.0"],
    log_results: false
end
