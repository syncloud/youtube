import { test, expect } from '@playwright/test'
import { signIn } from '../helpers/auth'
import { shoot } from '../helpers/screenshot'

test('user can sign in and reach the empty downloads view', async ({ page }, testInfo) => {
  await signIn(page)
  await shoot(page, testInfo, 'signed-in')
})

test('downloaded video serves through the Download icon (regression for #652)', async ({ page, context }, testInfo) => {
  await signIn(page)
  await page.getByRole('button', { name: 'Home speed dial' }).hover()
  await page.getByRole('menuitem', { name: 'New download' }).click()
  await page.locator('textarea').first().fill('https://www.youtube.com/watch?v=NokXiX-aznM')
  await page.getByRole('button', { name: 'Start' }).click()
  await expect(page.getByText('21,000 RPM')).toBeVisible()
  await expect(page.getByText('Completed')).toBeVisible({ timeout: 120_000 })
  await shoot(page, testInfo, 'download-completed')

  const respPromise = context.waitForEvent('response', r => /\/filebrowser\/d\//.test(r.url()))
  await page.getByRole('button', { name: 'Download this file' }).click()
  const resp = await respPromise

  expect(resp.status(), `GET ${resp.url()}`).toBe(200)
})
