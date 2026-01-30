#!/usr/bin/env python3
"""
Data Quality Check Script
Compare December 2025 vs January 2026 data in PGE meter database
"""

import sqlite3
import pandas as pd
from datetime import datetime

# Connect to database
conn = sqlite3.connect('data/pge_meter_data.sqlite')

# Query all data
query = "SELECT dttm_start, value, hour FROM meter_data ORDER BY dttm_start"
df = pd.read_sql_query(query, conn)
conn.close()

# Convert to datetime
df['dttm_start'] = pd.to_datetime(df['dttm_start'])
df['date'] = df['dttm_start'].dt.date
df['month'] = df['dttm_start'].dt.to_period('M')

print("=" * 80)
print("DATA QUALITY ANALYSIS: December 2025 vs January 2026")
print("=" * 80)

# Overall summary
print("\n1. OVERALL DATA SUMMARY")
print("-" * 80)
print(f"Total records: {len(df)}")
print(f"Date range: {df['dttm_start'].min()} to {df['dttm_start'].max()}")
print(f"Total days: {df['date'].nunique()}")

# Monthly breakdown
print("\n2. MONTHLY BREAKDOWN")
print("-" * 80)
monthly_stats = df.groupby('month').agg({
    'value': ['count', 'sum', 'mean', 'min', 'max', 'std'],
    'date': 'nunique'
}).round(2)
monthly_stats.columns = ['Records', 'Total_kWh', 'Avg_kWh', 'Min_kWh', 'Max_kWh', 'Std_kWh', 'Days']
print(monthly_stats)

# December 2025 analysis
dec_2025 = df[df['month'] == '2025-12']
jan_2026 = df[df['month'] == '2026-01']

print("\n3. DECEMBER 2025 DETAILS")
print("-" * 80)
if len(dec_2025) > 0:
    print(f"Records: {len(dec_2025)}")
    print(f"Days: {dec_2025['date'].nunique()}")
    print(f"Date range: {dec_2025['dttm_start'].min()} to {dec_2025['dttm_start'].max()}")
    print(f"Total consumption: {dec_2025['value'].sum():.2f} kWh")
    print(f"Average hourly: {dec_2025['value'].mean():.2f} kWh")
    print(f"Daily average: {dec_2025.groupby('date')['value'].sum().mean():.2f} kWh/day")
    print(f"Min hourly: {dec_2025['value'].min():.2f} kWh")
    print(f"Max hourly: {dec_2025['value'].max():.2f} kWh")
    print(f"Std dev: {dec_2025['value'].std():.2f} kWh")

    # Check for gaps
    dec_daily = dec_2025.groupby('date').size()
    print(f"\nRecords per day (expected 24 for hourly data):")
    print(f"  Min: {dec_daily.min()}, Max: {dec_daily.max()}, Avg: {dec_daily.mean():.1f}")
    missing_days = dec_daily[dec_daily < 24]
    if len(missing_days) > 0:
        print(f"  WARNING: {len(missing_days)} days with incomplete data:")
        for date, count in missing_days.items():
            print(f"    {date}: {count} records (missing {24-count})")
else:
    print("NO DATA FOUND FOR DECEMBER 2025")

print("\n4. JANUARY 2026 DETAILS")
print("-" * 80)
if len(jan_2026) > 0:
    print(f"Records: {len(jan_2026)}")
    print(f"Days: {jan_2026['date'].nunique()}")
    print(f"Date range: {jan_2026['dttm_start'].min()} to {jan_2026['dttm_start'].max()}")
    print(f"Total consumption: {jan_2026['value'].sum():.2f} kWh")
    print(f"Average hourly: {jan_2026['value'].mean():.2f} kWh")
    print(f"Daily average: {jan_2026.groupby('date')['value'].sum().mean():.2f} kWh/day")
    print(f"Min hourly: {jan_2026['value'].min():.2f} kWh")
    print(f"Max hourly: {jan_2026['value'].max():.2f} kWh")
    print(f"Std dev: {jan_2026['value'].std():.2f} kWh")

    # Check for gaps
    jan_daily = jan_2026.groupby('date').size()
    print(f"\nRecords per day (expected 24 for hourly data):")
    print(f"  Min: {jan_daily.min()}, Max: {jan_daily.max()}, Avg: {jan_daily.mean():.1f}")
    missing_days = jan_daily[jan_daily < 24]
    if len(missing_days) > 0:
        print(f"  WARNING: {len(missing_days)} days with incomplete data:")
        for date, count in missing_days.items():
            print(f"    {date}: {count} records (missing {24-count})")
