import assert from "node:assert/strict";
import { Buffer } from "node:buffer";
import test from "node:test";

import { chunkIngestionBatch, limitTelemetryValue } from "./langfuse-batching.ts";

const metadata = { source: "pi-langfuse", fallback: "rest-ingestion" };

function requestBytes(batch: unknown[]): number {
  return Buffer.byteLength(JSON.stringify({ batch, metadata }), "utf8");
}

test("splits ingestion without exceeding the request byte limit", () => {
  const events = Array.from({ length: 12 }, (_, index) => ({
    type: "span-create",
    id: `event-${index}`,
    timestamp: "2026-07-21T00:00:00.000Z",
    body: { id: `span-${index}`, output: "x".repeat(180_000) },
  }));

  const chunks = chunkIngestionBatch(events, metadata, 500_000);

  assert.ok(chunks.length > 1);
  assert.equal(chunks.flat().length, events.length);
  assert.ok(chunks.every((chunk) => requestBytes(chunk) <= 500_000));
});

test("compacts an individual event that cannot fit", () => {
  const event = {
    type: "generation-create",
    id: "event",
    timestamp: "2026-07-21T00:00:00.000Z",
    body: {
      id: "generation",
      traceId: "trace",
      name: "oversized generation",
      completionStartTime: "2026-07-21T00:00:01.000Z",
      model: "gpt-5.6-sol",
      modelParameters: { temperature: 0.2 },
      usageDetails: { input: 12, output: 3 },
      costDetails: { total: 0.01 },
      output: Array.from({ length: 20 }, () => "x".repeat(100_000)),
    },
  };

  const [[compacted]] = chunkIngestionBatch([event], metadata, 100_000);

  assert.equal(compacted.body?.id, "generation");
  assert.equal(compacted.body?.completionStartTime, "2026-07-21T00:00:01.000Z");
  assert.deepEqual(compacted.body?.modelParameters, { temperature: 0.2 });
  assert.deepEqual(compacted.body?.usageDetails, { input: 12, output: 3 });
  assert.deepEqual(compacted.body?.costDetails, { total: 0.01 });
  assert.equal(
    (compacted.body?.metadata as Record<string, unknown>).landPayloadTruncated,
    true,
  );
  assert.ok(requestBytes([compacted]) <= 100_000);
});

test("preserves trace grouping fields when compacting", () => {
  const event = {
    type: "trace-create",
    id: "event",
    timestamp: "2026-07-21T00:00:02.000Z",
    body: {
      id: "trace",
      timestamp: "2026-07-21T00:00:00.000Z",
      name: "oversized trace",
      sessionId: "session",
      output: Array.from({ length: 20 }, () => "x".repeat(100_000)),
    },
  };

  const [[compacted]] = chunkIngestionBatch([event], metadata, 100_000);

  assert.equal(compacted.body?.timestamp, "2026-07-21T00:00:00.000Z");
  assert.equal(compacted.body?.sessionId, "session");
  assert.ok(requestBytes([compacted]) <= 100_000);
});

test("caps large telemetry strings before export", () => {
  const limited = limitTelemetryValue({ output: "é".repeat(300_000) }) as {
    output: string;
  };

  assert.ok(Buffer.byteLength(limited.output, "utf8") <= 256_000);
  assert.match(limited.output, /\[truncated by land: Langfuse payload limit\]$/);
});
