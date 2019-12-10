defmodule FunboxAwesomeElixir.Controller do
  alias FunboxAwesomeElixir.{Parser, Persister, Updater}
  use GenServer
  require Logger

  @readme_source_url [Application.get_env(:funbox_awesome_elixir, :readme_host), "/h4cc/awesome-elixir/master/README.md"] |> Enum.join("")
  @readme_destination_file Application.get_env(:funbox_awesome_elixir, :readme_destination_file)
  @update_interval Application.get_env(:funbox_awesome_elixir, :update_interval)

  def start_link(state \\ %{}) do
    GenServer.start_link(__MODULE__, state, name: :controller)
  end

  def init(_) do
    state = %{ready_data: [], last_update: nil}

    {ready_data, last_update} = Persister.get_app_state

    state = state
      |> Map.put(:ready_data, ready_data)
      |> Map.put(:last_update, last_update)

    {:ok, state}
  end

  def get_ready_data do
    GenServer.call(:controller, :get_ready_data)
  end

  def update_data do
    Process.send(:controller, :update_data, [:noconnect])
  end

  def reset_state do
    GenServer.call(:controller, :reset_state)
  end

  def handle_info({:repos_updated, repos}, _state) do
    meta = %{last_update: DateTime.utc_now}
    state = Map.merge(meta, %{ready_data: repos})
    Persister.save_app_state(repos, meta)

    {:noreply, state}
  end

  def handle_info(:update_data, state) do
    last_update = state[:last_update]

    now = DateTime.utc_now
    last_update = if last_update == nil do
      now |> DateTime.add(-@update_interval * 2, :second)
    else
      last_update
    end

    sec_since_last_update = DateTime.diff(last_update, now) |> abs()
    if sec_since_last_update >= @update_interval do
      Logger.warn("Repos update started")
      download_markdown() |> Parser.parse() |> Updater.update_repos

      Process.send_after(self(), :update_data, @update_interval * 1000)
    else
      seconds_remain = @update_interval - sec_since_last_update
      Logger.warn("Not enough time passed since last update. Next update will be initiated after #{seconds_remain} seconds")
      Process.send_after(self(), :update_data, seconds_remain * 1000)
    end

    {:noreply, state}
  end

  def handle_call(:get_ready_data, _from, state) do
    {:reply, state.ready_data, state}
  end

  def handle_call(:reset_state, _from, _state) do
    new_state = %{ready_data: [], last_update: nil}
    {:reply, new_state, new_state}
  end

  defp download_markdown do
    case HTTPoison.get(@readme_source_url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        File.rm(@readme_destination_file)
        File.write!(@readme_destination_file, body)
        body
    end
  end
end
