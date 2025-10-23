import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :git_colors, GitColorsWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "h4DI4/zZL7Odrx09zTpl7OXlNWfiEPmuysaKg4urrd6fiE2XCovsN41NZcsK0lER",
  server: false

# In test we don't send emails
config :git_colors, GitColors.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Enable test mode to mock git commands
config :git_colors, :test_mode, true
