defmodule Mssqlex.StorageTest do
  use ExUnit.Case

  import Mssqlex.TestHelper

  alias Mssqlex.Result, as: R
  alias Mssqlex.NewError, as: E

  @test_db "mssqlex_test_db"

  setup context do
    {:ok, pid} = Mssqlex.start_link(default_opts())
    {:ok, [pid: pid, test: context[:test]]}
  end

  test "Can create and drop db. Return error for existing or dropped db.", context do
    %R{} = query("CREATE DATABASE #{@test_db}")
    assert %E{
      mssql: %{
        code: :syntax_error_or_access_violation,
        driver: nil,
        message: "Database 'mssqlex_test_db' already exists. Choose a different database name.",
        mssql_code: "42000"
      }
    } == query("CREATE DATABASE #{@test_db}")

    %R{} = query("DROP DATABASE #{@test_db}")
    assert %E{
      mssql: %{
        code: :base_table_or_view_not_found,
        driver: nil,
        message: "Cannot drop the database 'mssqlex_test_db', because it does not exist or you do not have permission.",
        mssql_code: "42S02"
      }
    } == query("DROP DATABASE #{@test_db}")
  end
end
