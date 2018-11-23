defmodule Mssqlex.QueryTest do
  use ExUnit.Case, async: true

  import Mssqlex.TestHelper

  alias Mssqlex.Result, as: R

  setup context do
    {:ok, pid} = Mssqlex.start_link(default_opts())
    {:ok, [pid: pid, test: context[:test]]}
  end

  test "simple select", context do
    %R{} = query("CREATE TABLE #{table_name()} (name varchar(50))")
    %R{num_rows: 1} = query("INSERT INTO #{table_name()} VALUES ('Steven')")
    result = query("SELECT * FROM #{table_name()}")

    assert %R{columns: ["name"], num_rows: 1, rows: [["Steven"]]} == result
  end

  test "parametrized queries", context do
    %R{} = query("CREATE TABLE #{table_name()} (id int, name varchar(50), joined datetime2)")
    %R{num_rows: 1} = query(
      "INSERT INTO #{table_name()} VALUES (?, ?, ?);",
      [1, "Jae", "2017-01-01 12:01:01.3450000"]
    )
    result = query("SELECT * FROM #{table_name()}")

    assert %R{
      columns: ["id", "name", "joined"],
      num_rows: 1,
      rows: [[1, "Jae", {{2017, 1, 1}, {12, 1, 1, 0}}]]
    } == result
  end

  test "select where in", context do
    %R{} = query("CREATE TABLE #{table_name()} (name varchar(50), age int)")
    %R{num_rows: 1} = query("INSERT INTO #{table_name()} VALUES (?, ?)", ["Dexter", 34])
    %R{num_rows: 1} = query("INSERT INTO #{table_name()} VALUES (?, ?)", ["Malcolm", 41])

    result = query("SELECT * FROM #{table_name()} WHERE name IN (?, ?)", ["Dexter", "Malcolm"])
    assert %R{
      columns: ["name", "age"],
      num_rows: 2,
      rows: [["Dexter", 34], ["Malcolm", 41]]
    } == result

    result = query("SELECT * FROM #{table_name()} WHERE (name IN (?, ?)) AND (age = ?)", ["Dexter", "Malcolm", 41])
    assert %R{
      columns: ["name", "age"],
      num_rows: 1,
      rows: [["Malcolm", 41]]
    } == result

    result = query("SELECT * FROM #{table_name()} WHERE (age = ?) AND (name IN (?, ?))", [34, "Dexter", "Malcolm"])
    assert %R{
      columns: ["name", "age"],
      num_rows: 1,
      rows: [["Dexter", 34]]
    } == result
  end
end
