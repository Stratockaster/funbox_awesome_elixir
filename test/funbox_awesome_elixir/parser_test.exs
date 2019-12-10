defmodule FunboxAwesomeElixir.ParserTest do
  use ExUnit.Case, async: true
  alias FunboxAwesomeElixir.Parser

  setup do
    :ok
  end

  test "Parse data" do
    markdown = File.read!("fixtures/README.md")
    [head | _] = Parser.parse(markdown)
    %{category: category, description: description, name: name, url: url} = head

    assert is_binary(category)
    assert is_binary(description)
    assert is_binary(name)
    assert is_binary(url)
  end
end
