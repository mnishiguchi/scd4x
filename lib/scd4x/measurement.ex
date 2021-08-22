defmodule SCD4X.Measurement do
  @moduledoc """
  One sensor measurement
  """

  defstruct [:co2_ppm, :humidity_rh, :temperature_c, :timestamp_ms]

  @type t :: %{
          required(:timestamp_ms) => non_neg_integer(),
          required(:co2_ppm) => number,
          required(:humidity_rh) => number,
          required(:temperature_c) => number,
          optional(:__struct__) => atom
        }

  @spec from_raw(<<_::72>>) :: t()
  def from_raw(<<co2_ppm::16, _crc1, raw_temp::16, _crc2, raw_rh::16, _crc3>>) do
    __struct__(
      co2_ppm: co2_ppm,
      humidity_rh: humidity_rh_from_raw(raw_rh),
      temperature_c: temperature_c_from_raw(raw_temp),
      timestamp_ms: System.monotonic_time(:millisecond)
    )
  end

  defp humidity_rh_from_raw(raw_rh) do
    100 * raw_rh / 0xFFFF
  end

  defp temperature_c_from_raw(raw_temp) do
    -45 + 175 * raw_temp / 0xFFFF
  end
end
