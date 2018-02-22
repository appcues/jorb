defmodule Jorb.Queue do
  @mix_env Mix.env()

  def prefixed_queue_name(queue_name) do
    case @mix_env do
      :prod -> queue_name
      _ -> "#{@mix_env}_#{queue_name}"
    end
  end

  def exists?(queue_name) do
  end
end
