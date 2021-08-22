defmodule SCD4X.Comm do
  @moduledoc false

  alias SCD4X.Transport.I2C

  use Bitwise

  @cmd_serial_number <<0x3682::16>>
  @cmd_data_ready <<0xE4B8::16>>
  @cmd_self_test <<0x3639::16>>
  @cmd_start_periodic_measurement <<0x21B1::16>>
  @cmd_stop_periodic_measurement <<0x3F86::16>>
  @cmd_read_measurement <<0xEC05::16>>
  @cmd_measure_single_shot <<0x219D::16>>
  @cmd_measure_single_shot_rht_only <<0x2196::16>>
  @cmd_perisist_settings <<0x3615::16>>
  @cmd_get_temperature_offset <<0x2318::16>>
  @cmd_set_temperature_offset <<0x241D::16>>
  @cmd_get_sensor_altitude <<0x2322::16>>
  @cmd_set_sensor_altitude <<0x2427::16>>
  @cmd_set_ambient_pressure <<0xE000::16>>
  @cmd_perform_forced_recal <<0x362F::16>>
  @cmd_get_automatic_self_calibration_enabled <<0x2413::16>>
  @cmd_set_automatic_self_calibration_enabled <<0x2416::16>>
  @cmd_start_low_power_periodic_measurement <<0x21AC::16>>
  @cmd_factory_reset <<0x3632::16>>
  @cmd_reinit <<0x3646::16>>
  @cmd_power_down <<0x36E0::16>>
  @cmd_wake_up <<0x36F6::16>>

  def serial_number(transport) do
    with {:ok, raw_binary} <- I2C.write_read(transport, @cmd_serial_number, 9) do
      <<sn1::16, _crc1, sn2::16, _crc2, sn3::16, _crc3>> = raw_binary
      <<value::unsigned-big-48>> = <<sn1::16, sn2::16, sn3::16>>
      {:ok, value}
    end
  end

  def healthy?(transport) do
    with :ok <- I2C.write(transport, @cmd_self_test),
         :ok <- Process.sleep(10_000),
         {:ok, <<sensor_status::16, _crc>>} <- I2C.read(transport, 3) do
      sensor_status == 0
    end
  end

  def data_ready?(transport) do
    with {:ok, <<ready::16, _crc>>} <- I2C.write_read(transport, @cmd_data_ready, 3) do
      (ready &&& 0x07FF) > 0
    end
  end

  def start_periodic_measurement(transport) do
    I2C.write(transport, @cmd_start_periodic_measurement)
  end

  def stop_periodic_measurement(transport) do
    with :ok <- I2C.write(transport, @cmd_stop_periodic_measurement),
         :ok <- Process.sleep(500) do
      :ok
    end
  end

  def read_measurement(transport, retry \\ 5) do
    case I2C.write_read(transport, @cmd_read_measurement, 9) do
      {:ok, raw_binary} ->
        {:ok, SCD4X.Measurement.from_raw(raw_binary)}

      {:error, _} ->
        # Retry for convenience because we get NACK when data not ready.
        # The update interval of periodic measurement is 5 seconds.
        if retry > 0 do
          Process.sleep(1000)
          read_measurement(transport, retry - 1)
        else
          {:error, :data_not_ready}
        end
    end
  end

  def read_measurement_single_shot(transport) do
    with :ok <- I2C.write(transport, @cmd_measure_single_shot),
         :ok <- Process.sleep(5000) do
      read_measurement(transport)
    end
  end

  def read_measurement_single_shot_rht_only(transport) do
    with :ok <- I2C.write(transport, @cmd_measure_single_shot_rht_only),
         :ok <- Process.sleep(50) do
      read_measurement(transport)
    end
  end

  def get_temperature_offset(transport) do
    with {:ok, <<sensor_value::16, _crc>>} <-
           I2C.write_read(transport, @cmd_get_temperature_offset, 3) do
      div(175 * sensor_value, 0xFFFF)
    end
  end

  def set_temperature_offset(transport, value_c) do
    sensor_value = div(value_c * 0xFFFF, 175)
    crc = SCD4X.Calc.checksum(<<sensor_value>>)
    I2C.write(transport, [@cmd_set_temperature_offset, <<sensor_value::16, crc>>])
  end

  def get_sensor_altitude(transport) do
    with {:ok, <<value_m::16, _crc>>} <- I2C.write_read(transport, @cmd_get_sensor_altitude, 3) do
      {:ok, value_m}
    end
  end

  def set_sensor_altitude(transport, value_m) do
    crc = SCD4X.Calc.checksum(<<value_m>>)
    I2C.write(transport, [@cmd_set_sensor_altitude, <<value_m::16, crc>>])
  end

  def set_ambient_pressure(transport, value_pa) do
    sensor_value = div(value_pa, 100)
    crc = SCD4X.Calc.checksum(<<sensor_value>>)
    I2C.write(transport, [@cmd_set_ambient_pressure, <<sensor_value::16, crc>>])
  end

  def perform_forced_recal(transport, target_co2_ppm) do
    crc = SCD4X.Calc.checksum(<<target_co2_ppm>>)

    result =
      case I2C.write_read(transport, [@cmd_perform_forced_recal, <<target_co2_ppm::16, crc>>], 3) do
        {:ok, <<0xFFFF::16, _crc>>} -> {:error, :forced_recal_failed}
        {:ok, <<sensor_value::16, _crc>>} -> {:ok, sensor_value - 0x8000}
        error -> error
      end

    Process.sleep(400)
    result
  end

  def automatic_self_calibration_enabled?(transport) do
    case I2C.write_read(transport, @cmd_get_automatic_self_calibration_enabled, 3) do
      {:ok, <<1::16, 0xB0>>} -> true
      {:ok, <<0::16, 0x81>>} -> false
      error -> error
    end
  end

  def enable_automatic_self_calibration(transport) do
    I2C.write(transport, [@cmd_set_automatic_self_calibration_enabled, <<1::16, 0xB0>>])
  end

  def disable_automatic_self_calibration(transport) do
    I2C.write(transport, [@cmd_set_automatic_self_calibration_enabled, <<0::16, 0x81>>])
  end

  def start_low_power_periodic_measurement(transport) do
    I2C.write(transport, @cmd_start_low_power_periodic_measurement)
  end

  def persist_settings(transport) do
    with :ok <- I2C.write(transport, @cmd_perisist_settings),
         :ok <- Process.sleep(800) do
      :ok
    end
  end

  def factory_reset(transport) do
    with :ok <- I2C.write(transport, @cmd_factory_reset),
         :ok <- Process.sleep(1200) do
      :ok
    end
  end

  def reinit(transport) do
    with :ok <- I2C.write(transport, @cmd_reinit),
         :ok <- Process.sleep(20) do
      :ok
    end
  end

  def power_down(transport) do
    with :ok <- I2C.write(transport, @cmd_power_down),
         :ok <- Process.sleep(1) do
      :ok
    end
  end

  def wake_up(transport) do
    with :ok <- I2C.write(transport, @cmd_wake_up),
         :ok <- Process.sleep(20) do
      :ok
    end
  end
end
