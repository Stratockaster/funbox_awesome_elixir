defmodule FunboxAwesomeElixirWeb.PageControllerTest do
  use FunboxAwesomeElixirWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Awesome Elixir – Funbox test work"
  end
end
