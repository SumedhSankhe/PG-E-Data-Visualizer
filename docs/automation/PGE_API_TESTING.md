# PGE Share My Data API Testing

This document describes how we tested and validated the PGE API connection before receiving live data.

---

## Prerequisites

### 1. PGE Registration

You need a registered PGE Share My Data account with:

| Credential | Description |
|------------|-------------|
| Third Party ID | Your registration ID (e.g., `52144`) |
| Client ID | OAuth client identifier |
| Client Secret | OAuth client secret |
| SSL Certificate | `.crt` and `.key` files for mTLS |

### 2. Python Environment

```bash
cd /path/to/PG-E-Data-Visualizer
source venv/bin/activate
pip install pgesmd-self-access pandas
```

### 3. Auth Configuration

Create `auth/auth.json`:

```json
{
  "third_party_id": "52144",
  "client_id": "YOUR_CLIENT_ID",
  "client_secret": "YOUR_CLIENT_SECRET",
  "cert_crt_path": "/path/to/certificate.crt",
  "cert_key_path": "/path/to/private.key"
}
```

---

## Testing Steps

### Step 1: Verify Package Import

```python
from pgesmd_self_access.api import SelfAccessApi
print("Import successful")
```

**Common issues**:
- Wrong import path: Use `pgesmd_self_access.api`, not `pgesmd_self_access`
- Class name: `SelfAccessApi` (lowercase 'a' in 'Api')

### Step 2: Test Authentication

```python
from pgesmd_self_access.api import SelfAccessApi

auth_file = "auth/auth.json"
api = SelfAccessApi.auth(auth_file)

token = api.get_token()
print(f"Token: {token[:30]}...")
```

**Expected**: A token string like `a6db9ef7-a84c-4cad-990a-...`

**Common errors**:
- `400: Invalid Certificate` → Certificate path wrong or cert doesn't match registration
- `Missing self.cert, RI violated` → Certificate paths not set in auth.json

### Step 3: Check Service Status

```python
status = api.get_service_status()
print(f"Service online: {status}")
```

**Expected**: `True`

### Step 4: Complete API Testing (One-time)

PGE requires completing a test before activating your registration:

```python
from pgesmd_self_access.api import PgeRegister

# Create auth/auth.json first
reg = PgeRegister()

# This runs the full test sequence
result = reg.complete_testing()
print(f"Testing complete: {result}")
```

This will:
1. Get a test token
2. Check service status
3. Request sample data
4. Verify everything works

### Step 5: Request Historical Data

```python
from pgesmd_self_access.api import SelfAccessApi

api = SelfAccessApi.auth("auth/auth.json")
api.get_token()

# Request last 7 days of data
result = api.request_historical_data(days=7)
print(f"Request accepted: {result}")
```

**Expected**: `True` with log message:
```
request successful, awaiting POST from server.
```

**HTTP Response Codes**:
- `202 Accepted` → Success! PGE will send data to your notification URI
- `400 Bad Request` → Credentials or third_party_id mismatch
- `401 Unauthorized` → Token expired or invalid
- `403 Forbidden` → Certificate issue

---

## Complete Test Script

```python
#!/usr/bin/env python3
"""Test PGE API Connection"""

from pgesmd_self_access.api import SelfAccessApi

AUTH_FILE = "auth/auth.json"

def test_pge_api():
    print("=" * 60)
    print("PGE API Connection Test")
    print("=" * 60)

    # Initialize
    print("\n1. Initializing API...")
    api = SelfAccessApi.auth(AUTH_FILE)
    print("   OK")

    # Get token
    print("\n2. Getting access token...")
    token = api.get_token()
    print(f"   Token: {token[:30]}...")

    # Check service
    print("\n3. Checking service status...")
    status = api.get_service_status()
    print(f"   Service online: {status}")

    if not status:
        print("   ERROR: Service offline")
        return False

    # Request data
    print("\n4. Requesting historical data (7 days)...")
    result = api.request_historical_data(days=7)
    print(f"   Request accepted: {result}")

    if result:
        print("\n" + "=" * 60)
        print("SUCCESS! Data will be sent to your notification URI.")
        print("Check Supabase pge_data table in ~60 seconds.")
        print("=" * 60)

    return result

if __name__ == "__main__":
    test_pge_api()
```

Save as `scripts/automation/test_pge_api.py` and run:

```bash
source venv/bin/activate
python scripts/automation/test_pge_api.py
```

---

## API Methods

| Method | Description | Returns |
|--------|-------------|---------|
| `get_token()` | Get OAuth access token | Token string |
| `need_token()` | Check if token expired | Boolean |
| `get_service_status()` | Check if PGE API is online | Boolean |
| `request_latest_data()` | Request most recent data | Boolean |
| `request_historical_data(days=N)` | Request last N days | Boolean |
| `request_date_data(date)` | Request specific date | Boolean |

All `request_*` methods are **async** - they trigger PGE to send data to your notification URI.

---

## Understanding the Async Pattern

PGE's API does NOT return data directly. Instead:

```
You                         PGE                        Your Server
 |                           |                              |
 |-- request_historical_data |                              |
 |                           |                              |
 |<-------- 202 Accepted ----|                              |
 |                           |                              |
 |                           |-- (processes request) -------|
 |                           |                              |
 |                           |-- POST ESPI XML data ------->|
 |                           |                              |
 |                           |                     (store data)
```

This is why we need Supabase - to receive and store the callback.

---

## Troubleshooting

### "pgesmd_self_access package not installed"

```bash
pip install pgesmd-self-access
```

### "Invalid Certificate" (400)

1. Check certificate paths in auth.json are absolute paths
2. Verify certificate matches what you registered with PGE
3. Check certificate hasn't expired:
   ```bash
   openssl x509 -in certificate.crt -noout -dates
   ```

### "client credentials doesn't match" (400)

1. Verify `third_party_id` in auth.json matches PGE registration
2. Check `client_id` and `client_secret` are correct
3. Ensure you've completed the API testing phase with PGE

### Request returns True but no data received

1. Check your notification URI is correct in PGE registration
2. Verify Supabase Edge Function is deployed and working
3. Check Edge Function logs for errors
4. PGE may take 1-2 minutes to send data

---

## Certificate Details

Our certificate:
- **CN**: sumedhsankhe.github.io
- **Expires**: March 28, 2026

Check certificate:
```bash
openssl x509 -in /path/to/certificate.crt -noout -subject -dates
```

---

## PGE Registration Info

| Field | Value |
|-------|-------|
| Third Party ID | 52144 |
| User Type | Self Access |
| Commodity Type | Gas, Electric |
| Data Elements | Basic, Billing, Account, Usage |
| Historical Data | 24 months |
| Notification URI | https://dhwdtuuppvlbzjccotdk.supabase.co/functions/v1/pge-notify |

---

Last updated: January 2026
