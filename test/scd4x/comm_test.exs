defmodule SCD4X.CommTest do
  use ExUnit.Case, async: true

  import Mox

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  test "serial_number" do
    SCD4X.MockTransport
    |> Mox.expect(:write_read, 1, fn _transport, <<0x3682::16>>, 9 ->
      {:ok, <<2_710_516_872_966_255_127_359::72>>}
    end)

    assert {:ok, 161_556_789_148_587} = SCD4X.Comm.serial_number(fake_transport())
  end

  defp fake_transport do
    :c.pid(0, 0, 0)
  end
end
