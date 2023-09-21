defmodule ElixirBroadwayPlayground.SQSProducer do
  use Broadway

  require Logger

  alias Broadway.Message

  def start_link(config) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {
          BroadwaySQS.Producer,
          queue_url: Keyword.get(config, :queue_url),
          receive_interval: 1000,
          on_success: :ack,
          on_failure: :noop,
          visibility_timeout: 10,
          max_number_of_messages: 1,
          attribute_names: [:message_group_id, :approximate_first_receive_timestamp]
        }
      ],
      processors: [
        default: [concurrency: Keyword.get(config, :num_workers, 1)]
      ],
      partition_by: &partition_by/1
    )
  end

  @impl true
  def handle_message(
        _,
        %Message{
          data: data,
          metadata: %{attributes: %{"message_group_id" => message_group_id}}
        } = message,
        _
      ) do
    log_event("Handling message", data, message_group_id)

    HTTPoison.get("https://swapi.dev/api/people/1", [{"Content-Type", "application/json"}],
      ssl: [verify: :verify_none]
    )
    |> handle_response(message)
  end

  defp handle_response(
         {:ok, _},
         %Message{
           data: data,
           metadata: %{attributes: %{"message_group_id" => message_group_id}}
         } = message
       ) do
    log_event("Message acknowledge", data, message_group_id)
    Message.ack_immediately(message)
  end

  defp handle_response(
         {:error, %HTTPoison.Error{reason: reason}},
         %Message{
           data: data,
           metadata: %{attributes: %{"message_group_id" => message_group_id}}
         } = message
       ) do
    log_event("Message processing failed ", data, message_group_id)
    log_event(reason, data, message_group_id)
    Message.failed(message, reason)
  end

  defp log_event(text, data, msg_group_id) do
    message_id = Jason.decode!(data)["id"]
    Logger.info("[#{inspect(self())}] #{text}: #{inspect(msg_group_id)} / #{inspect(message_id)}")
  end

  defp partition_by(%Message{
         metadata: %{attributes: %{"message_group_id" => message_group_id}}
       }) do
    :erlang.phash2(message_group_id)
  end
end
