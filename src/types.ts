export interface Location {
  lon: number;
  lat: number;
  alt: number;
}

export interface TelemetryPayload {
  Status: "Online" | "Offline";
  BatteryLife: number;
  Light: number;
  Tilt: number;
  Shock: number;
  ActiveTags: number;
  Location: Location;
  TransportationMode: "Land" | "Air" | "Ocean" | "Train";
  LostTags: number;
  Temp: number;
  Humidity: number;
  Pressure: number;
  TotalTags: number;
  LightThreshold: number;
  TempThreshold: number;
  TiltThreshold: number;
  HumidityThreshold: number;
  ShockThreshold: number;
  PressureThreshold: number;
}

export interface Device {
  deviceId: string;
  telemetry: TelemetryPayload;
  enqueuedTime: Date;
}
