#!/usr/bin/env python3
"""Behavior tests for the native high-resolution wheel validator."""

from __future__ import annotations

import importlib.util
from importlib.machinery import SourceFileLoader
from pathlib import Path
import sys
import tempfile
import unittest


GUEST = Path(__file__).resolve().parents[1]
CHECKER_PATH = GUEST / "native-overlay/usr/local/bin/try-omarchy-scroll-check"
LOADER = SourceFileLoader("try_omarchy_scroll_check", str(CHECKER_PATH))
SPEC = importlib.util.spec_from_loader(LOADER.name, LOADER)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"cannot import {CHECKER_PATH}")
checker = importlib.util.module_from_spec(SPEC)
sys.modules[LOADER.name] = checker
SPEC.loader.exec_module(checker)


def smooth_frames(sign: int = -1) -> list[object]:
    magnitudes = [3, 5, 7, 9, 12, 15, 18, 15, 12, 9, 7, 5, 3]
    frames = []
    legacy_accum = 0
    for index, magnitude in enumerate(magnitudes):
        value = sign * magnitude
        legacy_accum += value
        legacy = 0
        if abs(legacy_accum) >= 120:
            legacy = 1 if legacy_accum > 0 else -1
            legacy_accum -= legacy * 120
        frames.append(
            checker.ScrollFrame(
                timestamp=100.0 + index / 120,
                vertical_hires=value,
                vertical_legacy=legacy,
            )
        )
    return frames


class ScrollCheckTests(unittest.TestCase):
    def test_sysfs_bitmap_and_device_discovery(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            device = root / "event7/device"
            (device / "capabilities").mkdir(parents=True)
            (device / "name").write_text(checker.DEVICE_NAME + "\n", encoding="utf-8")
            mask = sum(
                1 << code
                for code in (
                    checker.REL_WHEEL,
                    checker.REL_HWHEEL,
                    checker.REL_WHEEL_HI_RES,
                    checker.REL_HWHEEL_HI_RES,
                )
            )
            (device / "capabilities/rel").write_text(f"{mask:08x}\n", encoding="ascii")
            devices = checker.discover_devices(root)

        self.assertEqual(len(devices), 1)
        self.assertTrue(all(check.passed for check in checker.capability_checks(devices[0])))

    def test_smooth_high_resolution_stream_scores_excellent(self) -> None:
        result = checker.analyze_frames(smooth_frames())
        self.assertEqual(result["status"], "pass")
        self.assertEqual(result["grade"], "excellent")
        self.assertGreaterEqual(result["score"], 95)

    def test_reversed_direction_is_a_failure(self) -> None:
        result = checker.analyze_frames(smooth_frames(sign=1))
        checks = {check["key"]: check for check in result["checks"]}
        self.assertEqual(result["status"], "fail")
        self.assertFalse(checks["host_direction"]["passed"])

    def test_coarse_detents_are_not_high_resolution(self) -> None:
        frames = [
            checker.ScrollFrame(
                timestamp=100.0 + index / 120,
                vertical_hires=-120,
                vertical_legacy=-1,
            )
            for index in range(16)
        ]
        result = checker.analyze_frames(frames)
        checks = {check["key"]: check for check in result["checks"]}
        self.assertEqual(result["status"], "fail")
        self.assertFalse(checks["fine_granularity"]["passed"])

    def test_qemu_patch_preserves_cocoa_direction(self) -> None:
        patch = (GUEST.parent / "macos/patches/qemu-virtio-scroll-devices.patch").read_text(
            encoding="utf-8"
        )
        self.assertIn(
            "double units = points * HIRES_WHEEL_UNITS_PER_POINT + *fraction;",
            patch,
        )
        self.assertNotIn(
            "double units = -points * HIRES_WHEEL_UNITS_PER_POINT + *fraction;",
            patch,
        )


if __name__ == "__main__":
    unittest.main()
