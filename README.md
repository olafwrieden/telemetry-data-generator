# Telemetry Data Generator

This is a simple telemetry generator that can be used to generate telemetry data for testing purposes. It was built for the Azure Data Explorer Microhack as a replacement for the IoT Central dependency.

## How it works

The generator simulates telemetry from 30 devices whose ids are defined in the `src/deviceIds.ts` file. We want the generator to emit payloads for the same simulated devices each time, thus we hardcode the device ids to keep them consistent between runs.

Every 1 minute, the `functions/TelemetryGenerator.ts` runs and emits a payload for each device ID. The payload is a JSON object which matches the expected format for the IoT Central API.

The payload array is then written onto the Event Hub for later ingestion into Azure Data Explorer (or other downstream systems).

## How to use

To adjust the Event Hub name and connection string, edit the `TelemetryGenerator.ts` file. Here you can also adjust the frequency of the telemetry generation.

```typescript
...
// Schedule the function to run every minute and push into the iotdata Event Hub.
app.timer("TelemetryGenerator", {
  schedule: "0 */1 * * * *",
  handler: TelemetryGenerator,
  return: output.eventHub({
    eventHubName: "iotdata", // <-- Name of the Event Hub
    connection: "EventHubConnection", // <-- Environment variable name (Connection String)
  }),
});
```

Be sure to supply the `EventHubConnection` environment variable when deploying the function app. The value is the connection string of your Event Hub Namespace.

### In Development

Locally this can be supplied in a `local.settings.json` file like so:

```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "DefaultEndpointsProtocol=...",
    "FUNCTIONS_WORKER_RUNTIME": "node",
    "AzureWebJobsFeatureFlags": "EnableWorkerIndexing",
    "EventHubConnection": "Endpoint=sb://..."
  }
}
```

### In Production

Add the `EventHubConnection` environment variable in the Azure Function's Configuration settings. The value should be the Event Hub connection string, e.g.

Key: `EventHubConnection`
Value: `Endpoint=sb://...`
