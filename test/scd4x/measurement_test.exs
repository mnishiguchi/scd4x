defmodule SCD4X.MeasurementTest do
  use ExUnit.Case, async: true

  test "from_raw" do
    raw_sensor_signal = <<2, 96, 227, 109, 35, 65, 188, 9, 44>>

    assert %SCD4X.Measurement{
             co2_ppm: 608,
             humidity_rh: 73.45235370412756,
             temperature_c: 29.606317235065234,
             timestamp_ms: _
           } = SCD4X.Measurement.from_raw(raw_sensor_signal)
  end
end
