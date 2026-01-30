#!/usr/bin/env python3
"""
Fix January 2026 data by dividing values by 1000 (Wh → kWh)
Keeps March-December 2025 data unchanged
"""

import sqlite3
import pandas as pd
from datetime import datetime

# Connect to database
conn = sqlite3.connect('data/pge_meter_data.sqlite')

# Read all data
df = pd.read_sql_query("SELECT * FROM meter_data", conn)
df['dttm_start'] = pd.to_datetime(df['dttm_start'])

print("=" * 80)
print("FIXING JANUARY 2026 DATA")
print("=" * 80)

# Identify January 2026 data (values > 10 kWh/hour are likely in Wh)
jan_2026 = df['dttm_start'] >= '2026-01-01'
high_values = df['value'] > 10  # Threshold: >10 kWh/hour is unrealistic

# Find records that need fixing
needs_fix = jan_2026 & high_values

print(f"\nRecords to fix: {needs_fix.sum()}")
print(f"Date range: {df[needs_fix]['dttm_start'].min()} to {df[needs_fix]['dttm_start'].max()}")

if needs_fix.sum() > 0:
    # Show before values
    print(f"\nBefore fix:")
    print(f"  Average: {df[needs_fix]['value'].mean():.2f} kWh/hour")
    print(f"  Min: {df[needs_fix]['value'].min():.2f} kWh/hour")
    print(f"  Max: {df[needs_fix]['value'].max():.2f} kWh/hour")

    # Apply fix: divide by 1000
    df.loc[needs_fix, 'value'] = df.loc[needs_fix, 'value'] / 1000.0

    # Show after values
    print(f"\nAfter fix:")
    print(f"  Average: {df[needs_fix]['value'].mean():.2f} kWh/hour")
    print(f"  Min: {df[needs_fix]['value'].min():.2f} kWh/hour")
    print(f"  Max: {df[needs_fix]['value'].max():.2f} kWh/hour")

    # Update database
    print(f"\nUpdating database...")

    # Delete existing January 2026 data
    conn.execute("DELETE FROM meter_data WHERE dttm_start >= '2026-01-01'")

    # Insert fixed data
    fixed_data = df[jan_2026].copy()
    fixed_data['dttm_start'] = fixed_data['dttm_start'].dt.strftime('%Y-%m-%d %H:%M:%S')
    fixed_data.to_sql('meter_data', conn, if_exists='append', index=False)

    conn.commit()
    print("✓ Database updated")

    # Verify
    df_verify = pd.read_sql_query(
        "SELECT * FROM meter_data WHERE dttm_start >= '2026-01-01'",
        conn
    )
    df_verify['dttm_start'] = pd.to_datetime(df_verify['dttm_start'])

    daily_avg = df_verify.groupby(df_verify['dttm_start'].dt.date)['value'].sum().mean()
    print(f"\nVerification:")
    print(f"  January 2026 daily average: {daily_avg:.2f} kWh/day")

    if daily_avg < 100:
        print("  ✓ Values look reasonable!")
    else:
        print("  ⚠ Values still seem high!")

    # Also update RDS file
    print(f"\nUpdating RDS backup...")
    all_data = pd.read_sql_query("SELECT * FROM meter_data ORDER BY dttm_start", conn)
    all_data['dttm_start'] = pd.to_datetime(all_data['dttm_start'])

    # Save to CSV (R can read this)
    all_data.to_csv('data/meter_data_fixed.csv', index=False)
    print("✓ Saved to data/meter_data_fixed.csv")
    print("  Run this in R to update RDS:")
    print("    library(data.table)")
    print("    dt <- fread('data/meter_data_fixed.csv')")
    print("    dt[, dttm_start := as.POSIXct(dttm_start)]")
    print("    saveRDS(dt[, .(dttm_start, hour, value, day, day2)], 'data/meterData.rds')")

else:
    print("\n✓ No records need fixing!")

conn.close()

print("\n" + "=" * 80)
print("FIX COMPLETE!")
print("=" * 80)
