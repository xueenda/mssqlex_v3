defmodule MssqlexV3Test do
  use ExUnit.Case, async: true

  import MssqlexV3.TestHelper

  alias MssqlexV3.Result, as: R
  alias MssqlexV3.Query, as: Q

  setup context do
    {:ok, pid} = MssqlexV3.start_link(default_opts())
    {:ok, [pid: pid, test: context[:test]]}
  end

  test "execute/4", %{pid: pid} do
    assert {:ok,
     %Q{cache: nil, columns: nil, name: nil, statement: "SELECT 1"},
     %R{columns: [""], num_rows: 1, rows: [[1]]}
    } == MssqlexV3.execute(pid, %Q{statement: "SELECT 1"}, [], [])
  end

  test "execute!/4", %{pid: pid} do
    assert %R{
      columns: [""],
      num_rows: 1,
      rows: [[1]]
    } == MssqlexV3.execute!(pid, %Q{statement: "SELECT 1"}, [], [])
  end
end
