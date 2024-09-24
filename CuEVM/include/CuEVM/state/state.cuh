// CuEVM: CUDA Ethereum Virtual Machine implementation
// Copyright 2023 Stefan-Dan Ciocirlan (SBIP - Singapore Blockchain Innovation
// Programme) Author: Stefan-Dan Ciocirlan Date: 2023-11-30
// SPDX-License-Identifier: MIT

#pragma once

#include <cjson/cJSON.h>

#include <CuEVM/core/byte_array.cuh>
#include <CuEVM/state/account.cuh>
#include <CuEVM/utils/arith.cuh>

namespace CuEVM {
/**
 * The state struct.
 * It contains the accounts and the number of accounts.
 */
struct state_t {
    CuEVM::account_t *accounts; /**< The accounts */
    uint32_t no_accounts;       /**< The number of accounts */

    /**
     * The default constructor.
     * It initializes the accounts to nullptr and the no_accounts to 0.
     */
    __host__ __device__ state_t() : accounts(nullptr), no_accounts(0) {}

    /**
     * The constructor with the accounts and the number of accounts.
     * @param[in] accounts The accounts.
     * @param[in] no_accounts The number of accounts.
     */
    __host__ __device__ state_t(CuEVM::account_t *accounts,
                                uint32_t no_accounts)
        : accounts(accounts), no_accounts(no_accounts) {}

    /**
     * The destructor.
     */
    __host__ __device__ ~state_t();

    /**
     * Free the internal memory of the state.
     */
    __host__ __device__ void free();

    /**
     * Free the internal memory of a managed state.
     */
    __host__ void free_managed();

    /**
     * Clear the internal memory of the state.
     */
    __host__ __device__ void clear();

    /**
     * The copy constructor.
     * @param[in] other The other state.
     */
    __host__ __device__ state_t(const state_t &other);

    /**
     * The assignment operator.
     * @param[in] other The other state.
     * @return The current state.
     */
    __host__ __device__ state_t &operator=(const state_t &other);

    /**
     * The duplicate function.
     * @param[in] other The other state.
     */
    __host__ __device__ void duplicate(const state_t &other);

    /**
     * The get account index function.
     * @param[in] arith The arithmetic environment.
     * @param[in] address The address.
     * @param[out] index The index.
     * @return If found 0. otherwise error.
     */
    __host__ __device__ int32_t get_account_index(ArithEnv &arith,
                                                  const bn_t &address,
                                                  uint32_t &index);

    /**
     * The get account function.
     * @param[in] arith The arithmetic environment.
     * @param[in] address The address.
     * @param[out] account The account.
     * @return If found 0. otherwise error.
     */
    __host__ __device__ int32_t get_account(ArithEnv &arith,
                                            const bn_t &address,
                                            CuEVM::account_t &account);

    /**
     * The get account function.
     * @param[in] arith The arithmetic environment.
     * @param[in] address The address.
     * @param[out] account_ptr The account pointer.
     * @return If found 0. otherwise error.
     */
    __host__ __device__ int32_t get_account(ArithEnv &arith,
                                            const bn_t &address,
                                            CuEVM::account_t *&account_ptr);

    /**
     * The add account function.
     * @param[in] account The account.
     * @return If added 0. otherwise error.
     */
    __host__ __device__ int32_t add_account(const CuEVM::account_t &account);

    /**
     * The set account function.
     * @param[in] arith The arithmetic environment.
     * @param[in] account The account.
     * @return If set 0. otherwise error.
     */
    __host__ __device__ int32_t set_account(ArithEnv &arith,
                                            const CuEVM::account_t &account);

    /**
     * The has account function.
     * @param[in] arith The arithmetic environment.
     * @param[in] address The address.
     * @return If has 1. otherwise 0.
     */
    __host__ __device__ int32_t has_account(ArithEnv &arith,
                                            const bn_t &address);

    /**
     * The update account function.
     * @param[in] arith The arithmetic environment.
     * @param[in] account The account.
     * @return If updated 0. otherwise error.
     */
    __host__ __device__ int32_t update_account(ArithEnv &arith,
                                               const CuEVM::account_t &account);

    /**
     * Get the account from the JSON.
     * @param[in] state_json The state JSON.
     * @param[in] managed The managed flag.
     * @return If successful 1. otherwise 0.
     */
    __host__ int32_t from_json(const cJSON *state_json, int32_t managed = 0);

    /**
     * The print function.
     * It prints the state.
     */
    __host__ __device__ void print();

    /**
     * The to JSON function.
     * @return The JSON.
     */
    __host__ cJSON *to_json();
};

}  // namespace CuEVM