defmodule FunboxAwesomeElixirWeb.PageController do
  use FunboxAwesomeElixirWeb, :controller
  alias FunboxAwesomeElixir.Controller

  def index(conn, params) do
    data = Controller.get_ready_data()

    min_stars = Map.get(params, "min_stars")

    data =
    if min_stars do
      data
        |> Stream.reject(&is_nil(&1[:stars]))
        |> Stream.filter(fn repo -> repo[:stars] >= String.to_integer(min_stars) end)
    else
      data
    end

    data = data
      |> Enum.group_by(&(&1[:category]))
      |> Enum.sort
      |> Enum.map(fn {category, repos} -> {category, Enum.at(repos, 1)[:category_description], repos} end)

    render(conn, "index.html", data: data)
  end
end
