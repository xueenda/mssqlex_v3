defmodule MssqlexV3.Mixfile do
  use Mix.Project

  def project do
    [
      app: :mssqlex_v3,
      version: "3.0.2",
      description:
        "Adapter to Microsoft SQL Server. Using DBConnection and ODBC.",
      elixir: "~> 1.6",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      aliases: aliases(),

      # Testing
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        "test.local": :test,
        coveralls: :test,
        "coveralls.travis": :test
      ],

      # Docs
      name: "MssqlexV3",
      source_url: "https://github.com/nikneroz/mssqlex_v3",
      docs: [main: "readme", extras: ["README.md"]]
    ]
  end

  def application do
    [extra_applications: [:logger, :odbc]]
  end

  defp aliases do
    []
  end

  defp deps do
    [
      {:db_connection, "~> 2.0"},
      {:decimal, "~> 1.0"},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:excoveralls, "~> 0.6", only: :test},
      {:inch_ex, "~> 0.5", only: :docs},
      {:exfmt, "~> 0.4.0", only: :dev}
    ]
  end

  defp package do
    [
      name: :mssqlex_v3,
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Steven Blowers", "Jae Bach Hardie", "Denis Rozenkin"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/nikneroz/mssqlex_v3"}
    ]
  end
end
