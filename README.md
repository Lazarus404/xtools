# XTools

XTools is an Elixir built TURN server testing tool.  It performs each of the typical processes through a TURN server on several ports simultaneously, ensuring your TURN configuration is correct and useable.

## Running

No effort has been carried out to make this release'able.  To run, simply call;

```elixir
> iex -S mix
```

Note that you'll need to enable port tunnelling for the send indication and channel data messages to echo back through the TURN server.  To do this, I use [PlayIt.GG](https://playit.gg/).  It's very simple to use.  Once running, update the `remote_ip` and `remote_port` in the `confix.exs` file.  Also, make sure to correctly set the `local_ip` and `local_port` in the config for local socket bindings.
