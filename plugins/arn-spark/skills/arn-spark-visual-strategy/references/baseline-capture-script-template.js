/**
 * Visual Test Capture Script Template
 *
 * Template used by arn-spark-visual-test-engineer to generate a project-specific
 * capture script. The agent reads this template and adapts it based on:
 * - The project's routes/screens (from screen-manifest.json or manual list)
 * - Viewport configuration
 * - Dark/light mode toggle mechanism
 * - Dev server URL and start command
 *
 * Placeholders:
 * - __BASE_URL__: Dev server URL (e.g., http://localhost:5173)
 * - __SCREENS__: Array of {name, route, waitFor?} objects
 * - __VIEWPORT_WIDTH__: Capture viewport width (e.g., 1280)
 * - __VIEWPORT_HEIGHT__: Capture viewport height (e.g., 720)
 * - __OUTPUT_DIR__: Directory for captured screenshots (e.g., visual-tests/captures)
 * - __DARK_MODE_TOGGLE__: Selector or JS to toggle dark mode (or null if N/A)
 */

import { chromium } from '@playwright/test';
import { mkdirSync, existsSync } from 'fs';
import { join } from 'path';

const BASE_URL = '__BASE_URL__';
const VIEWPORT = { width: __VIEWPORT_WIDTH__, height: __VIEWPORT_HEIGHT__ };
const OUTPUT_DIR = '__OUTPUT_DIR__';
const DARK_MODE_TOGGLE = __DARK_MODE_TOGGLE__; // null or selector string

const SCREENS = __SCREENS__;
// Example:
// [
//   { name: 'hub', route: '/', waitFor: 'networkidle' },
//   { name: 'settings', route: '/settings', waitFor: '.settings-panel' },
//   { name: 'pairing', route: '/pairing', waitFor: 'networkidle' },
// ]

async function capture() {
  // Ensure output directory exists
  if (!existsSync(OUTPUT_DIR)) {
    mkdirSync(OUTPUT_DIR, { recursive: true });
  }

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: VIEWPORT });
  const page = await context.newPage();

  console.log(`Capturing ${SCREENS.length} screens at ${VIEWPORT.width}x${VIEWPORT.height}`);

  for (const screen of SCREENS) {
    const url = `${BASE_URL}${screen.route}`;
    console.log(`  Capturing: ${screen.name} (${url})`);

    await page.goto(url, { waitUntil: 'networkidle' });

    // Wait for specific element or condition if specified
    if (screen.waitFor && screen.waitFor !== 'networkidle') {
      await page.waitForSelector(screen.waitFor, { timeout: 10000 });
    }

    // Allow rendering to settle
    await page.waitForTimeout(500);

    // Capture light mode
    const lightPath = join(OUTPUT_DIR, `${screen.name}--light.png`);
    await page.screenshot({ path: lightPath, fullPage: false });
    console.log(`    -> ${lightPath}`);

    // Capture dark mode if toggle exists
    if (DARK_MODE_TOGGLE) {
      await page.click(DARK_MODE_TOGGLE);
      await page.waitForTimeout(300); // Allow transition
      const darkPath = join(OUTPUT_DIR, `${screen.name}--dark.png`);
      await page.screenshot({ path: darkPath, fullPage: false });
      console.log(`    -> ${darkPath}`);

      // Toggle back to light mode
      await page.click(DARK_MODE_TOGGLE);
      await page.waitForTimeout(300);
    }
  }

  await browser.close();
  console.log(`\nDone. ${SCREENS.length} screens captured to ${OUTPUT_DIR}/`);
}

capture().catch(err => {
  console.error('Capture failed:', err);
  process.exit(1);
});
