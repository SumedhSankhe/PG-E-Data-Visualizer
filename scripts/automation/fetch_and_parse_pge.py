#!/usr/bin/env python3
"""
Fetch and Parse PGE Data

This script:
1. Fetches BatchList notifications from Supabase
2. Extracts resource URIs from BatchList
3. Fetches actual ESPI XML data from PGE API
4. Parses ESPI XML to extract usage readings
5. Saves to CSV for R processing

Works both locally and in GitHub Actions.
"""

import os
import sys
import json
import logging
import tempfile
import xml.etree.ElementTree as ET
from datetime import datetime
from pathlib import Path

import requests
import pandas as pd

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# ESPI XML namespaces
NAMESPACES = {
    'atom': 'http://www.w3.org/2005/Atom',
    'espi': 'http://naesb.org/espi'
}


def get_supabase_config():
    """Get Supabase configuration from environment or local file"""
    # Try environment variables first (for GHA)
    url = os.getenv('SUPABASE_URL')
    key = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

    if url and key:
        logger.info("Using Supabase config from environment variables")
        return url, key

    # Fall back to local config file
    try:
        # Try importing from local supabase_client.py
        sys.path.insert(0, os.path.dirname(__file__))
        from supabase_client import SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
        logger.info("Using Supabase config from local file")
        return SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
    except ImportError:
        logger.error("No Supabase configuration found")
        logger.error("Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY environment variables")
        logger.error("Or create scripts/automation/supabase_client.py with credentials")
        return None, None


def get_pge_api():
    """Initialize PGE API client"""
    import base64

    try:
        from pgesmd_self_access.api import SelfAccessApi
    except ImportError:
        logger.error("pgesmd_self_access not installed")
        return None

    # Try environment variables first (for GHA)
    client_id = os.getenv('PGE_CLIENT_ID')
    client_secret = os.getenv('PGE_CLIENT_SECRET')
    third_party_id = os.getenv('PGE_THIRD_PARTY_ID', '52144')

    # Certificates can be provided as:
    # 1. File paths (PGE_CERT_CRT_PATH, PGE_CERT_KEY_PATH)
    # 2. Base64-encoded content (PGE_CERT_CRT_BASE64, PGE_CERT_KEY_BASE64)
    cert_crt_path = os.getenv('PGE_CERT_CRT_PATH')
    cert_key_path = os.getenv('PGE_CERT_KEY_PATH')
    cert_crt_b64 = os.getenv('PGE_CERT_CRT_BASE64')
    cert_key_b64 = os.getenv('PGE_CERT_KEY_BASE64')

    temp_files = []  # Track temp files to clean up

    try:
        # If base64-encoded certs provided, decode to temp files
        if cert_crt_b64 and cert_key_b64:
            logger.info("Using base64-encoded certificates from environment")

            # Decode and write cert
            fd, cert_crt_path = tempfile.mkstemp(suffix='.crt')
            with os.fdopen(fd, 'wb') as f:
                f.write(base64.b64decode(cert_crt_b64))
            temp_files.append(cert_crt_path)

            # Decode and write key
            fd, cert_key_path = tempfile.mkstemp(suffix='.key')
            with os.fdopen(fd, 'wb') as f:
                f.write(base64.b64decode(cert_key_b64))
            temp_files.append(cert_key_path)

        if client_id and client_secret and cert_crt_path and cert_key_path:
            logger.info("Using PGE config from environment variables")
            auth_config = {
                "third_party_id": third_party_id,
                "client_id": client_id,
                "client_secret": client_secret,
                "cert_crt_path": cert_crt_path,
                "cert_key_path": cert_key_path
            }
            fd, auth_file = tempfile.mkstemp(suffix='.json')
            with os.fdopen(fd, 'w') as f:
                json.dump(auth_config, f)
            temp_files.append(auth_file)

            api = SelfAccessApi.auth(auth_file)

            # Store temp files on the api object for cleanup later
            api._temp_files = temp_files
            return api

    except Exception as e:
        logger.error(f"Error setting up PGE API from environment: {e}")
        # Clean up temp files on error
        for f in temp_files:
            if os.path.exists(f):
                os.unlink(f)

    # Fall back to local auth file
    auth_file = os.path.join(os.path.dirname(__file__), '..', '..', 'auth', 'auth.json')
    if os.path.exists(auth_file):
        logger.info(f"Using PGE config from {auth_file}")
        return SelfAccessApi.auth(auth_file)

    logger.error("No PGE API configuration found")
    return None


def fetch_batch_lists_from_supabase(url, key):
    """Fetch unprocessed BatchList notifications from Supabase"""
    headers = {
        "apikey": key,
        "Authorization": f"Bearer {key}",
        "Content-Type": "application/json"
    }

    # Fetch unprocessed rows
    response = requests.get(
        f"{url}/rest/v1/pge_data",
        headers=headers,
        params={
            "select": "*",
            "processed": "eq.false",
            "order": "received_at.desc",
            "limit": 10
        }
    )
    response.raise_for_status()
    return response.json()


def mark_row_processed(url, key, row_id):
    """Mark a Supabase row as processed"""
    headers = {
        "apikey": key,
        "Authorization": f"Bearer {key}",
        "Content-Type": "application/json"
    }

    response = requests.patch(
        f"{url}/rest/v1/pge_data",
        headers=headers,
        params={"id": f"eq.{row_id}"},
        json={"processed": True}
    )
    response.raise_for_status()