else:
    print("NO DATA FOUND FOR JANUARY 2026")

# Comparison
if len(dec_2025) > 0 and len(jan_2026) > 0:
    print("\n5. COMPARISON: DECEMBER 2025 vs JANUARY 2026")
    print("-" * 80)

    dec_daily_avg = dec_2025.groupby('date')['value'].sum().mean()
    jan_daily_avg = jan_2026.groupby('date')['value'].sum().mean()

    pct_change = ((jan_daily_avg - dec_daily_avg) / dec_daily_avg) * 100

    print(f"Average daily consumption:")
    print(f"  December: {dec_daily_avg:.2f} kWh/day")
    print(f"  January:  {jan_daily_avg:.2f} kWh/day")
    print(f"  Change:   {pct_change:+.1f}%")

    # Check for unusual patterns
    print(f"\nData quality indicators:")
    dec_complete_days = (dec_2025.groupby('date').size() == 24).sum()
    jan_complete_days = (jan_2026.groupby('date').size() == 24).sum()
    print(f"  Complete days (24 hours):")
    print(f"    December: {dec_complete_days}/{dec_2025['date'].nunique()}")
    print(f"    January:  {jan_complete_days}/{jan_2026['date'].nunique()}")

    # Check for zeros
    dec_zeros = (dec_2025['value'] == 0).sum()
    jan_zeros = (jan_2026['value'] == 0).sum()
    print(f"  Zero value records:")
    print(f"    December: {dec_zeros} ({dec_zeros/len(dec_2025)*100:.1f}%)")
    print(f"    January:  {jan_zeros} ({jan_zeros/len(jan_2026)*100:.1f}%)")

    # Check for outliers (values > 3 std devs from mean)
    dec_mean, dec_std = dec_2025['value'].mean(), dec_2025['value'].std()
    jan_mean, jan_std = jan_2026['value'].mean(), jan_2026['value'].std()

    dec_outliers = dec_2025[dec_2025['value'] > dec_mean + 3*dec_std]
    jan_outliers = jan_2026[jan_2026['value'] > jan_mean + 3*jan_std]

    print(f"  Outliers (>3 std dev):")
    print(f"    December: {len(dec_outliers)}")
    if len(dec_outliers) > 0:
        print(f"      Max: {dec_outliers['value'].max():.2f} kWh at {dec_outliers['dttm_start'].iloc[0]}")
    print(f"    January:  {len(jan_outliers)}")
    if len(jan_outliers) > 0:
        print(f"      Max: {jan_outliers['value'].max():.2f} kWh at {jan_outliers['dttm_start'].iloc[0]}")

# Check for suspicious patterns
print("\n6. DATA QUALITY ISSUES DETECTED")
print("-" * 80)

issues = []

# Check if December has significantly more/less data than January
if len(dec_2025) > 0 and len(jan_2026) > 0:
    if abs(len(dec_2025) - len(jan_2026)) > 100:
        issues.append(f"ISSUE: Large difference in record counts (Dec: {len(dec_2025)}, Jan: {len(jan_2026)})")

# Check if values are still in Wh range (too high)
if df['value'].max() > 500:
    issues.append(f"CRITICAL: Maximum hourly value is {df['value'].max():.2f} kWh - likely still in Wh, not kWh!")
    issues.append("         Expected max hourly for 1-bed apartment: 2-5 kWh")
    issues.append("         This suggests the data reprocessing hasn't been run yet")

# Check daily averages
if len(dec_2025) > 0:
    dec_daily_avg = dec_2025.groupby('date')['value'].sum().mean()
    if dec_daily_avg > 200:
        issues.append(f"ISSUE: December daily average ({dec_daily_avg:.0f} kWh/day) is unrealistically high")
        issues.append("       Expected for 1-bed apartment: 30-50 kWh/day")

if len(jan_2026) > 0:
    jan_daily_avg = jan_2026.groupby('date')['value'].sum().mean()
    if jan_daily_avg > 200:
        issues.append(f"ISSUE: January daily average ({jan_daily_avg:.0f} kWh/day) is unrealistically high")
        issues.append("       Expected for 1-bed apartment: 30-50 kWh/day")

# Check for missing data
if len(dec_2025) == 0:
    issues.append("WARNING: No data found for December 2025")
if len(jan_2026) == 0:
    issues.append("WARNING: No data found for January 2026")

if len(issues) == 0:
    print("✓ No major data quality issues detected!")
else:
    for issue in issues:
        print(f"⚠ {issue}")

print("\n" + "=" * 80)
print("Analysis complete!")
print("=" * 80)
