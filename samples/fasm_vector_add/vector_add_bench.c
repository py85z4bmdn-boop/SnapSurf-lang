#define _POSIX_C_SOURCE 200809L

#include <errno.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#if defined(__GNUC__) || defined(__clang__)
#define SNAPSURF_NOINLINE __attribute__((noinline))
#else
#define SNAPSURF_NOINLINE
#endif

void snapsurf_vec_add_i32_sse2(
    int32_t *dst,
    const int32_t *a,
    const int32_t *b,
    size_t len);

typedef void (*add_i32_fn)(
    int32_t *dst,
    const int32_t *a,
    const int32_t *b,
    size_t len);

static volatile int64_t g_checksum_sink;

SNAPSURF_NOINLINE
static void scalar_add_i32(
    int32_t *dst,
    const int32_t *a,
    const int32_t *b,
    size_t len)
{
    for (size_t i = 0; i < len; i++) {
        dst[i] = a[i] + b[i];
    }
}

static uint64_t now_ns(void)
{
    struct timespec ts;

    if (clock_gettime(CLOCK_MONOTONIC, &ts) != 0) {
        perror("clock_gettime");
        exit(1);
    }

    return ((uint64_t)ts.tv_sec * 1000000000ULL) + (uint64_t)ts.tv_nsec;
}

static void *alloc_aligned(size_t alignment, size_t bytes)
{
    void *ptr = NULL;
    int rc = posix_memalign(&ptr, alignment, bytes);

    if (rc != 0) {
        fprintf(stderr, "posix_memalign: %s\n", strerror(rc));
        exit(1);
    }

    return ptr;
}

static void fill_inputs(int32_t *a, int32_t *b, size_t len)
{
    for (size_t i = 0; i < len; i++) {
        uint32_t x = ((uint32_t)i * 13U) ^ 0x5a5a5a5aU;
        uint32_t y = 0x10203040U - ((uint32_t)i * 7U);

        a[i] = (int32_t)x;
        b[i] = (int32_t)y;
    }
}

static int64_t checksum_i32(const int32_t *values, size_t len)
{
    int64_t acc = 0;

    for (size_t i = 0; i < len; i++) {
        acc += (int64_t)(values[i] ^ (int32_t)i);
    }

    return acc;
}

static void verify_equal(
    const int32_t *expected,
    const int32_t *actual,
    size_t len)
{
    for (size_t i = 0; i < len; i++) {
        if (expected[i] != actual[i]) {
            fprintf(
                stderr,
                "mismatch at %zu: expected=%" PRId32 " actual=%" PRId32 "\n",
                i,
                expected[i],
                actual[i]);
            exit(1);
        }
    }
}

static void verify_boundary_lengths(void)
{
    enum { capacity = 32 };
    int32_t a[capacity + 4];
    int32_t b[capacity + 4];
    int32_t scalar_out[capacity + 4];
    int32_t asm_out[capacity + 4];

    fill_inputs(a, b, capacity + 4);

    for (size_t offset = 0; offset < 3; offset++) {
        for (size_t len = 0; len <= 17; len++) {
            for (size_t i = 0; i < capacity + 4; i++) {
                scalar_out[i] = INT32_C(0x13572468);
                asm_out[i] = INT32_C(0x13572468);
            }

            scalar_add_i32(scalar_out + offset, a + offset, b + offset, len);
            snapsurf_vec_add_i32_sse2(asm_out + offset, a + offset, b + offset, len);
            verify_equal(scalar_out, asm_out, capacity + 4);
        }
    }
}

static uint64_t bench_i32(
    add_i32_fn fn,
    int32_t *dst,
    const int32_t *a,
    const int32_t *b,
    size_t len,
    size_t repeats)
{
    uint64_t best = UINT64_MAX;

    for (size_t i = 0; i < repeats; i++) {
        uint64_t start = now_ns();
        fn(dst, a, b, len);
        uint64_t elapsed = now_ns() - start;

        if (elapsed < best) {
            best = elapsed;
        }
    }

    g_checksum_sink ^= checksum_i32(dst, len);
    return best;
}

static double gib_per_second(size_t len, uint64_t ns)
{
    const double bytes_per_run = (double)len * (double)sizeof(int32_t) * 3.0;
    const double gib = bytes_per_run / (1024.0 * 1024.0 * 1024.0);

    return gib / ((double)ns / 1000000000.0);
}

int main(void)
{
    const size_t len = 1U << 20;
    const size_t repeats = 64;
    const size_t bytes = len * sizeof(int32_t);

    int32_t *a = alloc_aligned(64, bytes);
    int32_t *b = alloc_aligned(64, bytes);
    int32_t *scalar_out = alloc_aligned(64, bytes);
    int32_t *asm_out = alloc_aligned(64, bytes);

    fill_inputs(a, b, len);
    verify_boundary_lengths();

    scalar_add_i32(scalar_out, a, b, len);
    snapsurf_vec_add_i32_sse2(asm_out, a, b, len);
    verify_equal(scalar_out, asm_out, len);

    uint64_t scalar_ns = bench_i32(
        scalar_add_i32,
        scalar_out,
        a,
        b,
        len,
        repeats);
    uint64_t fasm_ns = bench_i32(
        snapsurf_vec_add_i32_sse2,
        asm_out,
        a,
        b,
        len,
        repeats);

    verify_equal(scalar_out, asm_out, len);

    printf("vector_add_i32_sse2: ok\n");
    printf("boundary_lengths=ok\n");
    printf("len=%zu repeats=%zu bytes_per_run=%zu\n", len, repeats, bytes * 3U);
    printf(
        "c_scalar_best_ns=%" PRIu64 " throughput_gib_s=%.2f\n",
        scalar_ns,
        gib_per_second(len, scalar_ns));
    printf(
        "fasm_sse2_best_ns=%" PRIu64 " throughput_gib_s=%.2f\n",
        fasm_ns,
        gib_per_second(len, fasm_ns));
    printf("fasm_speedup=%.2fx\n", (double)scalar_ns / (double)fasm_ns);
    printf("checksum=%" PRId64 "\n", g_checksum_sink);

    free(asm_out);
    free(scalar_out);
    free(b);
    free(a);

    return 0;
}
