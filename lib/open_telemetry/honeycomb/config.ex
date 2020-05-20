defmodule OpenTelemetry.Honeycomb.Config.AttributeMap do
  @moduledoc """
  Attribute map configuration.

  Controls the dataset attributes used for various span properties _eg._ `"trace.trace_id"` for
  the trace identifier, which you didn't set via `OpenTelemetry.Span.set_attribute/2`. Use the map
  to match any existing [definitions][HCdefs] you've configured at the Honeycomb end.

  [HCdefs]: https://docs.honeycomb.io/working-with-your-data/managing-your-data/definitions/#tracing
  """

  @typedoc """
  Attribute map configuration for the OpenTelemetry Honeycomb exporter.
  """

  @type t :: %__MODULE__{
          duration_ms: String.t(),
          name: String.t(),
          parent_span_id: String.t(),
          span_id: String.t(),
          span_type: String.t(),
          trace_id: String.t()
        }

  defstruct duration_ms: "duration_ms",
            name: "name",
            parent_span_id: "trace.parent_id",
            span_id: "trace.span_id",
            span_type: "meta.span_type",
            trace_id: "trace.trace_id"
end

defmodule OpenTelemetry.Honeycomb.Config do
  @moduledoc """
  Configuration.

    #{
    "README.md"
    |> File.read!()
    |> String.split("<!-- CDOC !-->")
    |> Enum.fetch!(1)
    |> (&Regex.replace(~R{\(\#\K(?=[a-z][a-z0-9-]+\))}, &1, "module-")).()
  }
  """

  alias OpenTelemetry.Honeycomb.Config.AttributeMap
  alias OpenTelemetry.Honeycomb.Http
  alias OpenTelemetry.Honeycomb.Json

  @typedoc """
  Configuration option for the OpenTelemetry Honeycomb exporter.
  """
  @type config_opt ::
          {:api_endpoint, String.t()}
          | {:attribute_map, AttributeMap.t()}
          | {:dataset, String.t()}
          | {:write_key, String.t() | nil}
          | {:samplerate_key, String.t() | nil}
          | Http.config_opt()
          | Json.config_opt()

  @typedoc """
  A keyword list of configuration options for the OpenTelemetry Honeycomb exporter.
  """
  @type t :: [config_opt()]

  @doc """
  Get the default configuration for the OpenTelemetry Honeycomb exporter.
  """
  def default_config,
    do:
      [
        api_endpoint: "https://api.honeycomb.io",
        attribute_map: %AttributeMap{},
        dataset: "opentelemetry",
        write_key: nil
      ]
      |> Keyword.merge(Http.default_config())
      |> Keyword.merge(Json.default_config())
end
