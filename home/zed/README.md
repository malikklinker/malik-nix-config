# Zed

The Home Manager module in `../zed.nix` installs Zed with writable settings and
keymaps. The shared desktop theme adapter generates `desktop-theme/zed.json`,
linked into Zed as the Desktop theme. Restart Zed if a palette change is not
reflected immediately.

Vim normal-mode shortcuts:

| Keys | Action |
| --- | --- |
| Space Space / Space f f | Find file |
| Space s g | Search project (editable multibuffer) |
| Space e | Focus project tree |
| Space b b | Switch buffer |
| Space c a / c r / c f | Code actions / rename / format |
| Space x x | Project diagnostics |
| Space g g | Git panel |
| Space z | Centered layout |

Launch with `zeditor /path/to/project`. New projects open in Restricted Mode;
trust your project through that indicator to enable language servers and tasks.
Nix, Rust, and C/C++ language servers use Nix store binaries.

## Fortran

`fortran.nix` installs a local development extension based on the pinned upstream
0.0.3 WASM package. It adds symbol outlines, bracket matching, Vim function/type
text objects, program run buttons, more file suffixes, and fixes the indentation
and highlight capture names. The Material icon theme provides Fortran file icons.
The upstream installation is backed up under `~/.local/share/zed/extensions-backups`.

Fortls provides completion, hover, signatures, definitions, references, rename,
diagnostics, and experimental code actions. Configure project source/include
paths and preprocessor definitions in `.fortlsrc` when needed. It does not replace
compiler diagnostics.

- `gs`: file symbols; `Ctrl+Shift+B`: outline panel.
- `gd`, `gA`, `cd`: definition, references, rename (stock Vim bindings).
- `Ctrl+Shift+I` or `Space c f`: format with fprettify, two-space indentation.
  Formatting is manual because fprettify targets modern free-form Fortran.
- `Alt+Shift+T`: task picker; search for `Fortran:`. `Alt+T` reruns the last task.
- Snippets: `program`, `module`, `subroutine`, `function`, `dtype`, `doloop`,
  `doconcurrent`, `selectcase`, `isoenv`, and `allocstat`.

Standalone build/run tasks use gfortran with debug symbols, warnings, runtime
checks, and a backtrace. Compiler artifacts stay under `~/.cache/zed/fortran`.
They compile only the selected file; multi-file projects should have an fpm,
Make, or CMake build definition. Project tasks find the closest definition above
the active file. Project run/test tasks support fpm; Make/CMake projects can add
their own executable and test tasks in `.zed/tasks.json`. The standalone run
button takes no program arguments; use a project task for argument-driven runs.

The local extension is intentionally pinned so an automatic upstream update
cannot overwrite these query fixes. Update the archive version/hash explicitly
when rebasing it. No debugger adapter is added by this configuration.

## Python environments

Select the scientific system Python environment with `toolchain: select`
in the command palette for coursework using NumPy, Matplotlib, SciPy, pandas,
or SymPy. Zed also discovers Python environments used by desktop services;
those may have a newer Python version but do not contain scientific packages.
The selection is saved per project and configures both Python tasks and import
resolution. For projects with their own virtual environment, select that instead.

`icons.nix` pins the Material icon theme with all file and folder icons recolored
to the desktop's muted blue-gray (`#8a98aa`). Shapes and transparency are retained.

The initial installation uses the user Nix profile to avoid switching unrelated
pending system changes. After a Home Manager rebuild installs Zed, the duplicate
user-profile entry can be removed with `nix profile remove zed-editor`.
