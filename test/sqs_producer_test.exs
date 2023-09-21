defmodule ElixirBroadwayPlayground.Test.SQSProducerTest do
  use ExUnit.Case, async: false
  use ExUnit.Callbacks

  alias ElixirBroadwayPlayground.SQSProducer

  setup do
    {:ok, queue_url} = create_fifo_queue("broadway_demo")

    on_exit(fn ->
      delete_queue(queue_url)
    end)

    {:ok, %{queue_url: queue_url, bypass: Bypass.open(port: 8182)}}
  end

  test "process multiple messages from the same message group", %{
    queue_url: queue_url,
    bypass: bypass
  } do
    # Bypass.expect(bypass, "GET", "/api", fn conn ->
    #   :timer.sleep(500)
    #   Plug.Conn.send_resp(conn, 200, "")
    # end)

    enqueue_message(queue_url, %{id: "A1"}, "A")
    enqueue_message(queue_url, %{id: "A2"}, "A")
    enqueue_message(queue_url, %{id: "C1"}, "C")
    enqueue_message(queue_url, %{id: "B1"}, "B")
    enqueue_message(queue_url, %{id: "A3"}, "A")
    enqueue_message(queue_url, %{id: "B2"}, "B")
    enqueue_message(queue_url, %{id: "C2"}, "C")

    {:ok, _pid} =
      start_supervised(%{
        id: SqsQueueConsumer,
        start: {SQSProducer, :start_link, [[queue_url: queue_url, num_workers: 50]]}
      })
  end

  defp enqueue_message(queue_url, body, msg_group_id) do
    queue_url
    |> ExAws.SQS.send_message(Jason.encode!(body),
      message_group_id: msg_group_id
    )
    |> ExAws.request()
  end

  defp create_fifo_queue(queue_name) do
    {:ok, %{body: %{queue_url: queue_url}}} =
      "#{queue_name}.fifo"
      |> ExAws.SQS.create_queue(fifo_queue: true, content_based_deduplication: true)
      |> ExAws.request()

    {:ok, queue_url}
  end

  defp delete_queue(queue_url) do
    queue_url
    |> ExAws.SQS.delete_queue()
    |> ExAws.request()

    :ok
  end
end
