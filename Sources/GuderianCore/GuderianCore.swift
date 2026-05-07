// GuderianCore is the integration surface for the local Guderian game.
// Re-export the embedded dzw engine and Guderian content module so tests,
// app UI, and automation share one stable import while the reusable engine
// target remains content-agnostic.
@_exported import DerZweiteWeltkriegCore
@_exported import DerZweiteWeltkriegHistorical
@_exported import DerZweiteWeltkriegGuderian
