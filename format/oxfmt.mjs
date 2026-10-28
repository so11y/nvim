import { readFile, readdir, access } from "node:fs/promises";
import { createRequire } from "node:module";
import { dirname, join, parse, extname } from "node:path";
import { pathToFileURL, fileURLToPath } from "node:url";
import { createInterface } from "node:readline";

const write = process.stdout.write.bind(process.stdout);
// Project JS configs may log while loading. Keep the response channel private.
process.stdout.write = process.stderr.write.bind(process.stderr);
const directory = dirname(fileURLToPath(import.meta.url));
const require = createRequire(join(process.cwd(), "package.json"));
let packageFile;
try {
  packageFile = require.resolve("oxfmt/package.json");
} catch (error) {
  if (error.code !== "MODULE_NOT_FOUND") throw error;
  packageFile = process.argv[2];
}
const oxfmtDirectory = dirname(packageFile);
const { format } = await import(
  pathToFileURL(join(oxfmtDirectory, "dist/index.js"))
);
const bundledPrettier = (await readdir(join(oxfmtDirectory, "dist"))).find(
  (name) => /^prettier-(?!plugin-)[\w-]+\.js$/.test(name)
);
if (!bundledPrettier)
  throw new Error(
    "This Oxfmt installation has no bundled Prettier configuration resolver."
  );
let prettier;
let projectPrettier;
try {
  projectPrettier = require.resolve("prettier");
} catch (error) {
  if (error.code !== "MODULE_NOT_FOUND") throw error;
}
prettier = projectPrettier
  ? require(projectPrettier)
  : await import(pathToFileURL(join(oxfmtDirectory, "dist", bundledPrettier)));
const schema = JSON.parse(
  await readFile(join(oxfmtDirectory, "configuration_schema.json"), "utf8")
);
const defaults = Object.fromEntries(
  (await prettier.getSupportInfo()).options
    .filter(
      (option) =>
        option.name in schema.properties && option.default !== undefined
    )
    .map((option) => [option.name, option.default])
);
defaults.sortPackageJson = false;
const parsers = {
  babel: "jsx",
  "babel-flow": "js",
  flow: "js",
  espree: "js",
  meriyah: "js",
  acorn: "js",
  typescript: "ts",
  "babel-ts": "ts",
  json: "json",
  "json-stringify": "json",
  json5: "json5",
  jsonc: "jsonc",
  css: "css",
  scss: "scss",
  less: "less",
  html: "html",
  vue: "vue",
  angular: "html",
  markdown: "md",
  mdx: "mdx",
  yaml: "yaml",
  graphql: "graphql"
};

async function findUp(filename, name) {
  for (let current = dirname(filename); ; current = dirname(current)) {
    const candidate = join(current, name);
    try {
      await access(candidate);
      return candidate;
    } catch (error) {
      if (error.code !== "ENOENT") throw error;
    }
    if (current === parse(current).root) return;
  }
}

async function formatDocument({ filename, source, fileformat }) {
  // These resolver calls bypass configuration caches, including newly created files.
  const ignorePath = await findUp(filename, ".prettierignore");
  const { ignored } = await prettier.getFileInfo(filename, {
    ignorePath,
    resolveConfig: false
  });
  if (ignored) return { ignored: true };
  const [standardConfig, customConfig] = await Promise.all([
    prettier.resolveConfigFile(filename),
    findUp(filename, "prettier.json")
  ]);
  const config =
    customConfig &&
    (!standardConfig ||
      dirname(customConfig).length >= dirname(standardConfig).length)
      ? customConfig
      : standardConfig;
  let options = await prettier.resolveConfig(filename, {
    config,
    editorconfig: true,
    useCache: false
  });
  if (options === null) {
    options = await prettier.resolveConfig(filename, {
      config: join(directory, "prettier.json"),
      editorconfig: true,
      useCache: false
    });
  }
  options = { ...defaults, ...options };
  let formatFilename = filename;
  if (options.parser) {
    const extension = parsers[options.parser];
    if (!extension)
      throw new Error(
        "Oxfmt does not support the configured Prettier parser: " +
          options.parser
      );
    const actualExtension = extname(filename).slice(1);
    if (
      actualExtension !== extension &&
      !(options.parser === "typescript" && actualExtension === "tsx")
    ) {
      formatFilename += "." + extension;
    }
    delete options.parser;
  }
  if (options.endOfLine === "auto") {
    options.endOfLine = { dos: "crlf", mac: "cr", unix: "lf" }[fileformat];
  }
  if (options.jsxBracketSameLine !== undefined) {
    options.bracketSameLine ??= options.jsxBracketSameLine;
    delete options.jsxBracketSameLine;
  }
  if (options.experimentalTernaries === false)
    delete options.experimentalTernaries;
  if (options.printWidth === Infinity) {
    throw new Error(
      "Oxfmt cannot represent max_line_length = off (unbounded printWidth)."
    );
  }
  if (options.plugins?.length) {
    throw new Error(
      "Oxfmt cannot load Prettier plugins: " + options.plugins.join(", ")
    );
  }
  delete options.plugins;
  delete options.$schema;
  delete options.filepath;
  for (const key of Object.keys(options)) {
    if (!(key in schema.properties)) {
      throw new Error(
        "Oxfmt does not support the configured Prettier option: " + key
      );
    }
  }
  const result = await format(formatFilename, source, options);
  if (result.errors.length) {
    throw new Error(
      result.errors.map((error) => error.codeframe || error.message).join("\n")
    );
  }
  return { code: result.code };
}

let requests = Promise.resolve();
for await (const line of createInterface({
  input: process.stdin,
  crlfDelay: Infinity
})) {
  requests = requests.then(async () => {
    const { id, ...request } = JSON.parse(line);
    let result;
    try {
      result = await formatDocument(request);
    } catch (error) {
      result = { error: error.message };
    }
    write(JSON.stringify({ id, ...result }) + "\n");
  });
}
await requests;