def extract_uris_from_batch_list(xml_string):
    """Extract resource URIs from BatchList XML"""
    if not xml_string or '<ns0:BatchList' not in xml_string:
        return []

    try:
        root = ET.fromstring(xml_string)
        uris = []
        for resources in root.findall('.//{http://naesb.org/espi}resources'):
            uri = resources.text
            if uri and 'correlationID' in uri and 'correlationID=000000000' not in uri:
                uris.append(uri)
        return uris
    except ET.ParseError as e:
        logger.warning(f"Error parsing BatchList XML: {e}")
        return []


def parse_espi_xml(xml_string):
    """
    Parse ESPI XML and extract interval readings

    Returns:
        List of dicts with 'timestamp' and 'value' keys
    """
    readings = []

    try:
        root = ET.fromstring(xml_string)
    except ET.ParseError as e:
        logger.error(f"Failed to parse ESPI XML: {e}")
        return readings

    # Find all IntervalReading elements
    for reading in root.findall('.//espi:IntervalReading', NAMESPACES):
        try:
            # Get time period
            time_period = reading.find('espi:timePeriod', NAMESPACES)
            if time_period is None:
                continue

            start_elem = time_period.find('espi:start', NAMESPACES)
            duration_elem = time_period.find('espi:duration', NAMESPACES)

            if start_elem is None:
                continue

            # Start time is Unix timestamp
            start_ts = int(start_elem.text)
            duration = int(duration_elem.text) if duration_elem is not None else 3600

            # Get value (in Wh, need to convert to kWh)
            value_elem = reading.find('espi:value', NAMESPACES)
            if value_elem is None:
                continue

            value_wh = int(value_elem.text)
            value_kwh = value_wh / 1000.0  # Convert Wh to kWh

            # Convert timestamp to datetime
            dt = datetime.fromtimestamp(start_ts)

            readings.append({
                'dttm_start': dt.strftime('%Y-%m-%d %H:%M:%S'),
                'value': value_kwh,
                'duration_seconds': duration
            })

        except (ValueError, AttributeError) as e:
            logger.warning(f"Error parsing reading: {e}")
            continue

    return readings


def main():
    """Main execution function"""
    logger.info("=" * 60)
    logger.info("PGE Data Fetch and Parse")
    logger.info("=" * 60)

    # Get configurations
    supabase_url, supabase_key = get_supabase_config()
    if not supabase_url or not supabase_key:
        logger.error("Supabase configuration missing")
        return 1

    pge_api = get_pge_api()
    if not pge_api:
        logger.error("PGE API configuration missing")
        return 1

    # Get token
    logger.info("Getting PGE API token...")
    pge_api.get_token()

    # Fetch BatchList notifications from Supabase
    logger.info("Fetching unprocessed notifications from Supabase...")
    rows = fetch_batch_lists_from_supabase(supabase_url, supabase_key)
    logger.info(f"Found {len(rows)} unprocessed rows")

    if not rows:
        logger.info("No new data to process")
        return 0

    all_readings = []
    processed_row_ids = []

    for row in rows:
        row_id = row['id']
        raw_xml = row.get('raw_xml', '')

        # Extract URIs from BatchList
        uris = extract_uris_from_batch_list(raw_xml)

        if not uris:
            logger.info(f"Row {row_id}: No valid URIs found, marking as processed")
            processed_row_ids.append(row_id)
            continue

        logger.info(f"Row {row_id}: Found {len(uris)} URIs to fetch")

        for uri in uris:
            logger.info(f"  Fetching: {uri[:80]}...")
            try:
                espi_data = pge_api.get_espi_data(uri)
                if espi_data:
                    readings = parse_espi_xml(espi_data)
                    logger.info(f"    Parsed {len(readings)} readings")
                    all_readings.extend(readings)
                else:
                    logger.warning(f"    No data returned")
            except Exception as e:
                logger.error(f"    Error fetching URI: {e}")

        processed_row_ids.append(row_id)

    # Save readings to CSV
    if all_readings:
        df = pd.DataFrame(all_readings)

        # Remove duplicates based on timestamp
        df = df.drop_duplicates(subset=['dttm_start'])

        # Sort by timestamp
        df = df.sort_values('dttm_start')

        # Save to CSV
        output_dir = Path(__file__).parent.parent.parent / 'data'
        output_dir.mkdir(exist_ok=True)
        output_file = output_dir / 'pge_latest.csv'

        df.to_csv(output_file, index=False)
        logger.info(f"Saved {len(df)} readings to {output_file}")

        # Summary
        logger.info(f"Date range: {df['dttm_start'].min()} to {df['dttm_start'].max()}")
        logger.info(f"Total consumption: {df['value'].sum():.2f} kWh")
    else:
        logger.warning("No readings parsed from any URI")

    # Mark rows as processed
    for row_id in processed_row_ids:
        try:
            mark_row_processed(supabase_url, supabase_key, row_id)
            logger.info(f"Marked row {row_id} as processed")
        except Exception as e:
            logger.error(f"Failed to mark row {row_id} as processed: {e}")

    logger.info("=" * 60)
    logger.info("Complete!")
    logger.info("=" * 60)

    return 0


if __name__ == "__main__":
    sys.exit(main())
