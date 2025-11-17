{ inputs, ... }:
_final: prev: {
  # MCP server for NixOS search
  mcp-nixos = inputs.mcp-nixos.packages.${prev.system}.default;
}
