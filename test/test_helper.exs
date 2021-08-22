# Always warning as errors
if Version.match?(System.version(), "~> 1.10") do
  Code.put_compiler_option(:warnings_as_errors, true)
end

# Define dynamic mocks
Mox.defmock(SCD4X.MockTransport, for: SCD4X.Transport)

# Override the config settings
Application.put_env(:scd4x, :transport_mod, SCD4X.MockTransport)

ExUnit.start()
