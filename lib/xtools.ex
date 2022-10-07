defmodule XTools do
  @moduledoc """
  Application stub, used to parent TURN connections supervisor
  """
  use Application
  require Logger

  def start(_type, args) do
    XTools.Supervisor.start_link(Application.get_env(:xtools, :listen))
  end

  def main(argv) do
    main(argv)
  end
end
