defmodule SCD4X.Transport.I2C do
  @moduledoc false

  @behaviour SCD4X.Transport

  @impl SCD4X.Transport
  def start_link(opts) do
    transport_mod().start_link(opts)
  end

  @impl SCD4X.Transport
  def read(transport, bytes_to_read) do
    transport_mod().read(transport, bytes_to_read)
  end

  @impl SCD4X.Transport
  def write(transport, register_and_data) do
    transport_mod().write(transport, register_and_data)
  end

  @impl SCD4X.Transport
  def write(transport, register, data) do
    transport_mod().write(transport, register, data)
  end

  @impl SCD4X.Transport
  def write_read(transport, register, bytes_to_read) do
    transport_mod().write_read(transport, register, bytes_to_read)
  end

  defp transport_mod() do
    Application.get_env(:scd4x, :transport_mod, I2cServer)
  end
end
