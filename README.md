# SCD4X

[![Hex version](https://img.shields.io/hexpm/v/scd4x.svg 'Hex version')](https://hex.pm/packages/scd4x)
[![API docs](https://img.shields.io/hexpm/v/scd4x.svg?label=docs 'API docs')](https://hexdocs.pm/scd4x)
[![CI](https://github.com/mnishiguchi/scd4x/actions/workflows/ci.yml/badge.svg)](https://github.com/mnishiguchi/scd4x/actions/workflows/ci.yml)
[![Publish](https://github.com/mnishiguchi/scd4x/actions/workflows/publish.yml/badge.svg)](https://github.com/mnishiguchi/scd4x/actions/workflows/publish.yml)

Use [Sensirion SCD4X](https://www.sensirion.com/en/environmental-sensors/carbon-dioxide-sensors/carbon-dioxide-sensor-scd4x) [CO2](https://en.wikipedia.org/wiki/Carbon_dioxide) sensors (SCD40 and SCD41) in Elixir.

## Usage

### Start the sensor server

```elixir
iex> {:ok, scd} = SCD4X.start_link(bus_name: "i2c-1")
{:ok, #PID<0.1407.0>}
```

### Single shot measurement

```elixir
iex> SCD4X.measure_single_shot(scd)
{:ok,
 %SCD4X.Measurement{
   co2_ppm: 638,
   humidity_rh: 70.49713134765625,
   temperature_c: 26.63848876953125,
   timestamp_ms: 400768
 }}
```

### Periodical measurement

```elixir
iex> SCD4X.start_periodic_measurement(scd)
:ok

iex> SCD4X.measure(scd)
{:ok,
 %SCD4X.Measurement{
   co2_ppm: 612,
   humidity_rh: 59.07440185546875,
   temperature_c: 30.331497192382812,
   timestamp_ms: 620482
 }}

SCD4X.stop_periodic_measurement(scd)
:ok
```
