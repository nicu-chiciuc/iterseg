# Iterseg

An iterated function system experiment written in CoffeeScript and published as compiled browser
JavaScript.

The CoffeeScript sources and generated browser files are kept together. Cloudflare deploys the
browser files directly, so this project has no build step.

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
