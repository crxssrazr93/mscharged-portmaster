// Equivalence + timing harness: reference decoder (THPDec_orig) vs new decoder (THPDec_new).
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <chrono>
#include <random>
#include <vector>
extern "C" {
typedef int32_t s32;
int32_t THPVideoDecode(const void*, void*, void*, void*, void*);
int32_t THPVideoDecode_orig(const void*, void*, void*, void*, void*);
int32_t AuroraTHPVideoDecodeBounded(const void*, size_t, void*, size_t, void*, size_t, void*, size_t, uint32_t, uint32_t);
int32_t AuroraTHPVideoDecodeBounded_orig(const void*, size_t, void*, size_t, void*, size_t, void*, size_t, uint32_t, uint32_t);
}
using Bytes = std::vector<uint8_t>;
static void put16(Bytes& b, unsigned v) { b.push_back(v >> 8); b.push_back(v & 255); }

struct Table { int counts[17]; Bytes symbols; };
// Canonical table: rank i (priority order) gets length floor(log2(i+1)) + bias.
static Table make_table(int bias, const Bytes& symbols) {
  Table t{}; size_t n = symbols.size();
  for (size_t i = 0; i < n; ++i) { int len = bias; for (size_t v = i + 1; v > 1; v >>= 1) ++len; if (len > 16) { n = i; break; } ++t.counts[len]; }
  t.symbols.assign(symbols.begin(), symbols.begin() + n);
  // complete the code space with duplicates of the first symbol at the longest length
  int L = 16; while (L > 1 && t.counts[L] == 0) --L;
  long used = 0; for (int l = 1; l <= L; ++l) used += (long)t.counts[l] << (L - l);
  long rest = (1L << L) - used;
  while (rest > 0 && t.counts[L] < 255) { ++t.counts[L]; t.symbols.push_back(symbols[0]); --rest; }
  return t;
}
static void put_dht(Bytes& b, int cls, int id, const Table& t) {
  b.push_back(0xFF); b.push_back(0xC4);
  put16(b, 2 + 1 + 16 + t.symbols.size());
  b.push_back((cls << 4) | id);
  for (int l = 1; l <= 16; ++l) b.push_back(t.counts[l]);
  b.insert(b.end(), t.symbols.begin(), t.symbols.end());
}

struct Stream { Bytes data; unsigned w, h; };
static Stream make_stream(std::mt19937& rng, unsigned w, unsigned h, int mode, unsigned restart, size_t scanBytes, bool realistic) {
  Stream s; s.w = w; s.h = h; Bytes& b = s.data;
  b = {0xFF, 0xD8};
  // quant tables 0,1
  for (int id = 0; id < 2; ++id) {
    b.push_back(0xFF); b.push_back(0xDB); put16(b, 67); b.push_back(id);
    for (int i = 0; i < 64; ++i) b.push_back(realistic ? 1 + (i / 4) + id * 2 + (rng() % 3) : 1 + rng() % 255);
  }
  b.push_back(0xFF); b.push_back(0xC0); put16(b, 17); b.push_back(8); put16(b, h); put16(b, w); b.push_back(3);
  b.push_back(1); b.push_back(0x22); b.push_back(0); b.push_back(2); b.push_back(0x11); b.push_back(1); b.push_back(3); b.push_back(0x11); b.push_back(1);
  // DC table: symbols 0..11
  Bytes dcs; for (int i = 0; i < 12; ++i) dcs.push_back(i);
  Table dc = make_table(realistic ? 2 : 3, dcs);
  // AC: priority order; EOB first, small sizes first
  Bytes acs; acs.push_back(0x00);
  for (int sz = 1; sz <= (mode == 0 ? 8 : 15); ++sz) for (int run = 0; run < 16; ++run) if (mode == 2 || run <= 3) acs.push_back(run << 4 | sz);
  acs.push_back(0xF0);
  Table ac = make_table(mode == 2 ? 4 : 3, acs);
  double kraft = 0; for (int l = 1; l <= 16; ++l) kraft += ac.counts[l] / double(1u << l);
  if (kraft > 1.0) { fprintf(stderr, "bad table %f\n", kraft); exit(2); }
  put_dht(b, 0, 0, dc); put_dht(b, 0, 1, dc); put_dht(b, 1, 0, ac); put_dht(b, 1, 1, ac);
  if (restart) { b.push_back(0xFF); b.push_back(0xDD); put16(b, 4); put16(b, restart); }
  b.push_back(0xFF); b.push_back(0xDA); put16(b, 12); b.push_back(3);
  b.push_back(1); b.push_back(0x00); b.push_back(2); b.push_back(0x11); b.push_back(3); b.push_back(0x11);
  b.push_back(0); b.push_back(63); b.push_back(0);
    // scan data: random bits; realistic mode biases toward zeros so most blocks end early / are sparse
  for (size_t i = 0; i < scanBytes; ++i) {
    uint8_t v = rng();
    if (realistic) v &= rng(); // fewer ones
    b.push_back(v);
  }
  return s;
}
static size_t tiled(size_t w, size_t h) { return ((w + 7) / 8) * ((h + 3) / 4) * 32; }
static double now() { return std::chrono::duration<double>(std::chrono::steady_clock::now().time_since_epoch()).count(); }

