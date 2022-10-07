defmodule XtoolsTest do
  use ExUnit.Case
  doctest Xtools

  test "greets the world" do
    assert Xtools.hello() == :world
  end
end
