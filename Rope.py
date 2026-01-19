#!/usr/bin/env python3

import argparse
import logging
import sys
import onnxruntime

from rope import Coordinator

def setup_logging(verbosity):
    """Setup logging based on verbosity level"""
    if verbosity >= 2:
        level = logging.DEBUG
        onnx_level = 0  # Verbose
    elif verbosity == 1:
        level = logging.INFO
        onnx_level = 1  # Info
    else:
        level = logging.WARNING
        onnx_level = 2  # Warning
    
    # Configure Python logging
    logging.basicConfig(
        level=level,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        handlers=[
            logging.StreamHandler(sys.stdout)
        ]
    )
    
    # Create logger first before using it
    logger = logging.getLogger(__name__)
    
    # Configure ONNX Runtime logging (compatible with both onnxruntime and onnxruntime-directml)
    if hasattr(onnxruntime, 'set_default_logger_severity'):
        onnxruntime.set_default_logger_severity(onnx_level)
        logger.info(f"ONNX Runtime logging level: {onnx_level}")
    else:
        logger.debug("ONNX Runtime does not support set_default_logger_severity (DirectML variant)")
    
    logger.info(f"Logging level set to: {logging.getLevelName(level)}")
    
    return logger

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Rope - Face Swapping Application')
    parser.add_argument('-v', '--verbose', action='count', default=0,
                        help='Increase verbosity (use -v, -vv, or -vvv)')
    parser.add_argument('--force-cpu', action='store_true',
                        help='Force CPU execution (disable GPU)')
    
    args = parser.parse_args()
    
    # Setup logging
    logger = setup_logging(args.verbose)
    
    if args.force_cpu:
        logger.warning("⚠ CPU-only mode enabled (GPU disabled)")
        import os
        os.environ['ROPE_FORCE_CPU'] = '1'
    
    try:
        logger.info("Starting Rope application...")
        Coordinator.run()
    except Exception as e:
        logger.exception(f"Fatal error: {e}")
        sys.exit(1)
