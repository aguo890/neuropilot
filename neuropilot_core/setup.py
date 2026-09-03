# =============================================================================
# AI CONTEXT & DOCUMENTATION
# Phase: 3 (NeuroPilot Core - Task 3.2)
# Purpose: Setuptools setup script for building and installing the neuropilot_core C++ extension.
# =============================================================================

import os
from setuptools import setup
from pybind11.setup_helpers import Pybind11Extension, build_ext

__version__ = "1.0.0"

ext_modules = [
    Pybind11Extension(
        "neuropilot_core",
        [
            "python/bindings.cpp",
            "src/matrix.cpp",
            "src/kalman_filter.cpp",
        ],
        include_dirs=["include"],
        cxx_std=17,
        extra_compile_args=["-O3", "-Wall", "-Wextra"],
    ),
]

setup(
    name="neuropilot_core",
    version=__version__,
    author="NeuroPilot Team",
    description="C++ Kalman Filter neural decoder with pybind11 Python bindings",
    ext_modules=ext_modules,
    cmdclass={"build_ext": build_ext},
    zip_safe=False,
    python_requires=">=3.8",
)
