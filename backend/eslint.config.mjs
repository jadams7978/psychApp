import js from "@eslint/js";
import importPlugin from "eslint-plugin-import";
import globals from "globals";

export default [
  { ignores: ["node_modules/**", "dist/**"] },
  {
    files: ["**/*.js"],
    languageOptions: {
      ecmaVersion: "latest",
      sourceType: "module",
      globals: {
        ...globals.node,   // <-- enables console, process, etc. for Node
      }
    },
    plugins: { import: importPlugin },
    rules: {
      ...js.configs.recommended.rules,
      "no-console": "off",
      "import/order": ["warn", { "newlines-between": "always", alphabetize: { order: "asc" } }]
    }
  }
];