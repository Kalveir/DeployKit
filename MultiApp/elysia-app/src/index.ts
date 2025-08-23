import { Elysia } from "elysia";
const app = new Elysia()
  .get("/", () => {
    return { message: "Hello Elysia" }; // Ini akan otomatis jadi JSON
  })
  .listen(8888);
console.log(
  `🦊 Elysia is running at ${app.server?.hostname}:${app.server?.port}`
);
