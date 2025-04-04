// @ts-check

import globals from "globals";
import eslint from "@eslint/js";
import tseslint from "typescript-eslint";


export default tseslint.config(
    {
        extends: [
            eslint.configs.recommended,
            tseslint.configs.strict,
            tseslint.configs.stylistic,
        ],
        ignores: ["node_modules", "public", "app/assets/javascripts/{awesomplete,cable}.js"],
    },
    {
        languageOptions: { globals: globals.browser }
    }
);
