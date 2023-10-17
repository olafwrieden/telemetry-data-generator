import { faker } from "@faker-js/faker";
import { TelemetryPayload } from "./types";

/**
 * Generates a telemetry payload with randomly generated data.
 * @returns {TelemetryPayload} The generated telemetry payload.
 */
export const generate = (): TelemetryPayload => {
  const telemetryPayload: TelemetryPayload = {
    Status: faker.helpers.arrayElement(["Online", "Offline"]),
    BatteryLife: faker.number.int({ min: 0, max: 90 }),
    Light: faker.number.float({ min: 1, max: 83000, precision: 0.000001 }),
    Tilt: faker.number.float({ min: -90, max: 90, precision: 0.000001 }),
    Shock: faker.number.float({ min: -16, max: 16, precision: 0.000001 }),
    ActiveTags: faker.number.int({ min: 150, max: 174 }),
    Location: {
      lon: faker.location.longitude(),
      lat: faker.location.latitude(),
      alt: faker.number.float({ min: 0, max: 5000, precision: 0.000001 }),
    },
    TransportationMode: faker.helpers.arrayElement([
      "Land",
      "Air",
      "Ocean",
      "Train",
    ]),
    LostTags: faker.number.int({ min: 0, max: 10 }),
    Temp: faker.number.float({ min: -10, max: 50, precision: 0.000001 }),
    Humidity: faker.number.float({ min: 1, max: 100, precision: 0.000001 }),
    Pressure: faker.number.float({ min: 260, max: 1260, precision: 0.000001 }),
    TotalTags: faker.number.int({ min: 175, max: 200 }),
    LightThreshold: 30,
    TempThreshold: faker.number.float({
      min: -20,
      max: 50,
      precision: 0.000001,
    }),
    TiltThreshold: faker.number.float({
      min: -90,
      max: 90,
      precision: 0.000001,
    }),
    HumidityThreshold: faker.number.float({
      min: 1,
      max: 100,
      precision: 0.000001,
    }),
    ShockThreshold: faker.number.float({
      min: -16,
      max: 16,
      precision: 0.000001,
    }),
    PressureThreshold: faker.number.float({
      min: 260,
      max: 1260,
      precision: 0.000001,
    }),
  };

  return telemetryPayload;
};
