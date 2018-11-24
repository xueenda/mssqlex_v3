defmodule MssqlexV3.TransactionTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog
  import MssqlexV3.TestHelper

  alias MssqlexV3.Result, as: R
  alias MssqlexV3.Error, as: E

  setup context do
    {:ok, pid} = MssqlexV3.start_link(default_opts())
    {:ok, [pid: pid, test: context[:test]]}
  end

  test "failing transaction timeout test", %{pid: pid} do
    sleep = fn _ -> :timer.sleep(100) end
    assert capture_log(fn ->
      assert {:error, :rollback} == DBConnection.transaction(pid, sleep, timeout: 0)
    end) =~ "timed out because it queued and checked out the connection for longer than 0ms"
  end

  test "simple transaction test", %{pid: pid} = context do
    result = 
      DBConnection.transaction(pid, fn tr_pid ->
        context = %{pid: tr_pid, test: context[:test]}
        %R{} = query("CREATE TABLE #{table_name()} (name varchar(50))")
        %R{} = query("INSERT INTO #{table_name()} VALUES (?);", ["Steven"])
      end)

    assert {:ok, %R{num_rows: 1}} == result
    assert %R{
      columns: ["name"],
      num_rows: 1,
      rows: [["Steven"]]
    } == query("SELECT * from #{table_name()}")
  end

  test "nested transaction test", %{pid: pid} = context do
    result = 
      DBConnection.transaction(pid, fn tr_main_pid ->
        context = %{pid: tr_main_pid, test: context[:test]}
        %R{} = query("CREATE TABLE #{table_name()} (name varchar(50))")
        %R{} = query("INSERT INTO #{table_name()} VALUES (?)", ["Steven"])

        {:ok, result} =
          DBConnection.transaction(tr_main_pid, fn tr_nested_pid ->
            context = %{pid: tr_nested_pid, test: context[:test]}
            %R{} = query("INSERT INTO #{table_name()} VALUES (?)", ["Jae"])
          end)
        result
      end)

    assert {:ok, %R{num_rows: 1}} == result

    assert %R{
      columns: ["name"],
      num_rows: 2,
      rows: [["Steven"], ["Jae"]]
    } == query("SELECT * from #{table_name()}")
  end

  test "failing transaction test", %{pid: pid} = context do
    {:error, :rollback} = 
      DBConnection.transaction(pid, fn tr_main_pid ->
        context = %{pid: tr_main_pid, test: context[:test]}
        %R{} = query("CREATE TABLE #{table_name()} (name varchar(3))")

        {:ok, result} =
          DBConnection.transaction(tr_main_pid, fn tr_nested_pid ->
            context = %{pid: tr_nested_pid, test: context[:test]}
            %R{} = query("INSERT INTO #{table_name()} VALUES (?)", ["Jae"])
          end)

        DBConnection.transaction(tr_main_pid, fn tr_nested_pid ->
          context = %{pid: tr_nested_pid, test: context[:test]}
          MssqlexV3.query(tr_nested_pid, "INSERT INTO #{table_name()} VALUES (?)", ["Jas"], [])
          MssqlexV3.query(tr_nested_pid, "INSERT INTO #{table_name()} VALUES (?)", ["Steven"], [])
        end)
        result
      end)

    %E{mssql: %{code: code, message: message}} = query("SELECT * from #{table_name()}")
    assert code == :base_table_or_view_not_found
    assert message =~ "Invalid object name"
  end

  test "manual rollback transaction test", %{pid: pid} = context do
    DBConnection.transaction(pid, fn tr_main_pid ->
      context = %{pid: tr_main_pid, test: context[:test]}
      %R{} = query("CREATE TABLE #{table_name()} (name varchar(3))")

      {:ok, _result} =
        DBConnection.transaction(tr_main_pid, fn tr_nested_pid ->
          context = %{pid: tr_nested_pid, test: context[:test]}
          %R{} = query("INSERT INTO #{table_name()} VALUES (?)", ["Jae"])
        end)
      DBConnection.rollback(tr_main_pid, :stop)
    end)

    %E{mssql: %{code: code, message: message}} = query("SELECT * from #{table_name()}")
    assert code == :base_table_or_view_not_found
    assert message =~ "Invalid object name"
  end

  test "Commit savepoint", %{pid: pid} = context do
    {:ok, %R{}} = 
      DBConnection.transaction(pid, fn tr_pid ->
        context = %{pid: tr_pid, test: context[:test]}
        %R{} = query("CREATE TABLE #{table_name()} (name varchar(50))")
        %R{} = query("INSERT INTO #{table_name()} VALUES (?)", ["Steven"])
      end, mode: :savepoint)

    assert %R{columns: ["name"], num_rows: 1, rows: [["Steven"]]} = query("SELECT * from #{table_name()}")
  end

  test "failing savepoint", %{pid: pid} = context do
    assert_raise MssqlexV3.Error, fn ->
      DBConnection.transaction(pid, fn tr_main_pid ->
        context = %{pid: tr_main_pid, test: context[:test]}
        %R{} = query("CREATE TABLE #{table_name()} (name varchar(3))")

        {:ok, _result} =
          DBConnection.transaction(tr_main_pid, fn tr_nested_pid ->
            context = %{pid: tr_nested_pid, test: context[:test]}
            %R{} = query("INSERT INTO #{table_name()} VALUES (?)", ["Jae"])
          end, mode: :savepoint)

        DBConnection.transaction(tr_main_pid, fn tr_nested_pid ->
          %R{} = MssqlexV3.query!(tr_nested_pid, "INSERT INTO #{table_name()} VALUES (?)", ["Steven"])
        end, mode: :savepoint)
      end, mode: :savepoint)
    end

    assert %R{columns: ["name"], num_rows: 1, rows: [["Jae"]]} = query("SELECT * from #{table_name()}")
  end

  test "savepoint inside transaction", %{pid: pid} = context do
    {:ok, %R{}} =
      DBConnection.transaction(pid, fn tr_main_pid ->
        context = %{pid: tr_main_pid, test: context[:test]}
        %R{} = query("CREATE TABLE #{table_name()} (name varchar(3))")

        {:ok, result} =
          DBConnection.transaction(tr_main_pid, fn tr_nested_pid ->
            context = %{pid: tr_nested_pid, test: context[:test]}
            %R{} = query("INSERT INTO #{table_name()} VALUES (?)", ["Tom"])
          end, mode: :savepoint)
        result
      end)

    assert %R{columns: ["name"], num_rows: 1, rows: [["Tom"]]} = query("SELECT * from #{table_name()}")
  end

  test "savepoint rollback", %{pid: pid} = context do
    %R{} = query("CREATE TABLE #{table_name()} (name varchar(3))")

    {:error, :rollback} =
      DBConnection.transaction(pid, fn tr_main_pid ->
        context = %{pid: tr_main_pid, test: context[:test]}
        %R{} = query("INSERT INTO #{table_name()} VALUES (?)", ["Joe"])

        {:error, _} = 
          DBConnection.transaction(tr_main_pid, fn tr_nested_pid ->
            context = %{pid: tr_nested_pid, test: context[:test]}
            %R{} = query("INSERT INTO #{table_name()} VALUES (?)", ["Tom"])
            DBConnection.rollback(tr_nested_pid, "Tom is not so cool!")
          end, mode: :savepoint)
      end)

    assert %R{columns: ["name"], num_rows: 0, rows: []} = query("SELECT * from #{table_name()}")
  end
end
