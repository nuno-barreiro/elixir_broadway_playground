defmodule ElixirBroadwayPlayground.Support do
  alias ElixirBroadwayPlayground.SQSProducer

  def run_test do
    {:ok, queue_url} = create_fifo_queue("test_queue")

    enqueue_test_messages(queue_url) |> IO.inspect(label: "Enqueue test messages")
    start_producers(queue_url) |> IO.inspect(label: "Supervisor")

    queue_url
  end

  def enqueue_test_messages(queue_url) do
    enqueue_message(queue_url, %{id: "A1"}, "A")
    enqueue_message(queue_url, %{id: "A2"}, "A")
    enqueue_message(queue_url, %{id: "C1"}, "C")
    enqueue_message(queue_url, %{id: "B1"}, "B")
    enqueue_message(queue_url, %{id: "A3"}, "A")
    enqueue_message(queue_url, %{id: "B2"}, "B")
    enqueue_message(queue_url, %{id: "C2"}, "C")
    :timer.sleep(500)
    enqueue_message(queue_url, %{id: "A4"}, "A")
    enqueue_message(queue_url, %{id: "A5"}, "A")
  end

  def create_fifo_queue(queue_name) do
    {:ok, %{body: %{queue_url: queue_url}}} =
      "#{queue_name}.fifo"
      |> ExAws.SQS.create_queue(fifo_queue: true, content_based_deduplication: true)
      |> ExAws.request()

    {:ok, queue_url}
  end

  def delete_queue(queue_url) do
    queue_url
    |> ExAws.SQS.delete_queue()
    |> ExAws.request()

    :ok
  end

  def start_producers(queue_url) do
    children = [
      %{
        id: SqsQueueConsumer,
        start: {SQSProducer, :start_link, [[queue_url: queue_url, num_workers: 50]]}
      }
    ]

    opts = [strategy: :one_for_one, name: ElixirBroadwayPlayground.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def enqueue_message(queue_url, body, msg_group_id) do
    body = Map.merge(body, %{random_stuff: :rand.uniform(99999)})

    queue_url
    |> ExAws.SQS.send_message(Jason.encode!(body),
      message_group_id: msg_group_id
    )
    |> ExAws.request()
  end
end
