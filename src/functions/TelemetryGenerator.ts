import { InvocationContext, Timer, app, output } from "@azure/functions";
import { DEVICE_IDS } from "../deviceIds";
import { generate } from "../generator";
import { Device } from "../types";

export async function TelemetryGenerator(
  myTimer: Timer,
  context: InvocationContext
): Promise<Device[]> {
  context.log("Generating Payload...");

  // Generate a payload for each device id, the payload is structured to match the expected format for the IoT Central API.
  const output = DEVICE_IDS.map((id) => ({
    messageProperties: {
      "iothub-creation-time-utc": new Date(),
    },
    enrichments: {},
    applicationId: "1b2f5f29-a78b-4012-bf31-2016473cadf6",
    deviceId: id,
    messageSource: "telemetry",
    telemetry: generate(),
    schema: "default@v1",
    enqueuedTime: new Date(),
    templateId: "dtmi:ltifbs50b:mecybcwqm",
  }));

  // context.log(output);
  context.log("Emitting Payload.");

  // Write the payload to the Event Hub.
  return output;
}

// Schedule the function to run every minute and push into the iotdata Event Hub.
app.timer("TelemetryGenerator", {
  schedule: "0 */1 * * * *",
  handler: TelemetryGenerator,
  return: output.eventHub({
    eventHubName: "iotdata",
    connection: "EventHubConnection",
  }),
});
