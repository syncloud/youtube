import { test, expect } from '@playwright/test'
import { signIn } from '../helpers/auth'
import { ssh } from '../helpers/ssh'

test('clicking Download on a file in the filebrowser serves it (regression for #652)', async ({ page, context }) => {
  const filename = 'regression_filebrowser.bin'
  ssh(`echo regression > /data/youtube/${filename}`)
  ssh(`chown youtube:youtube /data/youtube/${filename}`)

  await signIn(page)
  await page.goto('/filebrowser')
  await expect(page.getByText(filename)).toBeVisible()

  const respPromise = context.waitForEvent('response', r => /\/filebrowser\/d\//.test(r.url()))
  await page.getByText(filename).click({ button: 'right' })
  await page.getByRole('menuitem', { name: 'Download' }).click()
  const resp = await respPromise

  expect(resp.status(), `GET ${resp.url()}`).toBe(200)
})
