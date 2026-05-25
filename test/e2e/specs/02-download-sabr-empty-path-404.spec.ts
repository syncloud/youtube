import { test, expect } from '@playwright/test'
import { signIn } from '../helpers/auth'
import { shoot } from '../helpers/screenshot'

// Regression for https://syncloud.discourse.group/t/youtube-downloader-error-404/652
// yt-dlp 2025.10.22 can't reach SABR-only YouTube formats on residential IPs,
// so the download exits without ever emitting the postprocess line. The Home
// view treats `progress.percentage === "-1"` as Completed (it stays "-1" for
// both "never started" and "fully done"), keeps the Download icon visible, and
// the icon calls window.open('/filebrowser/d/' + btoa(savedFilePath)). When
// savedFilePath is empty the URL becomes /filebrowser/d/?token=null, which has
// no {id} param, so chi returns 404.
test('SABR-only video Download icon serves the file (forum #652)', async ({ page, context }, testInfo) => {
  await signIn(page)
  await page.getByRole('button', { name: 'Home speed dial' }).hover()
  await page.getByRole('menuitem', { name: 'New download' }).click()
  await page.locator('textarea').first().fill('https://www.youtube.com/watch?v=NokXiX-aznM')
  await page.getByRole('button', { name: 'Start' }).click()

  // Scope all assertions to this specific card so we don't match a different
  // job left over from spec 01 in the same in-memory webui state.
  const card = page.locator('.MuiCard-root', { hasText: '21,000 RPM' })
  await expect(card).toBeVisible()
  await expect(card.getByText('Completed')).toBeVisible({ timeout: 300_000 })
  await shoot(page, testInfo, 'sabr-download-completed')

  const respPromise = context.waitForEvent('response', r => /\/filebrowser\/d\//.test(r.url()))
  await card.getByRole('button', { name: 'Download this file' }).click()
  const resp = await respPromise

  expect(resp.status(), `GET ${resp.url()}`).toBe(200)
})
