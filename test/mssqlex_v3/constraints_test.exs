defmodule MssqlexV3.ConstraintsTest do
  use ExUnit.Case, async: true

  import MssqlexV3.TestHelper

  alias MssqlexV3.Result, as: R
  alias MssqlexV3.Error, as: E

  setup context do
    {:ok, pid} = MssqlexV3.start_link(default_opts())
    {:ok, [pid: pid, test: context[:test]]}
  end

  test "Unique constraint", context do
    %R{} = query("CREATE TABLE #{table_name()} (id int CONSTRAINT id_unique UNIQUE)")
    %R{} = query("INSERT INTO #{table_name()} VALUES (?)", [42])
    %E{mssql: %{message: message}} =
      query("INSERT INTO #{table_name()} VALUES (?)", [42])

    assert message =~ "The duplicate key value is (42)."
    assert message =~ "Violation of UNIQUE KEY constraint 'id_unique'"
  end

  test "Unique index", context do
    %R{} = query("CREATE TABLE #{table_name()} (id int)")
    %R{} = query("CREATE UNIQUE INDEX id_unique ON #{table_name()} (id)")
    %R{} = query("INSERT INTO #{table_name()} VALUES (?)", [42])
    %E{mssql: %{message: message}} =
      query("INSERT INTO #{table_name()} VALUES (?)", [42])

    assert message =~ "Cannot insert duplicate key row in object"
    assert message =~ "with unique index 'id_unique'."
  end

  test "Foreign Key constraint", context do
    assoc_table_name = table_name("assoc")
    table_name = table_name("fk")
    %R{} = query("CREATE TABLE #{assoc_table_name} (id int CONSTRAINT id_pk PRIMARY KEY)")
    %R{} = query("CREATE TABLE #{table_name} (id int CONSTRAINT id_foreign FOREIGN KEY REFERENCES #{assoc_table_name})")
    %R{} = query("INSERT INTO #{assoc_table_name} VALUES (?)", [42])
    %E{mssql: %{message: message}} = query("INSERT INTO #{table_name} VALUES (?)", [12])

    assert message =~ "The INSERT statement conflicted with the FOREIGN KEY constraint \"id_foreign\"."
  end

  test "Check constraint", context do
    %R{} = query("CREATE TABLE #{table_name()} (id int CONSTRAINT id_check CHECK (id = 1))")
    %E{mssql: %{message: message}} = query("INSERT INTO #{table_name()} VALUES (?)", [42])

    assert message =~ "The INSERT statement conflicted with the CHECK constraint \"id_check\"."
  end

  @tag skip: "Database doesn't support this"
  test "Multiple constraints", context do
    %R{} = query("CREATE TABLE #{table_name()} (id int CONSTRAINT mult_id_unique UNIQUE, foo int CONSTRAINT mult_foo_check CHECK (foo = 3))")
    %R{} = query("INSERT INTO #{table_name()} VALUES (?, ?)", [42, 3])
    %E{mssql: %{message: message}} = query("INSERT INTO #{table_name()} VALUES (?, ?)", [42, 5])

    assert message =~ "Violation of UNIQUE KEY constraint 'mult_id_unique'."
    assert message =~ "Violation of UNIQUE KEY constraint 'mult_foo_check'."
  end
end
