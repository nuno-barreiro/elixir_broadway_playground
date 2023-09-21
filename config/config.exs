import Config

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id, :request_id],
  level: :debug

config :ex_aws,
  region: "us-west-2",
  access_key_id: "notValidKey",
  secret_access_key: "notValidSecret"

config :ex_aws, :sqs,
  scheme: "http://",
  host: "localhost",
  port: 4566,
  region: "us-west-2"
