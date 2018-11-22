defmodule Mssqlex.TypesTest do
  use ExUnit.Case, async: true

  alias Mssqlex.Result, as: R

  import Mssqlex.TestHelper

  setup context do
    {:ok, pid} = Mssqlex.start_link(Mssqlex.TestHelper.default_opts)
    {:ok, [pid: pid, test: context[:test]]}
  end

  test "char", context do
    assert %R{num_rows: 1, columns: ["test"], rows: [["Nathan"]]} ==
      insert_and_execute(context, "char(6)", ["Nathan"])
  end

  test "nchar", context do
    assert %R{num_rows: 1, columns: ["test"], rows: [["e→øæ"]]} ==
      insert_and_execute(context, "nchar(4)", ["e→øæ"])
  end

  test "nchar with preserved encoding", context do
    expected = :unicode.characters_to_binary("e→ø", :unicode, {:utf16, :little})

    assert %R{num_rows: 1, columns: ["test"], rows: [[expected]]} ==
             insert_and_execute(context, "nchar(3)", ["e→ø"], preserve_encoding: true)
  end

  test "varchar", context do
    assert %R{num_rows: 1, columns: ["test"], rows: [["Nathan"]]} ==
             insert_and_execute(context, "varchar(6)", ["Nathan"])
  end

  test "varchar with unicode characters", context do
    assert %R{num_rows: 1, columns: ["test"], rows: [["Nathan Molnár"]]} ==
             insert_and_execute(context, "varchar(15)", ["Nathan Molnár"])
  end

  test "nvarchar", context do
    assert %R{num_rows: 1, columns: ["test"], rows: [["e→øæ"]]} ==
             insert_and_execute(context, "nvarchar(4)", ["e→øæ"])
  end

  test "nvarchar with preserved encoding", context do
    expected = :unicode.characters_to_binary("e→ø", :unicode, {:utf16, :little})

    assert %R{num_rows: 1, columns: ["test"], rows: [[expected]]} ==
             insert_and_execute(context, "nvarchar(3)", ["e→ø"], preserve_encoding: true)
  end

  test "numeric(9, 0) as integer", context do
    assert %R{num_rows: 1, columns: ["test"], rows: [[123_456_789]]} ==
             insert_and_execute(context, "numeric(9)", [123_456_789])
  end

  test "numeric(8, 0) as decimal", context do
    assert %R{num_rows: 1, columns: ["test"], rows: [[12_345_678]]} ==
             insert_and_execute(context, "numeric(8)", [Decimal.new(12_345_678)])
  end

  test "numeric(15, 0) as decimal", context do
    number = Decimal.new("123456789012345")
    result = insert_and_execute(context, "numeric(15)", [number])
    [[result_number]] = result.rows

    assert result.num_rows == 1
    assert result.columns == ["test"]
    assert Decimal.equal?(number, result_number)
  end

  test "numeric(38, 0) as decimal", context do
    number = "12345678901234567890123456789012345678"

    assert %R{num_rows: 1, columns: ["test"], rows: [[number]]} ==
             insert_and_execute(context, "numeric(38)", [Decimal.new(number)])
  end

  test "numeric(36, 0) as string", context do
    number = "123456789012345678901234567890123456"

    assert %R{num_rows: 1, columns: ["test"], rows: [[number]]} ==
             insert_and_execute(context, "numeric(36)", [number])
  end

  test "numeric(5, 2) as decimal", context do
    number = Decimal.new("123.45")

    assert %R{num_rows: 1, columns: ["test"], rows: [[number]]} ==
             insert_and_execute(context, "numeric(5,2)", [number])
  end

  test "numeric(6, 3) as float", context do
    number = Decimal.new("123.456")

    assert %R{num_rows: 1, columns: ["test"], rows: [[number]]} ==
             insert_and_execute(context, "numeric(6,3)", [123.456])
  end

  test "real as decimal", context do
    number = Decimal.new("123.45")
    result = insert_and_execute(context, "real", [number])
    [[result_number]] = result.rows

    assert result.num_rows == 1
    assert result.columns == ["test"]
    assert Decimal.equal?(number, Decimal.round(result_number, 2))
  end

  test "float as decimal", context do
    number = Decimal.new("123.45")

    assert %R{num_rows: 1, columns: ["test"], rows: [[number]]} ==
             insert_and_execute(context, "float", [number])
  end

  test "double as decimal", context do
    number = Decimal.new("1.12345678901234")

    assert %R{num_rows: 1, columns: ["test"], rows: [[number]]} == insert_and_execute(context, "double precision", [number])
  end

  test "money as decimal", context do
    number = Decimal.new("1000000.45")

    assert %R{num_rows: 1, columns: ["test"], rows: [["1000000.4500"]]} ==
             insert_and_execute(context, "money", [number])
  end

  test "smallmoney as decimal", context do
    number = Decimal.new("123.45")

    assert %R{num_rows: 1, columns: ["test"], rows: [[number]]} ==
             insert_and_execute(context, "smallmoney", [number])
  end

  test "bigint", context do
    assert %R{num_rows: 1, columns: ["test"], rows: [["-9223372036854775808"]]} ==
             insert_and_execute(context, "bigint", [-9_223_372_036_854_775_808])
  end

  test "int", context do
    assert %R{num_rows: 1, columns: ["test"], rows: [[2_147_483_647]]} ==
             insert_and_execute(context, "int", [2_147_483_647])
  end

  test "smallint", context do
    assert %R{num_rows: 1, columns: ["test"], rows: [[32_767]]} ==
             insert_and_execute(context, "smallint", [32_767])
  end

  test "tinyint", context do
    assert %R{num_rows: 1, columns: ["test"], rows: [[255]]} ==
             insert_and_execute(context, "tinyint", [255])
  end

  test "smalldatetime as tuple", context do
    assert %R{num_rows: 1, columns: ["test"], rows: [[{{2017, 1, 1}, {12, 10, 0, 0}}]]} ==
             insert_and_execute(context, "smalldatetime", [{{2017, 1, 1}, {12, 10, 0, 0}}])
  end

  test "datetime as tuple", context do
    assert %R{num_rows: 1, columns: ["test"], rows: [[{{2017, 1, 1}, {12, 10, 0, 0}}]]} ==
             insert_and_execute(context, "datetime", [{{2017, 1, 1}, {12, 10, 0, 0}}])
  end

  test "datetime2 as tuple", context do
    assert %R{num_rows: 1, columns: ["test"], rows: [[{{2017, 1, 1}, {12, 10, 0, 0}}]]} ==
             insert_and_execute(context, "datetime2", [{{2017, 1, 1}, {12, 10, 0, 0}}])
  end

  test "date as tuple", context do
    assert %R{num_rows: 1, columns: ["test"], rows: [["2017-01-01"]]} ==
             insert_and_execute(context, "date", [{2017, 1, 1}])
  end

  test "time as tuple", context do
    insert(context, "time(6)", [{12, 10, 0, 54}])

    assert %R{num_rows: 1, columns: [""], rows: [["12:10:00.000054"]]} ==
      query("SELECT CONVERT(nvarchar(15), test, 21) FROM #{table_name("time(6)")}")
  end

  test "bit", context do
    assert %R{num_rows: 1, columns: ["test"], rows: [[true]]} ==
      insert_and_execute(context, "bit", [true])
  end

  test "uniqueidentifier", context do
    insert(context, "uniqueidentifier", ["6F9619FF-8B86-D011-B42D-00C04FC964FF"])

    assert %R{num_rows: 1, columns: [""], rows: [["6F9619FF-8B86-D011-B42D-00C04FC964FF"]]} ==
      query("SELECT CONVERT(char(36), test) FROM #{table_name("uniqueidentifier")}")
  end

  test "rowversion", context do
    type = "rowversion"

    %R{} = query("CREATE TABLE #{table_name(type)} (test #{type}, num int)")
    %R{} = query("INSERT INTO #{table_name(type)} (num) VALUES (?)", [1])
    %R{} = query("INSERT INTO #{table_name(type)} (num) VALUES (?)", [1])

    assert %R{num_rows: 2, columns: [""], rows: [[2001], [2002]]} ==
             query("SELECT CONVERT(int, test) FROM #{table_name(type)}")
  end

  test "binary", context do
    insert(context, "binary", [255])

    assert %R{num_rows: 1, columns: [""], rows: [[255]]} ==
      query("SELECT CONVERT(int, test) FROM #{table_name("binary")}")
  end

  test "varbinary", context do
    insert(context, "varbinary", [255])

    assert %R{num_rows: 1, columns: [""], rows: [[255]]} == 
      query("SELECT CONVERT(int, test) FROM #{table_name("varbinary")}")
  end

  test "null", context do
    type = "char(13)"

    %R{} = query("CREATE TABLE #{table_name(type)} (test #{type}, num int)")
    %R{} = query("INSERT INTO #{table_name(type)} (num) VALUES (?)", [2])

    assert %R{num_rows: 1, columns: [""], rows: [[nil]]} == 
      query("SELECT CONVERT(int, test) FROM #{table_name(type)}")
  end

  test "invalid input type", context do
    assert_raise Mssqlex.NewError, ~r/unrecognised type/, fn ->
      insert_and_execute(context, "char(10)", [{"Nathan"}])
    end
  end

  test "invalid input binary", context do
    assert_raise Mssqlex.NewError, ~r/failed to convert/, fn ->
      insert_and_execute(context, "char(12)", [<<110, 0, 200>>])
    end
  end

  defp table_name(type) do
    database = Mssqlex.TestHelper.default_opts[:database]
    ~s(#{database}.dbo."#{Base.url_encode64(type)}")
  end

  defp insert(context, type, params, opts \\ []) do
    %R{} = query("CREATE TABLE #{table_name(type)} (test #{type})", [], opts)
    %R{} = query("INSERT INTO #{table_name(type)} VALUES (?)", params, opts)
  end

  defp insert_and_execute(context, type, params, opts \\ []) do
    insert(context, type, params, opts)
    query("SELECT * FROM #{table_name(type)}", [], opts)
  end
end
