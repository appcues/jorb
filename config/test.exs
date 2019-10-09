use Mix.Config

config :jorb, Jorb.Backend.MemoryJob, backend: Jorb.Backend.Memory

config :jorb, Jorb.Backend.SQSJob, backend: Jorb.Backend.SQS

config :ex_aws, :sqs,
  access_key_id: "foo",
  secret_access_key: "bar",
  scheme: "http://",
  host: "localhost",
  port: 27345,
  region: "us-west-2"
