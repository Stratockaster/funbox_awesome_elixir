defmodule FunboxAwesomeElixir.ControllerTest do
  use ExUnit.Case
  alias FunboxAwesomeElixir.Controller

  @ready_data Application.get_env(:funbox_awesome_elixir, :ready_data_file)
  @meta Application.get_env(:funbox_awesome_elixir, :meta_file)
  @readme_destination_file Application.get_env(:funbox_awesome_elixir, :readme_destination_file)

  setup do
    bypass_readme = Bypass.open(port: 1367)
    bypass_github = Bypass.open(port: 1366)

    Bypass.expect(bypass_readme, "GET", "/h4cc/awesome-elixir/master/README.md", fn conn ->
      response = File.read!("fixtures/README.md")
      Plug.Conn.resp(conn, 200, response)
    end)

    Bypass.expect(bypass_github, fn conn ->
      response = "{\"stargazers_count\": 471, \"commit\": {\"author\": {\"date\": \"2018-01-19T16:11:02Z\"}}}"
      Plug.Conn.resp(conn, 200, response)
    end)

    on_exit fn ->
      File.rm(@ready_data)
      File.rm(@meta)
      File.rm(@readme_destination_file)
    end

    {:ok, bypass_github: bypass_github, bypass_readme: bypass_readme}
  end

  test "Update repos" do
    Controller.reset_state()
    controller_state_before = :sys.get_state(:controller)
    assert Controller.get_ready_data == []
    assert controller_state_before[:last_update] == nil

    Controller.update_data()
    crawler = wait_for(:crawler)
    Process.monitor(crawler)
    assert_receive({:DOWN, _ref, :process, pid, :normal}, 4_000)

    :timer.sleep(200) # wait for controller handles message

    controller_state_after = :sys.get_state(:controller)
    last_update = controller_state_after[:last_update]
    assert last_update != nil
    assert Controller.get_ready_data |> Enum.count > 0
    assert Process.whereis(:crawler) == nil

    # Testing that update rescheduled

    next_crawler = wait_for(:crawler)
    assert next_crawler != crawler
    Process.monitor(next_crawler)
    assert_receive({:DOWN, _ref, :process, pid, :normal}, 4_000)
    assert Process.whereis(:crawler) == nil

    :timer.sleep(200) # wait for controller handles message

    controller_state = :sys.get_state(:controller)
    assert last_update != controller_state[:last_update]
  end

  defp wait_for(proc_name, timeout \\ 5_000) do
    if timeout == 0, do: raise "#{proc_name} did not found"

    pid = Process.whereis(proc_name)

    if pid do
      pid
    else
      step = 10
      :timer.sleep(step)
      wait_for(proc_name, timeout - step)
    end
  end
end
