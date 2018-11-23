defmodule Mssqlex.TestHelper do
  alias Mssqlex.Result, as: R

  @default_opts [
    hostname: System.get_env("MSSQL_HST") || "localhost",
    username: System.get_env("MSSQL_UID"),
    password: System.get_env("MSSQL_PWD"),
    database: "mssqlex_test"
  ]


  def default_opts, do: @default_opts

  def reset_db do 
    {:ok, pid} = Mssqlex.start_link([{:database, "master"} | @default_opts])
    {:ok, %R{}} = Mssqlex.query(pid, "DROP DATABASE IF EXISTS mssqlex_test", [])
    {:ok, %R{}} = Mssqlex.query(pid, "CREATE DATABASE mssqlex_test COLLATE Latin1_General_CS_AS_KS_WS", [])
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
      case Mssqlex.query(var!(context)[:pid], unquote(stat), unquote(params), unquote(opts)) do
        {:ok, %Mssqlex.Result{} = result} -> result
        {:error, err} -> err
      end
    end
  end
end

Mssqlex.TestHelper.reset_db()
ExUnit.start()
