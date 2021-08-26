defmodule SCD4X do
  @moduledoc """
  Use Sensirion SCD4X CO2 sensor in Elixir
  """

  use GenServer

  require Logger

  @type options() :: [GenServer.option() | {:bus_name, bus_name}]

  @typedoc """
  Which I2C bus to use (defaults to `"i2c-1"`)
  """
  @type bus_name :: binary

  @default_bus_name "i2c-1"
  @bus_address 0x62

  @spec start_link(options()) :: GenServer.on_start()
  def start_link(init_arg \\ []) do
    gen_server_opts =
      Keyword.take(init_arg, [:name, :debug, :timeout, :spawn_opt, :hibernate_after])

    GenServer.start_link(__MODULE__, init_arg, gen_server_opts)
  end

  @spec start_periodic_measurement(GenServer.server()) :: :ok | {:error, any}
  def start_periodic_measurement(server) do
    GenServer.call(server, :start_periodic_measurement)
  end

  @spec stop_periodic_measurement(GenServer.server()) :: :ok | {:error, any}
  def stop_periodic_measurement(server) do
    GenServer.call(server, :stop_periodic_measurement)
  end

  @spec measure(GenServer.server()) :: {:ok, SCD4X.Measurement.t()} | {:error, any}
  def measure(server) do
    GenServer.call(server, :measure, 10_000)
  end

  @spec measure(GenServer.server(), :single_shot) :: {:ok, SCD4X.Measurement.t()} | {:error, any}
  def measure(server, :single_shot) do
    GenServer.call(server, :measure_single_shot, 10_000)
  end

  @deprecated "Use measure/2 with :single_shot option instead"
  def measure_single_shot(server) do
    GenServer.call(server, :measure_single_shot, 10_000)
  end

  @impl GenServer
  def init(init_arg) do
    bus_name = init_arg[:bus_name] || @default_bus_name
    bus_address = @bus_address

    Logger.info(
      "[SCD4X] Starting on bus #{bus_name} at address #{inspect(bus_address, base: :hex)}"
    )

    with {:ok, transport} <-
           SCD4X.Transport.I2C.start_link(bus_name: bus_name, bus_address: bus_address),
         {:ok, serial_number} <- SCD4X.Comm.serial_number(transport) do
      Logger.info("[SCD4X] Initializing sensor #{serial_number}")

      state = %{
        serial_number: serial_number,
        transport: transport
      }

      {:ok, state}
    else
      _error ->
        {:stop, "Error connecting to the sensor"}
    end
  end

  @impl GenServer
  def handle_call(:start_periodic_measurement, _from, state) do
    response = SCD4X.Comm.start_periodic_measurement(state.transport)
    {:reply, response, state}
  end

  @impl GenServer
  def handle_call(:stop_periodic_measurement, _from, state) do
    response = SCD4X.Comm.stop_periodic_measurement(state.transport)
    {:reply, response, state}
  end

  @impl GenServer
  def handle_call(:measure, _from, state) do
    response = SCD4X.Comm.read_measurement(state.transport)
    {:reply, response, state}
  end

  @impl GenServer
  def handle_call(:measure_single_shot, _from, state) do
    response = SCD4X.Comm.read_measurement_single_shot(state.transport)
    {:reply, response, state}
  end
end
