# Supabase Integration

## What is Supabase?

Supabase is an open-source Firebase alternative that provides:
- **PostgreSQL Database**: A full Postgres database with REST API
- **Edge Functions**: Serverless functions that run on Deno (similar to AWS Lambda)
- **Authentication**: User auth (not used in this project)
- **Storage**: File storage (not used in this project)

We use Supabase as a **persistent endpoint** to receive data callbacks from PGE's API.

---

## Why Supabase?

PGE's Share My Data API uses an **async callback pattern**:
1. You request data from PGE
2. PGE returns "accepted" immediately
3. PGE sends the actual data to YOUR server 30-60 seconds later

GitHub Actions can't receive callbacks (no persistent URL). Supabase Edge Functions provide a free, always-available endpoint that can receive and store PGE's data.

---

## Our Setup

### Project Details

| Setting | Value |
|---------|-------|
| Project ID | `dhwdtuuppvlbzjccotdk` |
| Region | (check dashboard) |
| Notification URI | `https://dhwdtuuppvlbzjccotdk.supabase.co/functions/v1/pge-notify` |

### Components

#### 1. Edge Function: `pge-notify`

Receives POST requests from PGE containing ESPI XML data.

**Location**: Supabase Dashboard → Edge Functions → pge-notify

**Code**:
```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
      },
    })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const body = await req.text()
    const timestamp = new Date().toISOString()

    console.log('PGE Notification Received:', timestamp)

    const { error } = await supabase
      .from('pge_data')
      .insert({
        received_at: timestamp,
        raw_xml: body,
        processed: false
      })

    if (error) throw error

    return new Response(
      JSON.stringify({ status: 'success', timestamp }),
      { headers: { 'Content-Type': 'application/json' }, status: 200 }
    )
  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ status: 'error', message: error.message }),
      { headers: { 'Content-Type': 'application/json' }, status: 500 }
    )
  }
})
```

#### 2. Database Table: `pge_data`

Stores raw XML data received from PGE.

**Schema**:
| Column | Type | Description |
|--------|------|-------------|
| `id` | int8 (identity) | Auto-incrementing primary key |
| `received_at` | timestamptz | When data was received |
| `raw_xml` | text | Raw ESPI XML from PGE |
| `processed` | bool | Whether GHA has processed this row |

**RLS**: Enabled (service role key bypasses it)

---

## Testing

### Test the Edge Function

Send a test POST request:

```bash
curl -X POST "https://dhwdtuuppvlbzjccotdk.supabase.co/functions/v1/pge-notify" \
  -H "Content-Type: application/xml" \
  -d '<test>Hello from test</test>'
```

Expected response:
```json
{"status":"success","timestamp":"2026-01-20T01:20:58.386Z"}
```

### Verify Data in Table

Check via Supabase Dashboard:
1. Go to **Table Editor → pge_data**
2. You should see a new row with the test data

Or via SQL Editor:
```sql
SELECT * FROM pge_data ORDER BY received_at DESC LIMIT 5;
```

### Query via API (with service role key)

```bash
curl "https://dhwdtuuppvlbzjccotdk.supabase.co/rest/v1/pge_data?select=*&order=received_at.desc&limit=5" \
  -H "apikey: YOUR_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY"
```

Note: The anon key cannot read due to RLS. Use the service role key for backend access.

---

## Keys

| Key Type | Use For | RLS Bypass |
|----------|---------|------------|
| `anon` (public) | Client-side apps | No |
| `service_role` | Backend/GHA | Yes |

**Location**: Supabase Dashboard → Settings → API → Project API keys

- **anon key**: Safe to expose in client code
- **service_role key**: Keep secret! Used in Edge Functions and GHA

---

## Data Flow

```
PGE API Request (from GHA or local)
        ↓
PGE processes request
        ↓ (30-60 seconds)
PGE POSTs to Supabase Edge Function
        ↓
Edge Function stores in pge_data table
        ↓
GHA fetches from pge_data table
        ↓
GHA processes XML → updates database → redeploys app
```

---

## Troubleshooting

### Edge Function not receiving data

1. Check function logs: **Edge Functions → pge-notify → Logs**
2. Verify URL matches PGE registration exactly
3. Test function manually with curl

### Data not appearing in table

1. Check Edge Function logs for errors
2. Verify `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` env vars are set
3. Check RLS isn't blocking (use Table Editor which bypasses RLS)

### Can't query via API

1. Use service role key, not anon key
2. Check RLS policies if using anon key

---

## Useful Links

- [Supabase Dashboard](https://supabase.com/dashboard)
- [Edge Functions Docs](https://supabase.com/docs/guides/functions)
- [PostgREST API Docs](https://supabase.com/docs/guides/api)

---

Last updated: January 2026
