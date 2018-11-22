defmodule Mssqlex.ODBC do
  @moduledoc """
  Adapter to Erlang's `:odbc` module.

  This module is a GenServer that handles communication between Elixir
  and Erlang's `:odbc` module. Transformations are kept to a minimum,
  primarily just translating binaries to charlists and vice versa.

  It is used by `Mssqlex.Protocol` and should not generally be
  accessed directly.
  """

  use GenServer

  alias Mssqlex.Error
  alias Mssqlex.NewError

  ## Private API
  
  @spec get_connection(Keyword.t()) :: {:ok, pid()} | {:error, NewError.t()}
  defp get_connection(opts) do
    connect_opts = Keyword.delete_first(opts, :conn_str)

    case :odbc.connect(opts[:conn_str], connect_opts) do
      {:ok, pid} ->
        {:ok, pid}
      {:error, {odbc_code, _native_code, message}} ->
        {:error, Mssqlex.NewError.exception([mssql: %{driver: opts[:driver], code: odbc_code, message: message}])}
    end
  end

  @spec test_connection(binary(), Keyword.t()) :: {:ok, Keyword.t()} | {:error, NewError.t()}
  defp test_connection(conn_str, opts) do
    conn_str = to_charlist(conn_str)
    connect_opts =
      opts
      |> Keyword.put_new(:auto_commit, :off)
      |> Keyword.put_new(:timeout, 5000)
      |> Keyword.put_new(:extended_errors, :on)
      |> Keyword.put_new(:tuple_row, :off)
      |> Keyword.put_new(:binary_strings, :on)

    hostname = opts[:hostname] || "localhost"
    port = opts[:port] || 1433

    {:ok, pid} = Task.Supervisor.start_link
    task = Task.Supervisor.async_nolink(pid, fn ->
      :odbc.connect(conn_str, connect_opts)
    end, [timeout: 15_000])

    case Task.yield(task, 15_000) || Task.shutdown(task) do
      {:ok, {:ok, pid}} ->
        :ok = :odbc.disconnect(pid)
        connect_opts = Keyword.put_new(connect_opts, :conn_str, conn_str)
        {:ok, connect_opts}
      {:ok, {:error, {odbc_code, _native_code, message}}} ->
        {:error, Mssqlex.NewError.exception([mssql: %{driver: opts[:driver], code: odbc_code, message: message}])}
      {:exit, :timeout} ->
        {:error, DBConnection.ConnectionError.exception("tcp connect (#{hostname}:#{port}): non-existing domain - :nxdomain")}
      result ->
        result
    end
  end

  ## Public API

  @doc """
  Starts the connection process to the ODBC driver.

  `conn_str` should be a connection string in the format required by
  your ODBC driver.
  `opts` will be passed verbatim to `:odbc.connect/2`.
  """
  @spec start_link(binary(), Keyword.t()) :: {:ok, pid()}
  def start_link(conn_str, opts) do
    # opts = Keyword.put_new(opts, :show_sensitive_data_on_connection_error, true)
    case test_connection(conn_str, opts) do
      {:ok, connect_opts} ->
        GenServer.start_link(__MODULE__, connect_opts)
      error ->
        error
    end
  end

  @doc """
  Sends a parametrized query to the ODBC driver.

  Interface to `:odbc.param_query/3`.See
  [Erlang's ODBC guide](http://erlang.org/doc/apps/odbc/getting_started.html)
  for usage details and examples.

  `pid` is the `:odbc` process id
  `statement` is the SQL query string
  `params` are the parameters to send with the SQL query
  `opts` are options to be passed on to `:odbc`
  """
  @spec query(pid(), iodata(), Keyword.t(), Keyword.t()) ::
          {:selected, [binary()],
           [tuple()]
           | {:updated, non_neg_integer()}}
          | {:error, Exception.t()}
  def query(pid, statement, params, opts) do
    if Process.alive?(pid) do
      statement =
        statement
        |> IO.iodata_to_binary()
        |> String.replace(~r/\$\d+/, "?")
      GenServer.call(
        pid,
        {:query, %{statement: statement, params: params}},
        Keyword.get(opts, :timeout, 5000)
      )
    else
      {:error, %Mssqlex.Error{message: :no_connection}}
    end
  end

  @doc """
  Commits a transaction on the ODBC driver.

  Note that unless in autocommit mode, all queries are wrapped in
  implicit transactions and must be committed.

  `pid` is the `:odbc` process id
  """
  @spec commit(pid()) :: :ok | {:error, Exception.t()}
  def commit(pid) do
    if Process.alive?(pid) do
      GenServer.call(pid, :commit)
    else
      {:error, %Mssqlex.Error{message: :no_connection}}
    end
  end

  @doc """
  Rolls back a transaction on the ODBC driver.

  `pid` is the `:odbc` process id
  """
  @spec rollback(pid()) :: :ok | {:error, Exception.t()}
  def rollback(pid) do
    if Process.alive?(pid) do
      GenServer.call(pid, :rollback)
    else
      {:error, %Mssqlex.Error{message: :no_connection}}
    end
  end

  @doc """
  Disconnects from the ODBC driver.

  Attempts to roll back any pending transactions. If a pending
  transaction cannot be rolled back the disconnect still
  happens without any changes being committed.

  `pid` is the `:odbc` process id
  """
  @spec disconnect(pid()) :: :ok
  def disconnect(pid) do
    rollback(pid)
    GenServer.stop(pid, :normal)
  end

  ## GenServer callbacks

  @doc false
  def init(opts) do
    case get_connection(opts) do
      {:ok, pid} -> {:ok, pid}
      {:error, error} -> {:stop, error.mssql.message}
    end
  end

  @doc false
  def handle_call({:query, %{statement: statement, params: params}}, _from, state) do
    result = :odbc.param_query(state, to_charlist(statement), params)
    {:reply, handle_errors(result), state}
  end

  @doc false
  def handle_call(:commit, _from, state) do
    {:reply, handle_errors(:odbc.commit(state, :commit)), state}
  end

  @doc false
  def handle_call(:rollback, _from, state) do
    {:reply, handle_errors(:odbc.commit(state, :rollback)), state}
  end

  @doc false
  def terminate(_reason, state) do
    :odbc.disconnect(state)
  end

  defp handle_errors({:error, reason}), do: {:error, Error.exception(reason)}
  defp handle_errors(term), do: term
end
