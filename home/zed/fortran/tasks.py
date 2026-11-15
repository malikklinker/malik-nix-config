"""Zed Fortran tasks with quoted argv and isolated compiler artifacts."""

import hashlib
import os
from pathlib import Path
import subprocess
import sys


def run(argv, cwd):
    print("+ " + " ".join(map(str, argv)), flush=True)
    subprocess.run(list(map(str, argv)), cwd=cwd, check=True)


def main():
    action, filename = sys.argv[1:]
    source = Path(filename).resolve(strict=True)
    if source.suffix.lower() not in {
        ".f",
        ".for",
        ".ftn",
        ".f77",
        ".f90",
        ".f95",
        ".f03",
        ".f08",
        ".f18",
        ".fpp",
    }:
        raise ValueError("Select a Fortran source file first.")
    if action.startswith("project-"):
        # Prefer the closest build definition, not an unrelated ancestor project.
        for directory in source.parents:
            if (directory / "fpm.toml").is_file():
                verb = {
                    "project-build": "build",
                    "project-run": "run",
                    "project-test": "test",
                }[action]
                run(["fortran-fpm", verb, "--profile", "debug"], directory)
                return
            if any(
                (directory / name).is_file()
                for name in ["GNUmakefile", "Makefile", "makefile"]
            ):
                if action != "project-build":
                    raise ValueError(
                        "Use your project's Make run/test target; this task only builds Make projects."
                    )
                run(["make"], directory)
                return
            if (directory / "CMakeLists.txt").is_file():
                if action != "project-build":
                    raise ValueError(
                        "Use your project's executable/CTest task; this task only builds CMake projects."
                    )
                build = directory / "build/zed-debug"
                run(
                    ["cmake", "-S", directory, "-B", build, "-DCMAKE_BUILD_TYPE=Debug"],
                    directory,
                )
                run(["cmake", "--build", build], directory)
                return
        raise ValueError(
            "No fpm.toml, Makefile, or CMakeLists.txt found above this file. Use a standalone task for a single-file program, or add a project build definition for multiple files."
        )

    cache = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache"))
    build = cache / "zed/fortran" / hashlib.sha256(os.fsencode(source)).hexdigest()[:16]
    build.mkdir(parents=True, exist_ok=True)
    flags = [
        "-g",
        "-O0",
        "-Wall",
        "-Wextra",
        "-Wimplicit-interface",
        "-fcheck=all",
        "-fbacktrace",
        "-J",
        build,
        "-I",
        source.parent,
    ]
    if source.suffix.lower() not in {".f", ".for", ".ftn", ".f77"}:
        flags += ["-ffree-line-length-none"]
    if action == "check":
        run(["gfortran", *flags, "-fsyntax-only", source], build)
    elif action in {"build", "run"}:
        executable = build / "program"
        run(["gfortran", *flags, source, "-o", executable], build)
        if action == "run":
            run([executable], source.parent)
    else:
        raise ValueError(f"Unknown action: {action}")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError) as error:
        print(f"Fortran: {error}", file=sys.stderr)
        sys.exit(1)
    except subprocess.CalledProcessError as error:
        sys.exit(error.returncode)
