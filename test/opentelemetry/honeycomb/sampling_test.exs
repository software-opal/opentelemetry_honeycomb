defmodule OpenTelemetry.Honeycomb.SamplingTest do
  use ExUnit.Case, async: false

  require OpenTelemetry.Tracer
  require OpenTelemetry.Span

  import Mox, only: [set_mox_from_context: 1, verify_on_exit!: 1]

  setup :set_mox_from_context
  setup :verify_on_exit!

  @attempts 100

  test "#{@attempts} spans with a sample rate of 4" do
    test_pid = self()

    samplerate_key =
      :opentelemetry
      |> Application.get_all_env()
      |> get_in([:processors, :ot_batch_processor, :exporter, Access.elem(1), :samplerate_key])

    Mox.expect(MockedHttpBackend, :request, fn :post, _, _, body, _ ->
      try do
        assert events = body |> IO.iodata_to_binary() |> Poison.decode!()
        assert length(events) > 1, "opportunity for VERY rare build failure"

        replies =
          for %{"data" => data, "samplerate" => samplerate} <- events do
            refute samplerate == 1, "sample rate not set"
            refute samplerate_key in Map.keys(data), "samplerate_key #{samplerate_key} not popped"
            %{"status" => 202}
          end

        send(test_pid, {:mock_result, :ok})
        {:ok, 200, [], Poison.encode!(replies)}
      rescue
        e ->
          send(test_pid, {:mock_result, :error, e})
          {:ok, 400, [], "[]"}
      end
    end)

    for n <- 1..@attempts do
      OpenTelemetry.Tracer.with_span "some-span" do
        OpenTelemetry.Span.set_attribute("n", n)
        OpenTelemetry.Span.set_attribute(samplerate_key, 4)

        OpenTelemetry.Span.add_events([
          OpenTelemetry.event("event.name", [{"event.attr1", "event.value1"}])
        ])
      end
    end

    receive do
      {:mock_result, :ok} -> :ok
      {:mock_result, :error, e} -> raise e
    end
  end
end
