import { Buffer } from "node:buffer";

const DEFAULT_MAX_REQUEST_BYTES = 4_000_000;
const DEFAULT_MAX_STRING_BYTES = 256_000;
const TRUNCATION_MARKER = "\n[truncated by land: Langfuse payload limit]";

type IngestionEvent = {
  type?: unknown;
  id?: unknown;
  timestamp?: unknown;
  body?: Record<string, unknown>;
};

function encodedBytes(value: unknown): number {
  return Buffer.byteLength(JSON.stringify(value), "utf8");
}

function truncateString(value: string, maxBytes: number): string {
  if (Buffer.byteLength(value, "utf8") <= maxBytes) return value;

  const markerBytes = Buffer.byteLength(TRUNCATION_MARKER, "utf8");
  return Buffer.from(value, "utf8")
    .subarray(0, Math.max(0, maxBytes - markerBytes))
    .toString("utf8") + TRUNCATION_MARKER;
}

export function limitTelemetryValue(
  value: unknown,
  maxStringBytes = DEFAULT_MAX_STRING_BYTES,
): unknown {
  if (typeof value === "string") return truncateString(value, maxStringBytes);
  if (Array.isArray(value)) return value.map((item) => limitTelemetryValue(item, maxStringBytes));
  if (value && typeof value === "object") {
    return Object.fromEntries(
      Object.entries(value).map(([key, item]) => [key, limitTelemetryValue(item, maxStringBytes)]),
    );
  }
  return value;
}

function compactEvent(event: IngestionEvent): IngestionEvent {
  const body = event.body ?? {};
  const compactedBody: Record<string, unknown> = {
    id: body.id,
    traceId: body.traceId,
    name: body.name,
    startTime: body.startTime,
    endTime: body.endTime,
    parentObservationId: body.parentObservationId,
    model: body.model,
    level: body.level,
    statusMessage: body.statusMessage,
    metadata: {
      landPayloadTruncated: true,
      reason: "Event exceeded the Langfuse ingestion request limit",
    },
  };

  if (event.type === "trace-create") {
    compactedBody.timestamp = body.timestamp;
    compactedBody.sessionId = body.sessionId;
  } else if (event.type === "generation-create") {
    compactedBody.completionStartTime = body.completionStartTime;
    compactedBody.modelParameters = body.modelParameters;
    compactedBody.usageDetails = body.usageDetails;
    compactedBody.costDetails = body.costDetails;
  }

  return {
    type: event.type,
    id: event.id,
    timestamp: event.timestamp,
    body: compactedBody,
  };
}

export function chunkIngestionBatch(
  events: IngestionEvent[],
  metadata: Record<string, unknown>,
  maxRequestBytes = DEFAULT_MAX_REQUEST_BYTES,
): IngestionEvent[][] {
  if (!Number.isSafeInteger(maxRequestBytes) || maxRequestBytes <= 0) {
    throw new Error("maxRequestBytes must be a positive safe integer");
  }

  const chunks: IngestionEvent[][] = [];
  let current: IngestionEvent[] = [];

  for (const rawEvent of events) {
    let event = limitTelemetryValue(rawEvent) as IngestionEvent;
    if (encodedBytes({ batch: [event], metadata }) > maxRequestBytes) {
      event = compactEvent(event);
    }
    if (encodedBytes({ batch: [event], metadata }) > maxRequestBytes) {
      throw new Error("Langfuse ingestion metadata exceeds the configured request limit");
    }

    const candidate = [...current, event];
    if (current.length > 0 && encodedBytes({ batch: candidate, metadata }) > maxRequestBytes) {
      chunks.push(current);
      current = [event];
    } else {
      current = candidate;
    }
  }

  if (current.length > 0) chunks.push(current);
  return chunks;
}
