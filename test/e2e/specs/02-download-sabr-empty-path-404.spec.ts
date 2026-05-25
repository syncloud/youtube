import { test, expect } from '@playwright/test'
import { signIn } from '../helpers/auth'
import { shoot } from '../helpers/screenshot'

// Regression for https://syncloud.discourse.group/t/youtube-downloader-error-404/652
// yt-dlp 2025.10.22 can't reach SABR-only videos -> HTTP 403, no postprocess
// line emitted, so yt-dlp-webui leaves savedFilePath empty. The Home view still
// shows the "Completed" pill (yt-dlp's exit was treated as "done"), and clicking
// the Download icon opens '/filebrowser/d/?token=null' -- no {id} param, chi
// router returns 404. Expect the click to serve the file with 200.
test('SABR-only video still resolves the Download click without 404 (regression for forum #652)', async ({ page, context }, testInfo) => {
  await signIn(page)
  await page.getByRole('button', { name: 'Home speed dial' }).hover()
  await page.getByRole('menuitem', { name: 'New download' }).click()
  await page.locator('textarea').first().fill('https://www.youtube.com/watch?v=NokXiX-aznM')
  await page.getByRole('button', { name: 'Start' }).click()
  await expect(page.getByText('21,000 RPM')).toBeVisible()
  await expect(page.getByText('Completed')).toBeVisible({ timeout: 120_000 })
  await shoot(page, testInfo, 'sabr-download-completed')

  const respPromise = context.waitForEvent('response', r => /\/filebrowser\/d\//.test(r.url()))
  await page.getByRole('button', { name: 'Download this file' }).click()
  const resp = await respPromise

  expect(resp.status(), `GET ${resp.url()}`).toBe(200)
})
