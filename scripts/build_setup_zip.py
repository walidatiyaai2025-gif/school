#!/usr/bin/env python3
"""Backward-compatible entry point; the guarded builder lives in setup/."""
import runpy
from pathlib import Path
runpy.run_path(str(Path(__file__).resolve().parents[1] / 'setup' / 'build_setup.py'), run_name='__main__')
