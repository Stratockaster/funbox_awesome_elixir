defmodule FunboxAwesomeElixir.Parser do
  def parse(markdown) do
    String.split(markdown, "\n")
    |> Enum.filter(fn line ->
      is_repo?(line) or
      is_description?(line) or
      is_category?(line)
    end)
    |> Enum.chunk_while([], fn line, acc ->
      if is_category?(line) do
        {:cont, Enum.reverse(acc), [line]}
      else
        {:cont, [line | acc]}
      end
    end, fn acc -> {:cont, Enum.reverse(acc), []} end)
    |> Enum.drop(1) # first dummy list
    |> Enum.flat_map(fn item ->
      [category, category_description | repos] = item
      category = String.slice(category, 3..-1)
      category_description = String.slice(category_description, 1..-2)

      repos |> Enum.map(fn repo ->
        [name_with_url, description] = String.split(repo, ") - ", parts: 2)
        [name, url] = name_with_url |> String.slice(3..-1) |> String.split("](")

        %{
          id: UUID.uuid4(),
          name: name,
          url: url |> String.trim_trailing("/"),
          description: description,
          category: category,
          category_description: category_description
        }
      end)
    end)
  end

  def test do

  end

  defp is_repo?(line) do
    String.starts_with?(line, "* ") and String.contains?(line, ["](http"])
  end
  defp is_description?(line) do
    String.starts_with?(line, "*") and String.ends_with?(line, "*")
  end
  defp is_category?(line) do
    String.starts_with?(line, ["## "])
  end
end
