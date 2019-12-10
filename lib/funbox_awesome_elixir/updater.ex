defmodule FunboxAwesomeElixir.Updater do
  use GenServer
  require Logger
  alias FunboxAwesomeElixir.Crawler

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: :updater)
  end

  def init(_) do
    state = %{
      pending: [],
      done: []
    }

    {:ok, state}
  end

  def done_repos do
    GenServer.call(:updater, :done_repos)
  end

  def update_repos(repos) do
    GenServer.cast(:updater, {:update_repos, repos})
  end

  def handle_cast({:update_repos, repos}, state) do
    state = %{state | pending: repos}

    {:ok, crawler} = Crawler.start
    Logger.info("Crawler started")
    Process.monitor(crawler)
    ProgressBar.render(0, Enum.count(state.pending))
    Crawler.crawl_repos(crawler, state.pending)
    {:noreply, state}
  end

  def handle_call(:done_repos, _from, state) do
    {:reply, state.done, state}
  end

  def handle_info({:repo_crawled, repo}, state) do
    new_pending = Enum.reject(state.pending, &(&1[:id] == repo[:id]))
    new_done = [repo | state.done]

    ProgressBar.render(Enum.count(state.done), Enum.count(state.pending) + Enum.count(state.done))

    new_state = %{pending: new_pending, done: new_done}
    {:noreply, new_state}
  end

  def handle_info({:DOWN, _ref, :process, crawler, :normal}, state) do
    Logger.info("Crawler #{inspect crawler} completed all jobs and terminated.")

    send(:controller, {:repos_updated, state.done})

    {:noreply, %{pending: [], done: []}}
  end

  def handle_info({:DOWN, _ref, :process, crawler, reason}, state) do
    Logger.info("Crawler #{inspect crawler} went down, info: #{inspect reason}")

    update_repos(state.pending)
    {:noreply, state}
  end
end
