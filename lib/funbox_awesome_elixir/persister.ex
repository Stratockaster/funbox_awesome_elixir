defmodule FunboxAwesomeElixir.Persister do
  use GenServer

  @ready_data Application.get_env(:funbox_awesome_elixir, :ready_data_file)
  @meta Application.get_env(:funbox_awesome_elixir, :meta_file)

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: :persister)
  end

  def init(state) do
    {:ok, state}
  end

  def save_app_state(data, meta) do
    GenServer.cast(:persister, {:save_app_state, data, meta})
  end

  def get_app_state do
    GenServer.call(:persister, :get_app_state)
  end

  def handle_cast({:save_app_state, data, meta}, state) do
    File.rm(@ready_data)
    File.write!(@ready_data, Jason.encode!(data))
    File.rm(@meta)
    File.write!(@meta, Jason.encode!(meta))

    {:noreply, state}
  end

  def handle_call(:get_app_state, _from, state) do
    ready_data = if File.exists?(@ready_data) do
      @ready_data |> File.read! |> Jason.decode! |> Enum.map(fn repo -> atomic_map(repo) end)
    else
      []
    end

    last_update = if File.exists?(@meta) do
      {:ok, last_update, _} = @meta |> File.read! |> Jason.decode! |> Map.get("last_update") |> DateTime.from_iso8601
      last_update
    else
      nil
    end

    {:reply, {ready_data, last_update}, state}
  end

  defp atomic_map(map) do
    Map.new(map, fn {k, v} -> {String.to_atom(k), v} end)
  end
end
