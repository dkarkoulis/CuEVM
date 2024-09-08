#include <gtest/gtest.h>
#include <CuCrypto/blake2.cuh>
#include <cuda_runtime.h>

__global__ void blake2f_kernel(uint64_t* rounds, uint64_t* d_h, const uint64_t* d_m, uint64_t* d_t, int32_t* d_f) {
    CuCrypto::blake2::blake2f(*rounds, d_h, d_m, d_t, *d_f);
}

TEST(Blake2Test, Blake2fGPU) {
    uint64_t rounds = 0;
    uint64_t *d_rounds;
    cudaMalloc(&d_rounds, sizeof(rounds));
    cudaMemcpy(d_rounds, &rounds, sizeof(rounds), cudaMemcpyHostToDevice);
    
    // h
    uint8_t h_bytes[64] = {
        0x48, 0xc9, 0xbd, 0xf2, 0x67, 0xe6, 0x09, 0x6a,
        0x3b, 0xa7, 0xca, 0x84, 0x85, 0xae, 0x67, 0xbb,
        0x2b, 0xf8, 0x94, 0xfe, 0x72, 0xf3, 0x6e, 0x3c,
        0xf1, 0x36, 0x1d, 0x5f, 0x3a, 0xf5, 0x4f, 0xa5,
        0xd1, 0x82, 0xe6, 0xad, 0x7f, 0x52, 0x0e, 0x51,
        0x1f, 0x6c, 0x3e, 0x2b, 0x8c, 0x68, 0x05, 0x9b,
        0x6b, 0xbd, 0x41, 0xfb, 0xab, 0xd9, 0x83, 0x1f,
        0x79, 0x21, 0x7e, 0x13, 0x19, 0xcd, 0xe0, 0x5b
    };
    // Copy uint8_t array to uint64_t array
    uint64_t h[8];
    memcpy(h, h_bytes, sizeof(h_bytes));
    uint64_t* d_h;
    cudaMalloc(&d_h, sizeof(h));
    cudaMemcpy(d_h, h, sizeof(h), cudaMemcpyHostToDevice);
    // m
    uint8_t m_bytes[128] = {
        0x61, 0x62, 0x63, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    };
    uint64_t m[16];
    memcpy(m, m_bytes, sizeof(m_bytes));
    uint64_t* d_m;
    cudaMalloc(&d_m, sizeof(m));
    cudaMemcpy(d_m, m, sizeof(m), cudaMemcpyHostToDevice);

    // t
    uint8_t t_bytes[64] = {
        0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    };
    uint64_t t[2] ;
    memcpy(t, t_bytes, sizeof(t_bytes));
    uint64_t* d_t;
    cudaMalloc(&d_t, sizeof(t));
    cudaMemcpy(d_t, t, sizeof(t), cudaMemcpyHostToDevice);

    // f
    int32_t f = 1;
    int32_t* d_f;
    cudaMalloc(&d_f, sizeof(f));
    cudaMemcpy(d_f, &f, sizeof(f), cudaMemcpyHostToDevice);

    // Launch kernel
    blake2f_kernel<<<1, 1>>>(d_rounds, d_h, d_m, d_t, d_f);
    cudaDeviceSynchronize();

    // Copy result back to host
    cudaMemcpy(h, d_h, sizeof(h), cudaMemcpyDeviceToHost);

    // Expected hash value
    uint8_t expected_h_bytes[64] = {
        0x08, 0xc9, 0xbc, 0xf3, 0x67, 0xe6, 0x09, 0x6a,
        0x3b, 0xa7, 0xca, 0x84, 0x85, 0xae, 0x67, 0xbb,
        0x2b, 0xf8, 0x94, 0xfe, 0x72, 0xf3, 0x6e, 0x3c,
        0xf1, 0x36, 0x1d, 0x5f, 0x3a, 0xf5, 0x4f, 0xa5,
        0xd2, 0x82, 0xe6, 0xad, 0x7f, 0x52, 0x0e, 0x51,
        0x1f, 0x6c, 0x3e, 0x2b, 0x8c, 0x68, 0x05, 0x9b,
        0x94, 0x42, 0xbe, 0x04, 0x54, 0x26, 0x7c, 0xe0,
        0x79, 0x21, 0x7e, 0x13, 0x19, 0xcd, 0xe0, 0x5b
    };
    uint64_t expected_hash[8];
    memcpy(expected_hash, expected_h_bytes, sizeof(expected_h_bytes));

    // Verify the computed hash matches the expected hash
    for (int i = 0; i < 8; i++) {
        EXPECT_EQ(h[i], expected_hash[i]);
    }

    // Free device memory
    cudaFree(d_rounds);
    cudaFree(d_h);
    cudaFree(d_m);
    cudaFree(d_t);
    cudaFree(d_f);
}
// Example test case for BLAKE2 from https://eips.ethereum.org/EIPS/eip-152

