# Iterseg

An iterated function system experiment written in CoffeeScript and published as compiled browser
JavaScript.

The CoffeeScript sources and generated browser files are kept together. The build copies the current
browser files without compiling them again.

## Local preview

Use Node.js 24 and pnpm 10.34.5.

```sh
pnpm install --frozen-lockfile
pnpm run preview
```

The preview is available at [http://localhost:8787](http://localhost:8787).

## Deployment

Cloudflare Workers Builds runs `pnpm run build`. It then runs `pnpm run deploy` for `master` or
`pnpm run deploy:preview` for another branch.
