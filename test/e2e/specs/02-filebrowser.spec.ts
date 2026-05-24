import { test, expect, Page } from '@playwright/test'
import { ssh } from '../helpers/ssh'

const deviceUser = required('PLAYWRIGHT_DEVICE_USER')
const devicePassword = required('PLAYWRIGHT_DEVICE_PASSWORD')

function required(name: string): string {
  const v = process.env[name]
  if (!v) throw new Error(`${name} is required`)
  return v
}

async function signIn(page: Page) {
  await page.goto('/')
  await page.locator('#username-textfield').fill(deviceUser)
  await page.locator('#password-textfield').fill(devicePassword)
  await page.locator('#sign-in-button').click()
  await expect(page.getByText('No active downloads')).toBeVisible()
}

test('filebrowser serves files at the symlink-resolved path', async ({ page }) => {
  ssh('echo regression > /data/youtube/regression_filebrowser.bin')
  ssh('chown youtube:youtube /data/youtube/regression_filebrowser.bin')
  const resolved = ssh('readlink -f /data/youtube/regression_filebrowser.bin').trim()
  const id = encodeURIComponent(Buffer.from(resolved).toString('base64'))

  await signIn(page)
  const resp = await page.request.get(`/filebrowser/d/${id}`)

  expect(resp.status(), `GET /filebrowser/d/<base64(${resolved})>`).toBe(200)
  expect(await resp.text()).toContain('regression')
})
