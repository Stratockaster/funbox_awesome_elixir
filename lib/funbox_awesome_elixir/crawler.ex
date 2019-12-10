defmodule FunboxAwesomeElixir.Crawler do
  use GenServer

  @wait_between_requests Application.get_env(:funbox_awesome_elixir, :wait_between_requests)

  def start do
    GenServer.start(__MODULE__, [], name: :crawler)
  end

  def init(init) do
    {:ok, init}
  end

  def crawl_repos(pid, repos) do
    GenServer.cast(pid, {:crawl, repos})
  end

  def handle_cast({:crawl, repos}, state) do
    crawl(repos)
    {:noreply, state}
  end

  def crawl([]), do: Process.exit(self(), :normal)
  def crawl([repo | remaining_repos]) do
    :timer.sleep(@wait_between_requests)

    {stars, days} = query_external_data(repo)

    repo_with_info = repo
      |> Map.put(:stars, stars)
      |> Map.put(:days, days)

    send(:updater, {:repo_crawled, repo_with_info})
    crawl(remaining_repos)
  end

  def query_external_data(repo) do
    if String.contains?(repo[:url], "https://github.com") do
      "https://github.com/" <> owner_with_name = repo[:url] # <- https://github.com/tsloughter/rebar3_run
      [owner, repo_name] = String.split(owner_with_name, "/") |> Enum.take(2)

      HTTPoison.start
      token = Application.get_env(:funbox_awesome_elixir, :github_token)
      endpoint = Application.get_env(:funbox_awesome_elixir, :github_api_url) <> "/repos"
      headers = ["Authorization": "token #{token}", "Accept": "Application/json; Charset=utf-8"]
      options = [ssl: [{:versions, [:'tlsv1.2']}], recv_timeout: 1000]

      url = [endpoint, owner, repo_name] |> Enum.join("/")
      stars = query_stars(url, headers, options)

      url = [endpoint, owner, repo_name, "commits", "master"] |> Enum.join("/")
      last_commit_date = query_last_commit_date(url, headers, options)
      {:ok, now} = DateTime.now("Etc/UTC")

      days_since_last_commit =
      if last_commit_date == nil do
        nil
      else
        Float.floor(abs(DateTime.diff(last_commit_date, now)) / 60 / 60 / 24) |> Kernel.trunc
      end

      {stars, days_since_last_commit}
    else
      {nil, nil}
    end
  end

  def query_stars(url, headers, options) do
    case HTTPoison.get(url, headers, options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        external_repo_data = Jason.decode!(body)
        external_repo_data["stargazers_count"]
      {:ok, %HTTPoison.Response{status_code: 301, headers: response_headers}} ->
        {"Location", url} = response_headers |> Enum.find(fn {h_name, _h_value} -> h_name == "Location" end)
        query_stars(url, headers, options)
      {:ok, _} -> nil
      {:error, _} -> nil
    end
  end

  def query_last_commit_date(url, headers, options) do
    case HTTPoison.get(url, headers, options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        external_commit_data = Jason.decode!(body)
        last_commit_date_string = external_commit_data["commit"]["author"]["date"]
        {:ok, last_commit_date, 0} = DateTime.from_iso8601(last_commit_date_string) # <- 2016-08-22T03:29:58Z
        last_commit_date
      {:ok, %HTTPoison.Response{status_code: 301, headers: response_headers}} ->
        {"Location", url} = response_headers |> Enum.find(fn {h_name, _h_value} -> h_name == "Location" end)
        query_last_commit_date(url, headers, options)
      {:ok, _} -> nil
      {:error, _} -> nil
    end
  end
end
