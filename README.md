# Iterseg

An iterated function system experiment written in CoffeeScript and published as compiled browser
JavaScript.

The CoffeeScript sources stay at the repository root. The deployable browser files are in
`public/`. Cloudflare serves that directory directly, so this project has no build step.

## Local preview

Use pnpm 10.34.5.

```sh
pnpm install --frozen-lockfile
pnpm run check
pnpm run preview
```

The preview is available at [http://localhost:8787](http://localhost:8787).

## Deployment

Cloudflare Workers Builds leaves its optional build command empty. It runs `pnpm run deploy` for
`master` or `pnpm run deploy:preview` for another branch.
