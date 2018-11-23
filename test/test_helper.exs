defmodule MssqlexV3.TestHelper do
  alias MssqlexV3.Result, as: R

  @default_opts [
    hostname: System.get_env("MSSQL_HST") || "localhost",
    username: System.get_env("MSSQL_UID"),
    password: System.get_env("MSSQL_PWD"),
    database: "mssqlex_test"
  ]


  def default_opts, do: @default_opts

  def reset_db do 
    {:ok, pid} = MssqlexV3.start_link([{:database, "master"} | @default_opts])
    {:ok, %R{}} = MssqlexV3.query(pid, "DROP DATABASE IF EXISTS mssqlex_test", [])
    {:ok, %R{}} = MssqlexV3.query(pid, "CREATE DATABASE mssqlex_test COLLATE Latin1_General_CS_AS_KS_WS", [])
    GenServer.stop(pid, :normal)
  end

  def table_name(name) do
    database = default_opts()[:database]
    ~s(#{database}.dbo."#{Base.url_encode64(name)}")
  end

  defmacro table_name() do
    quote do
      database = default_opts()[:database]
      table = 
        var!(context)[:test]
        |> Atom.to_string()
        |> Base.url_encode64()
      ~s(#{database}.dbo."#{table}")
    end
  end

  defmacro query(stat, params \\ [], opts \\ []) do
    quote do
      case MssqlexV3.query(var!(context)[:pid], unquote(stat), unquote(params), unquote(opts)) do
        {:ok, %MssqlexV3.Result{} = result} -> result
        {:error, err} -> err
      end
    end
  end
end

MssqlexV3.TestHelper.reset_db()
ExUnit.start()
