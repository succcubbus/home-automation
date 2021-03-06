# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :home_automation, cowboy_port: 8080
config :home_automation, network: "192.168.1.0/24"
config :home_automation, offline_debounce: 105

config :home_automation,
  before_sleep_dim_color: %{hue: 0, saturation: 0, brightness: 15, kelvin: 2500}

config :home_automation, before_sleep_dim_duration: 30 * 60 * 1000

config :home_automation,
  sleeping_color: %{hue: 0, saturation: 0, brightness: 1, kelvin: 2500}

config :home_automation, sleeping_dim_duration: 20 * 1000

config :home_automation,
  after_sleep_undim_color: %{hue: 0, saturation: 0, brightness: 80, kelvin: 4000}

config :home_automation, after_sleep_undim_duration: 10 * 1000

config :home_automation, light_label: "light-couch"

config :logger, level: :info
config :logger, :console, format: "$time $metadata[$level] $levelpad$message\n"

import_config "*-private.exs"

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure your application as:
#
#     config :home_automation, key: :value
#
# and access this configuration in your application as:
#
#     Application.get_env(:home_automation, :key)
#
# You can also configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"
