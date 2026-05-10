#!/bin/zsh
set -euo pipefail
export DOTNET_ROOT="/usr/local/share/dotnet"
export PATH="$DOTNET_ROOT:$PATH"
project_root="$(cd "$(dirname "$0")/.." && pwd)"
dotnet build "$project_root/dotnet/AI.Core/AI.Core.csproj" -c Release
dotnet build "$project_root/dotnet/AI.Core.Cli/AI.Core.Cli.csproj" -c Release
dotnet run --project "$project_root/dotnet/AI.Core.Smoke/AI.Core.Smoke.csproj" -c Release
