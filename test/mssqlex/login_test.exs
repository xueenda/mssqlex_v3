defmodule MssqlexV3.LoginTest do
  use ExUnit.Case, async: false

  alias MssqlexV3.Result, as: R
  import MssqlexV3.TestHelper
  import ExUnit.CaptureLog

  @check_encryption """
  SELECT encrypt_option
  FROM sys.dm_exec_connections
  WHERE session_id = @@SPID
  """

  test "Given valid details, connects to database" do
    {:ok, pid} = MssqlexV3.start_link(MssqlexV3.TestHelper.default_opts)

    assert %R{columns: [""], num_rows: 1, rows: [["test"]]} ==
      MssqlexV3.query!(pid, "SELECT 'test'", [])
  end

  test "connects with encryption" do
    conn_opts = 
      default_opts()
      |> Keyword.put(:encrypt, true)
      |> Keyword.put(:trust_server_certificate, true)
    {:ok, pid} = MssqlexV3.start_link(conn_opts)

    assert %R{num_rows: 1, rows: [["TRUE"]], columns: ["encrypt_option"]} ==
      MssqlexV3.query!(pid, @check_encryption, [])
  end

  test "Given invalid details, errors" do
    error_msg = "28000 (invalid_authorization_specification)"

    conn_opts = 
      default_opts()
      |> Keyword.put(:password, "badpass")

    assert capture_log(fn ->
      {:ok, _pid} = MssqlexV3.start_link(conn_opts)
      :timer.sleep(200)
    end) =~ error_msg
  end
end
