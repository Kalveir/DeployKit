import { Hono } from 'hono'

const app = new Hono()

app.get('/', (c) => c.json({ message: 'hello world' }))

Deno.serve({ port: 8787 }, app.fetch)
