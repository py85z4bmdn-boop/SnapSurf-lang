# SnapSurf Gotchas

- Do not trust old NASM wording in docs as future direction. It describes the old implementation, not the target.
- Do not treat a single green command as completion. Re-run the failed command, then the nearest broader test, then full regression when build/codegen changed.
- Do not switch `Makefile` to a partial FASM compiler that cannot support the expected workflow unless the breakage is explicitly planned and checkpointed.
- Do not reintroduce root `Makefile`; root orchestration is CMake now.
- Do not use blind mechanical conversion as proof. FASM source must be audited per file and per routine.
- Do not let generated code silently keep NASM directives such as `global`, `section .text`, `default rel`, or `[rel ...]`.
- Do not parallelize dependent verification commands. Build -> file/run/strings must be sequential or the audit can produce a false failure.
- Do not use `fasm-smoke` or `check-discovery` as proof that full regression passes. They are narrow gates only.
