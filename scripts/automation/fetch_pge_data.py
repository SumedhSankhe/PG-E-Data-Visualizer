#!/usr/bin/env python3
"""
Fetch energy usage data from PGE Share My Data API
Uses the pgesmd_self_access package to authenticate and retrieve data
Exports data to CSV format for R processing
"""

import os
import sys
import logging
from datetime import datetime, timedelta
import pandas as pd

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def fetch_pge_data():
    """
    Fetch energy usage data from PGE Share My Data API

    Environment variables required:
    - PGE_CLIENT_ID: OAuth client ID from PGE
    - PGE_CLIENT_SECRET: OAuth client secret from PGE
    - PGE_ACCESS_TOKEN: OAuth access token
    - PGE_CERT_PATH: Path to SSL certificate

    Returns:
        DataFrame with energy usage data
    """
    try:
        # Import pgesmd_self_access
        try:
            from pgesmd_self_access import SelfAccessAPI
        except ImportError:
            logger.error("pgesmd_self_access package not installed")
            logger.error("Install with: pip install pgesmd-self-access")
            sys.exit(1)

        # Get credentials from environment variables
        client_id = os.getenv('PGE_CLIENT_ID')
        client_secret = os.getenv('PGE_CLIENT_SECRET')
        access_token = os.getenv('PGE_ACCESS_TOKEN')
        cert_path = os.getenv('PGE_CERT_PATH')

        # Validate credentials
        if not all([client_id, client_secret, access_token]):
            logger.error("Missing required environment variables")
            logger.error("Required: PGE_CLIENT_ID, PGE_CLIENT_SECRET, PGE_ACCESS_TOKEN")
            sys.exit(1)

        logger.info("Initializing PGE API client")

        # Initialize API client
        api = SelfAccessAPI(
            client_id=client_id,
            client_secret=client_secret,
            cert_path=cert_path if cert_path else None
        )

        # Set access token
        api.access_token = access_token

        logger.info("Fetching energy usage data")

        # Calculate date range (last 7 days by default)
        # PGE typically provides next-day data
        end_date = datetime.now()
        start_date = end_date - timedelta(days=7)

        # Fetch usage data
        # Note: Actual API method may vary - check pgesmd_self_access documentation
        usage_data = api.get_usage_data(
            start_date=start_date.strftime('%Y-%m-%d'),
            end_date=end_date.strftime('%Y-%m-%d')
        )

        if not usage_data:
            logger.warning("No data returned from API")
            return None

        logger.info(f"Retrieved {len(usage_data)} data points")

        # Convert to DataFrame
        df = pd.DataFrame(usage_data)

        # Standardize column names to match Shiny app requirements
        # Expected columns: dttm_start, value (hour, day, day2 added by R script)

        # Find timestamp column
        timestamp_col = None
        for col in ['timestamp', 'start_time', 'datetime', 'start', 'time']:
            if col in df.columns:
                timestamp_col = col
                break

        if timestamp_col is None:
            logger.error("Could not find timestamp column in API response")
            logger.error(f"Available columns: {list(df.columns)}")
            return None

        df['dttm_start'] = pd.to_datetime(df[timestamp_col])

        # Find consumption/value column
        value_col = None
        for col in ['consumption', 'kwh', 'usage', 'value', 'energy']:
            if col in df.columns:
                value_col = col
                break

        if value_col is None:
            logger.error("Could not find consumption/value column in API response")
            logger.error(f"Available columns: {list(df.columns)}")
            return None

        df['value'] = pd.to_numeric(df[value_col], errors='coerce')

        # Detect data interval
        if len(df) >= 2:
            time_diff = (df['dttm_start'].iloc[1] - df['dttm_start'].iloc[0]).total_seconds() / 60
            logger.info(f"Detected data interval: ~{time_diff:.0f} minutes")

            if time_diff < 60:
                logger.info(f"Sub-hourly data detected ({time_diff:.0f} min intervals)")
                logger.info("R processing script will aggregate to hourly")

        # Keep only timestamp and value - R script will add other columns
        # R script will also handle interval aggregation if needed
        df = df[['dttm_start', 'value']].copy()

        # Remove any NaN values
        df = df.dropna()

        # Sort by timestamp
        df = df.sort_values('dttm_start')

        logger.info(f"Processed data: {len(df)} rows")
        logger.info(f"Date range: {df['dttm_start'].min()} to {df['dttm_start'].max()}")
        logger.info(f"Total consumption: {df['value'].sum():.2f} kWh")

        return df

    except Exception as e:
        logger.error(f"Error fetching PGE data: {str(e)}")
        logger.exception("Full traceback:")
        return None

def main():
    """Main execution function"""
    logger.info("=" * 60)
    logger.info("PGE Share My Data Fetcher")
    logger.info("=" * 60)

    # Fetch data from PGE API
    df = fetch_pge_data()

    if df is None or df.empty:
        logger.error("Failed to fetch data from PGE API")
        sys.exit(1)

    # Save to CSV for R processing
    output_file = 'data/pge_latest.csv'
    df.to_csv(output_file, index=False)
    logger.info(f"Data saved to {output_file}")

    logger.info("=" * 60)
    logger.info("Fetch complete!")
    logger.info("=" * 60)

    return 0

if __name__ == "__main__":
    sys.exit(main())
