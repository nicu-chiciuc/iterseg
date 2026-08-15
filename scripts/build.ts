import { cp, mkdir, rm } from "node:fs/promises";

const repositoryRoot = new URL("../", import.meta.url);
const outputDirectory = new URL("../dist/", import.meta.url);
const deployablePaths = ["css/", "index.html", "js/", "main.js", "utils.js"] as const;

await rm(outputDirectory, { force: true, recursive: true });
await mkdir(outputDirectory, { recursive: true });

for (const deployablePath of deployablePaths) {
  await cp(new URL(deployablePath, repositoryRoot), new URL(deployablePath, outputDirectory), {
    recursive: true,
  });
}
