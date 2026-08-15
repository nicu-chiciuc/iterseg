# Iterseg

An iterated function system experiment written in CoffeeScript and published as compiled browser
JavaScript.

The CoffeeScript sources stay at the repository root. The deployable browser files are in
`public/`. The standard build command validates the generated JavaScript but creates no output.
Cloudflare serves `public/` directly.

## Local preview

Use pnpm 10.34.5.

```sh
pnpm install --frozen-lockfile
pnpm run check
pnpm run preview
```

The preview is available at [http://localhost:8787](http://localhost:8787).

## Deployment

Cloudflare Workers Builds runs `pnpm run build` before `pnpm run deploy` for `master` or
`pnpm run deploy:preview` for another branch.
