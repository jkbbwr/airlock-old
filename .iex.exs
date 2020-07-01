IO.puts("starting test session")
{:ok, session} = Airlock.Session.create(
  "1b33523f",
  2,
  [
    {"ssh-ed25519", "AAAAC3NzaC1lZDI1NTE5AAAAIDPwS3uicetysg/n1eZQdurGMXKMY4JbWyKxUiMXCFu8"},
    {"ssh-ed25519", "AAAAC3NzaC1lZDI1NTE5AAAAIGYg3QS+veazTKX1fWG9jolSl8M+xU/0JtbgHOsa/Q1Q"}
  ],
  %{
    hostname: 'localhost',
    username: 'jakob',
    port: 22,
  }
)
