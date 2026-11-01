Please refer to [this][1] article in order to get more information.


  [1]: http://nicusor.org.md/iterseg


## Deployment

GitHub Actions runs `.github/workflows/alchemy.yml`. Pushes to `master` deploy the
existing `iterseg` Worker at https://iterseg.pfp.workers.dev. Pull requests from
this repository deploy `iterseg-pr-<number>` and get a comment with the preview
URL. Closing the pull request deletes its preview Worker. Forks get no secrets
and no preview.

There is no build. `.assetsignore` allows the HTML, JavaScript, CSS, and theme
images. The Alchemy stack is `nicu-chiciuc/iterseg`; its stage state is stored in
the `alchemy-state-store` project of Convex team `nicu`. Deployment needs the
repository secrets `CONVEX_ACCESS_TOKEN`, `CLOUDFLARE_API_TOKEN`, and
`CLOUDFLARE_ACCOUNT_ID`. The site itself has no Convex data or runtime secrets.

For the first migration of an existing Worker, dispatch Alchemy on `master` with
`adopt=true` and `plan=true`. Review the plan before dispatching with
`adopt=true` and `plan=false`. Production has a retain policy; the workflow
only destroys stages named `pr-<number>`. Workers Builds must be disabled after
adoption so GitHub Actions is the only deployer.
