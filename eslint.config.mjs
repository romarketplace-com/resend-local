import nextCoreWebVitals from "eslint-config-next/core-web-vitals";
import eslintPluginUnusedImports from "eslint-plugin-unused-imports";

const eslintConfig = [
  {
    ignores: ["dist/**", "requests/**"],
  },
  ...nextCoreWebVitals,
  {
    plugins: {
      "unused-imports": eslintPluginUnusedImports,
    },
    rules: {
      "import/order": "error",
      "unused-imports/no-unused-imports": "error",
      "unused-imports/no-unused-vars": [
        "error",
        {
          vars: "all",
          varsIgnorePattern: "^_",
          args: "after-used",
          argsIgnorePattern: "^_",
        },
      ],
    },
  },
];

export default eslintConfig;
