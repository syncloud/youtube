import { test, expect } from '@playwright/test'
import { signIn } from '../helpers/auth'
import { ssh } from '../helpers/ssh'

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
