#!/usr/bin/env python3
"""
Fetch energy usage data from PGE Share My Data API
Uses the pgesmd_self_access package to authenticate and retrieve data
Exports data to CSV format for R processing

Note: The PGE Share My Data API uses an async callback pattern where data is
pushed to a server you host. This script attempts direct methods where possible
but may require a separate server component for full functionality.
"""

import os
import sys
import logging
import json
import tempfile
from datetime import datetime, timedelta
from pathlib import Path

import pandas as pd

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def create_auth_file():
    """
    Create a temporary auth file from environment variables.

    Environment variables used:
    - PGE_CLIENT_ID: OAuth client ID
    - PGE_CLIENT_SECRET: OAuth client secret
    - PGE_ACCESS_TOKEN: Access token (used as third_party_id fallback)
    - PGE_CERT_PATH: Path to certificate (can be crt path or combined)

    Returns:
        str: Path to the temporary auth file
    """
    client_id = os.getenv('PGE_CLIENT_ID')
    client_secret = os.getenv('PGE_CLIENT_SECRET')
    access_token = os.getenv('PGE_ACCESS_TOKEN', '')
    cert_path = os.getenv('PGE_CERT_PATH', '')

    if not client_id or not client_secret:
        return None

    # The pgesmd_self_access package expects cert_crt_path and cert_key_path
    # If only one path is provided, use it for both (some setups use combined certs)
    auth_config = {
        "third_party_id": access_token,  # Use access token as third party ID
        "client_id": client_id,
        "client_secret": client_secret,
        "cert_crt_path": cert_path,
        "cert_key_path": cert_path  # Same path if using combined cert
    }

    # Write temp auth file
    fd, auth_file = tempfile.mkstemp(suffix='.json')
    with os.fdopen(fd, 'w') as f:
        json.dump(auth_config, f)

    return auth_file


def fetch_pge_data():
    """
    Fetch energy usage data from PGE Share My Data API

    Environment variables required:
    - PGE_CLIENT_ID: OAuth client ID from PGE
    - PGE_CLIENT_SECRET: OAuth client secret from PGE

    Optional:
    - PGE_ACCESS_TOKEN: Access token from PGE
    - PGE_CERT_PATH: Path to SSL certificate

    Returns:
        DataFrame with energy usage data, or None if fetch fails
    """
    auth_file = None

    try:
        # Import pgesmd_self_access
        try:
            from pgesmd_self_access.api import SelfAccessApi
        except ImportError:
            logger.error("pgesmd_self_access package not installed")
            logger.error("Install with: pip install pgesmd-self-access")
            return None

        # Create auth file from environment variables
        auth_file = create_auth_file()
        if auth_file is None:
            logger.error("Missing required environment variables")
            logger.error("Required: PGE_CLIENT_ID, PGE_CLIENT_SECRET")
            return None

        logger.info("Initializing PGE API client")

        try:
            api = SelfAccessApi.auth(auth_file)
        except Exception as e:
            logger.error(f"Failed to authenticate with PGE API: {e}")
            return None

        # Check service status first
        logger.info("Checking PGE service status...")
        try:
            status = api.get_service_status()
            logger.info(f"PGE service status: {status}")
        except Exception as e:
            logger.warning(f"Could not check service status: {e}")

        # Try to request historical data
        # Note: This triggers an async request - data will be sent to callback server
        logger.info("Requesting historical data from PGE...")
        try:
            # Request last 7 days of data
            result = api.request_historical_data(days=7)
            if result:
                logger.info("Historical data request submitted successfully")
                logger.info("Note: Data will be delivered asynchronously to callback server")
            else:
                logger.warning("Historical data request returned False")
        except Exception as e:
            logger.error(f"Failed to request historical data: {e}")

        # The pgesmd_self_access package is designed for async callbacks
        # For a simple CI workflow, we cannot receive the callback
        # Return None to indicate data is not immediately available
        logger.warning("PGE Share My Data uses async callbacks - data not immediately available")
        logger.warning("To receive data, run a SelfAccessServer with a public endpoint")

        return None

    except Exception as e:
        logger.error(f"Error in PGE data fetch: {str(e)}")
        logger.exception("Full traceback:")
        return None

    finally:
        # Clean up temp auth file
        if auth_file and os.path.exists(auth_file):
            os.unlink(auth_file)


def check_existing_data():
    """
    Check if there's existing data that can be used.

    Returns:
        DataFrame if existing data found, None otherwise
    """
    data_files = [
        'data/pge_latest.csv',
        'data/meterData.rds',  # Can't read directly, but indicates data exists
        'data/pge_meter_data.sqlite'
    ]

    for data_file in data_files:
        if os.path.exists(data_file):
            logger.info(f"Found existing data file: {data_file}")
            if data_file.endswith('.csv'):
                try:
                    df = pd.read_csv(data_file)
                    logger.info(f"Loaded {len(df)} rows from {data_file}")
                    return df
                except Exception as e:
                    logger.warning(f"Could not read {data_file}: {e}")

    return None


def main():
    """Main execution function"""
    logger.info("=" * 60)
    logger.info("PGE Share My Data Fetcher")
    logger.info("=" * 60)

    # Check if we should skip fetching (useful for CI when secrets aren't set)
    if os.getenv('SKIP_PGE_FETCH', '').lower() in ('true', '1', 'yes'):
        logger.info("SKIP_PGE_FETCH is set - skipping data fetch")
        logger.info("Using existing data if available")

        existing_df = check_existing_data()
        if existing_df is not None:
            logger.info("Using existing data - workflow can continue")
            return 0
        else:
            logger.warning("No existing data found")
            return 0  # Don't fail - just skip

    # Check for required credentials
    if not os.getenv('PGE_CLIENT_ID') or not os.getenv('PGE_CLIENT_SECRET'):
        logger.warning("PGE credentials not configured")
        logger.warning("Set PGE_CLIENT_ID and PGE_CLIENT_SECRET as repository secrets")

        # Check for existing data
        existing_df = check_existing_data()
        if existing_df is not None:
            logger.info("Using existing data - workflow can continue")
            return 0
        else:
            logger.error("No credentials and no existing data - cannot proceed")
            return 1

    # Attempt to fetch data from PGE API
    df = fetch_pge_data()

    if df is None:
        logger.warning("Could not fetch new data from PGE API")

        # Check for existing data
        existing_df = check_existing_data()
        if existing_df is not None:
            logger.info("Using existing data - workflow can continue")
            return 0
        else:
            logger.error("No new data and no existing data - workflow may fail")
            # Return 0 to allow workflow to continue with existing sqlite/rds data
            return 0

    # Save to CSV for R processing
    output_file = 'data/pge_latest.csv'
    Path('data').mkdir(exist_ok=True)
    df.to_csv(output_file, index=False)
    logger.info(f"Data saved to {output_file}")

    logger.info("=" * 60)
    logger.info("Fetch complete!")
    logger.info("=" * 60)

    return 0


if __name__ == "__main__":
    sys.exit(main())
