# Project Task Engine

The project task engine gives Neovim and external coding agents one deterministic interface for common C/C++ project operations.

## Contract

Supported actions are:

```text
configure
build
test
lint
format
```

Inside Neovim:

```vim
:ProjectInfo
:ProjectTask build
:ProjectConfigure
:ProjectBuild
:ProjectTest
:ProjectLint
:ProjectFormat
```

The same interface works headlessly, which is the intended integration point for future coding-agent instructions:

```bash
cd /path/to/project
NVIM_CPP_IDE_PROFILE=cpp nvim --headless '+ProjectTask build' +qa
```

A failed task exits headless Neovim with a non-zero status derived from the underlying process. Interactive runs are asynchronous and place collected output in the quickfix list.

## Backend detection

Detection is deterministic and uses the project root discovered from the current buffer or working directory.

Priority:

1. explicit `backend` in `.nvim-cpp-ide.json` or `NVIM_CPP_IDE_BACKEND`
2. CMake (`CMakePresets.json`, `CMakeUserPresets.json`, or `CMakeLists.txt`)
3. standalone Ninja (`build.ninja`)
4. Make (`Makefile` / `makefile`)

CMake is checked before Ninja so a generated `build.ninja` does not replace the owning CMake project semantics.

## Backend mapping

| Action | CMake | standalone Ninja | Make |
|---|---|---|---|
| `configure` | `cmake --preset ...` or `cmake -S ... -B ...` | unavailable | unavailable |
| `build` | `cmake --build ...` | `ninja -C <root>` | `make -C <root>` |
| `test` | `ctest --preset ...` or `ctest --test-dir ...` | `ninja -C <root> test` | `make -C <root> test` |
| `lint` | build target `lint` | target `lint` | target `lint` |
| `format` | build target `format` | target `format` | target `format` |

Projects whose lint/format target names differ should use task overrides.

## CMake Presets

When configure presets exist, the engine selects the first visible configure preset unless one is explicitly requested.

Environment overrides:

```text
NVIM_CPP_IDE_CMAKE_PRESET
NVIM_CPP_IDE_CMAKE_BUILD_PRESET
NVIM_CPP_IDE_CMAKE_TEST_PRESET
NVIM_CPP_IDE_BUILD_DIR
NVIM_CPP_IDE_CMAKE_GENERATOR
```

For build/test presets, the engine prefers a visible preset associated with the selected configure preset. If no build/test preset exists, it falls back to the configure preset's `binaryDir`.

## Project-local overrides

Create `.nvim-cpp-ide.json` in the project root when repository conventions differ from the defaults:

```json
{
  "backend": "cmake",
  "cmake": {
    "configure_preset": "dev",
    "build_preset": "dev",
    "test_preset": "dev"
  },
  "tasks": {
    "lint": ["cmake", "--build", "build/dev", "--target", "clang-tidy"],
    "format": {
      "argv": ["python", "tools/format.py"],
      "cwd": "."
    }
  }
}
```

Task overrides intentionally use argv arrays instead of opaque shell strings. This keeps execution cross-platform, avoids shell quoting differences, and gives coding agents an exact command contract.

## Keymaps

| Key | Action |
|---|---|
| `F6` | project test |
| `F7` | project build |
| `F8` | project configure |
| `<leader>pi` | project info |
| `<leader>pc` | configure |
| `<leader>pb` | build |
| `<leader>pt` | test |
| `<leader>pl` | lint |
| `<leader>pf` | format |

F9/F4 remain the compatibility path for compiling and running a single C/C++ file.

## Design boundary

This layer does not know about Codex, Claude Code, Gemini CLI, ACP, or MCP. It only resolves project semantics and executes tasks. The next agent layer can therefore consume one stable execution interface instead of embedding build-system-specific instructions in every prompt.
