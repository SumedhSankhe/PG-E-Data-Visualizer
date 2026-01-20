#!/usr/bin/env python3
"""
Mark Supabase Rows as Processed

This script runs AFTER successful data processing to mark
Supabase rows as processed. This ensures rows aren't marked
if the processing pipeline fails.
"""

import os
import sys
import json
import logging
from pathlib import Path

import requests

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def get_supabase_config():
    """Get Supabase configuration from environment or local file"""
    url = os.getenv('SUPABASE_URL')
    key = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

    if url and key:
        return url, key

    # Fall back to local config file
    try:
        sys.path.insert(0, os.path.dirname(__file__))
        from supabase_client import SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
        return SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
    except ImportError:
        return None, None


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


def main():
    """Main execution function"""
    logger.info("Marking Supabase rows as processed...")

    # Get Supabase config
    supabase_url, supabase_key = get_supabase_config()
    if not supabase_url or not supabase_key:
        logger.error("Supabase configuration missing")
        return 1

    # Read processed row IDs from file
    data_dir = Path(__file__).parent.parent.parent / 'data'
    processed_ids_file = data_dir / 'processed_row_ids.json'

    if not processed_ids_file.exists():
        logger.info("No processed_row_ids.json file found - nothing to mark")
        return 0

    with open(processed_ids_file, 'r') as f:
        row_ids = json.load(f)

    if not row_ids:
        logger.info("No row IDs to mark as processed")
        return 0

    logger.info(f"Marking {len(row_ids)} rows as processed...")

    success_count = 0
    for row_id in row_ids:
        try:
            mark_row_processed(supabase_url, supabase_key, row_id)
            logger.info(f"Marked row {row_id} as processed")
            success_count += 1
        except Exception as e:
            logger.error(f"Failed to mark row {row_id}: {e}")

    # Clean up the file after successful marking
    if success_count == len(row_ids):
        processed_ids_file.unlink()
        logger.info("Cleaned up processed_row_ids.json")

    logger.info(f"Successfully marked {success_count}/{len(row_ids)} rows")
    return 0 if success_count == len(row_ids) else 1


if __name__ == "__main__":
    sys.exit(main())
