#!/usr/bin/env bash
set -e

PROJECT_ROOT="/mnt/c/Users/Sumedh/Documents/GitHub/PG-E-Data-Visualizer"
VENV_PATH="$PROJECT_ROOT/venv"
AUTH_FILE="$PROJECT_ROOT/auth/auth.json"

cd "$PROJECT_ROOT"

# Activate virtual environment
source "$VENV_PATH/bin/activate"

# Run Python logic
python3 << 'EOF'
from pgesmd_self_access.api import SelfAccessApi

auth_file = "/mnt/c/Users/Sumedh/Documents/GitHub/PG-E-Data-Visualizer/auth/auth.json"

api = SelfAccessApi.auth(auth_file)
api.get_token()

print("Requesting historical data (7 days)...")
result = api.request_historical_data(days=7)
print(f"Request accepted: {result}")

if result:
    print("\nWatch Supabase logs and pge_data table for incoming data.")
EOF