import { test, expect } from '@playwright/test'
import { signIn } from '../helpers/auth'
import { shoot } from '../helpers/screenshot'

// A short non-SABR video that yt-dlp 2025.10.22 can still download.
// Verifies the happy path: yt-dlp completes -> savedFilePath is set ->
// the Home Download icon serves the file with 200.
test('download a non-SABR YouTube video and retrieve it via the Download icon', async ({ page, context }, testInfo) => {
  await signIn(page)
  await page.getByRole('button', { name: 'Home speed dial' }).hover()
  await page.getByRole('menuitem', { name: 'New download' }).click()
  await page.locator('textarea').first().fill('https://m.youtube.com/watch?v=x983nr0lXwo')
  await page.getByRole('button', { name: 'Start' }).click()
  await expect(page.getByText('Syncloud Introduction')).toBeVisible()
  await expect(page.getByText('Completed')).toBeVisible({ timeout: 120_000 })
  await shoot(page, testInfo, 'download-completed')

  const respPromise = context.waitForEvent('response', r => /\/filebrowser\/d\//.test(r.url()))
  await page.getByRole('button', { name: 'Download this file' }).click()
  const resp = await respPromise

  expect(resp.status(), `GET ${resp.url()}`).toBe(200)
})
