defmodule Xtools.MixProject do
  use Mix.Project

  def project do
    [
      app: :xtools,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      applications: [:sasl, :logger, :ssl, :xmerl, :socket],
      extra_applications: [:crypto],
      registered: [XTools.Server],
      mod: {XTools, []},
      logger: [compile_time_purge_level: :debug],
      env: [
        node_name: "xtools",
        node_host: "localhost",
        cookie: :IAMACOOKIEMONSTER
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:uuid, "~> 1.1"},
      {:socket, github: "Lazarus404/elixir-socket"}
    ]
  end
end