int main(int argc, char** argv) {
  int seeds = argc > 1 ? atoi(argv[1]) : 300;
  int ok_frames = 0, fail_frames = 0, mismatches = 0;
  std::mt19937 rng(12345);
  for (int seed = 0; seed < seeds; ++seed) {
    static const unsigned dims[][2] = {{640, 480}, {64, 48}, {16, 16}, {100, 76}, {8, 8}, {24, 40}, {17, 33}, {320, 240}, {630, 478}};
    auto d = dims[rng() % 9];
    int mode = rng() % 10 < 5 ? 0 : rng() % 10 < 7 ? 1 : 2; bool real = mode != 2;
    unsigned mcus = ((d[0] + 15) / 16) * ((d[1] + 15) / 16);
    unsigned restart = (rng() % 5 == 0) ? 1 + rng() % 7 : 0;
    size_t bytes = size_t(mcus) * (real ? 40 : 300) + 64;
    Stream s = make_stream(rng, d[0], d[1], mode, restart, bytes, real);
    size_t cut = s.data.size();
    bool bounded = rng() % 2;
    if (bounded && rng() % 3 == 0) cut = s.data.size() - rng() % (bytes / 2 + 1); // truncated input
    size_t ys = tiled(d[0], d[1]), cs = tiled((d[0] + 1) / 2, (d[1] + 1) / 2);
    Bytes a[3] = {Bytes(ys, 0xAA), Bytes(cs, 0xAA), Bytes(cs, 0xAA)};
    Bytes b[3] = {a[0], a[1], a[2]};
    int ra, rb;
    if (bounded) {
      ra = AuroraTHPVideoDecodeBounded_orig(s.data.data(), cut, a[0].data(), ys, a[1].data(), cs, a[2].data(), cs, d[0], d[1]);
      rb = AuroraTHPVideoDecodeBounded(s.data.data(), cut, b[0].data(), ys, b[1].data(), cs, b[2].data(), cs, d[0], d[1]);
    } else {
      // unbounded reads need slack behind the data
      s.data.resize(s.data.size() + 64, 0);
      ra = THPVideoDecode_orig(s.data.data(), a[0].data(), a[1].data(), a[2].data(), nullptr);
      rb = THPVideoDecode(s.data.data(), b[0].data(), b[1].data(), b[2].data(), nullptr);
    }
    bool same = ra == rb;
    if (same && ra == 0) same = a[0] == b[0] && a[1] == b[1] && a[2] == b[2];
    if (ra == 0) ++ok_frames; else ++fail_frames;
    if (getenv("V")) printf("seed %d mode %d %ux%u bounded=%d cut=%zu/%zu restart=%u ra=%d rb=%d\n", seed, mode, d[0], d[1], bounded, cut, s.data.size(), restart, ra, rb);
    if (!same) { ++mismatches; printf("MISMATCH seed=%d %ux%u real=%d bounded=%d cut=%zu/%zu restart=%u ra=%d rb=%d\n", seed, d[0], d[1], real, bounded, cut, s.data.size(), restart, ra, rb); }
  }
  printf("equivalence: %d ok frames, %d failing frames, %d mismatches\n", ok_frames, fail_frames, mismatches);

  // timing on a realistic 640x480 stream that decodes fully
  for (int attempt = 0; attempt < 200; ++attempt) {
    Stream s = make_stream(rng, 640, 480, 0, 0, 1200 * 90, true);
    s.data.resize(s.data.size() + 64, 0);
    size_t ys = tiled(640, 480), cs = tiled(320, 240);
    Bytes a[3] = {Bytes(ys), Bytes(cs), Bytes(cs)}, b[3] = {Bytes(ys), Bytes(cs), Bytes(cs)};
    if (THPVideoDecode_orig(s.data.data(), a[0].data(), a[1].data(), a[2].data(), nullptr) != 0) continue;
    int N = 20;
    double t0 = now(); for (int i = 0; i < N; ++i) THPVideoDecode_orig(s.data.data(), a[0].data(), a[1].data(), a[2].data(), nullptr);
    double t1 = now(); for (int i = 0; i < N; ++i) THPVideoDecode(s.data.data(), b[0].data(), b[1].data(), b[2].data(), nullptr);
    double t2 = now();
    printf("timing 640x480 (%zu bytes): orig %.3f ms/frame, new %.3f ms/frame, equal=%d\n", s.data.size(), (t1 - t0) / N * 1e3, (t2 - t1) / N * 1e3, (int)(a[0] == b[0] && a[1] == b[1] && a[2] == b[2]));
    break;
  }
  return mismatches != 0;
}