TEST(Blake2Test, ZeroRoundsAssertions) {
    // uint64_t rounds = 12;
    uint64_t rounds = 0;
    // uint64_t h[8] = {
    //     0x48c9bdf267e6096a, 0x3ba7ca8485ae67bb,
    //     0x2bf894fe72f36e3c, 0xf1361d5f3af54fa5,
    //     0xd182e6ad7f520e51, 0x1f6c3e2b8c68059b,
    //     0x6bbd41fbabd9831f, 0x79217e1319cde05b
    // };
    uint8_t h_bytes[64] = {
        0x48, 0xc9, 0xbd, 0xf2, 0x67, 0xe6, 0x09, 0x6a,
        0x3b, 0xa7, 0xca, 0x84, 0x85, 0xae, 0x67, 0xbb,
        0x2b, 0xf8, 0x94, 0xfe, 0x72, 0xf3, 0x6e, 0x3c,
        0xf1, 0x36, 0x1d, 0x5f, 0x3a, 0xf5, 0x4f, 0xa5,
        0xd1, 0x82, 0xe6, 0xad, 0x7f, 0x52, 0x0e, 0x51,
        0x1f, 0x6c, 0x3e, 0x2b, 0x8c, 0x68, 0x05, 0x9b,
        0x6b, 0xbd, 0x41, 0xfb, 0xab, 0xd9, 0x83, 0x1f,
        0x79, 0x21, 0x7e, 0x13, 0x19, 0xcd, 0xe0, 0x5b
    };
    // Copy uint8_t array to uint64_t array
    uint64_t h[8];
    memcpy(h, h_bytes, sizeof(h_bytes));

    uint8_t m_bytes[128] = {
        0x61, 0x62, 0x63, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    };

    uint64_t m[16];
    memcpy(m, m_bytes, sizeof(m_bytes));
    uint8_t t_bytes[64] = {
        0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    };
    uint64_t t[2] ;
    memcpy(t, t_bytes, sizeof(t_bytes));
    int32_t f = 1;

    // Compute the BLAKE2 hash
    CuCrypto::blake2::blake2f(rounds, h, m, t, f);

    // Expected hash value
    // uint64_t expected_hash[8] = {
    //     0xba80a53f981c4d0d, 0x6a2797b69f12f6e9,
    //     0x4c212f14685ac4b7, 0x4b12bb6fdbffa2d1,
    //     0x7d87c5392aab792d, 0xc252d5de4533cc95,
    //     0x18d38aa8dbf1925a, 0xb92386edd4009923
    // };
    uint8_t expected_h_bytes[64] = {
        0x08, 0xc9, 0xbc, 0xf3, 0x67, 0xe6, 0x09, 0x6a,
        0x3b, 0xa7, 0xca, 0x84, 0x85, 0xae, 0x67, 0xbb,
        0x2b, 0xf8, 0x94, 0xfe, 0x72, 0xf3, 0x6e, 0x3c,
        0xf1, 0x36, 0x1d, 0x5f, 0x3a, 0xf5, 0x4f, 0xa5,
        0xd2, 0x82, 0xe6, 0xad, 0x7f, 0x52, 0x0e, 0x51,
        0x1f, 0x6c, 0x3e, 0x2b, 0x8c, 0x68, 0x05, 0x9b,
        0x94, 0x42, 0xbe, 0x04, 0x54, 0x26, 0x7c, 0xe0,
        0x79, 0x21, 0x7e, 0x13, 0x19, 0xcd, 0xe0, 0x5b
    };
    uint64_t expected_hash[8];
    memcpy(expected_hash, expected_h_bytes, sizeof(expected_h_bytes));

    // Verify the computed hash matches the expected hash
    for (int i = 0; i < 8; i++) {
        EXPECT_EQ(h[i], expected_hash[i]);
    }
}