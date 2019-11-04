use Mix.Config

config :jorb, Jorb.TestJob,
  read_batch_size: 10,
  write_batch_size: 1

config :jorb, Jorb.WriterTestJob,
  write_batch_size: 4,
  write_interval: 1,
  write_queues: ["q"]

config :ex_aws, :sqs,
  access_key_id: "foo",
  secret_access_key: "bar",
  scheme: "http://",
  host: "localhost",
  port: 32124,
  region: "us-west-2"
