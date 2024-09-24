// CuEVM: CUDA Ethereum Virtual Machine implementation
// Copyright 2023 Stefan-Dan Ciocirlan (SBIP - Singapore Blockchain Innovation
// Programme) Author: Stefan-Dan Ciocirlan Date: 2024-09-15
// SPDX-License-Identifier: MIT

#include <CuEVM/state/contract_storage.cuh>
#include <CuEVM/utils/error_codes.cuh>

namespace CuEVM {

__host__ __device__ contract_storage_t::~contract_storage_t() { clear(); }

__host__ __device__ void contract_storage_t::free() {
    __ONE_GPU_THREAD_BEGIN__
    if (storage != nullptr && capacity > 0) {
        delete[] storage;
    }
    __ONE_GPU_THREAD_END__
    clear();
}

__host__ void contract_storage_t::free_managed() {
    if (storage != nullptr && capacity > 0) {
        CUDA_CHECK(cudaFree(storage));
    }
    clear();
}

__host__ __device__ void contract_storage_t::clear() {
    storage = nullptr;
    size = 0;
    capacity = 0;
}

__host__ __device__ contract_storage_t &contract_storage_t::operator=(
    const contract_storage_t &other) {
    __SHARED_MEMORY__ storage_element_t *tmp_storage;
    if (this == &other) {
        return *this;
    }
    if (capacity != other.capacity) {
        free();
        size = other.size;
        capacity = other.capacity;
        __ONE_GPU_THREAD_BEGIN__
        if (capacity > 0) {
            tmp_storage = new storage_element_t[capacity];
        }
        __ONE_GPU_THREAD_END__
        storage = tmp_storage;
    }
    __ONE_GPU_THREAD_BEGIN__
    if (other.size > 0)
        memcpy(storage, other.storage, other.size * sizeof(storage_element_t));
    __ONE_GPU_THREAD_END__
    return *this;
}

__host__ __device__ int32_t contract_storage_t::get_value(ArithEnv &arith,
                                                          const bn_t &key,
                                                          bn_t &value) const {
    uint32_t idx = 0;
    for (idx = 0; idx < size; idx++) {
        if (storage[idx].has_key(arith, key)) {
            storage[idx].get_value(arith, value);
            return ERROR_SUCCESS;
        }
    }
    return ERROR_STORAGE_KEY_NOT_FOUND;
}

__host__ __device__ int32_t contract_storage_t::set_value(ArithEnv &arith,
                                                          const bn_t &key,
                                                          const bn_t &value) {
    __SHARED_MEMORY__ storage_element_t *new_storage;
    uint32_t idx;
    for (idx = 0; idx < size; idx++) {
        if (storage[idx].has_key(arith, key)) {
            storage[idx].set_value(arith, value);
            return ERROR_SUCCESS;
        }
    }
    if (size >= capacity) {
        if (capacity == 0) {
            capacity = CuEVM::initial_storage_capacity;
        } else {
            capacity *= 2;
        }
        __ONE_GPU_THREAD_BEGIN__
        new_storage = new storage_element_t[capacity];
        memcpy(new_storage, storage, size * sizeof(storage_element_t));
        delete[] storage;
        __ONE_GPU_THREAD_END__
        storage = new_storage;
    }
    storage[size].set_key(arith, key);
    storage[size].set_value(arith, value);
    size++;
    return ERROR_SUCCESS;
}

__host__ __device__ void contract_storage_t::update(
    ArithEnv &arith, const contract_storage_t &other) {
    bn_t key, value;
    for (uint32_t idx = 0; idx < other.size; idx++) {
        cgbn_load(arith.env, key, (cgbn_evm_word_t_ptr)&other.storage[idx].key);
        cgbn_load(arith.env, value,
                  (cgbn_evm_word_t_ptr)&other.storage[idx].value);
        set_value(arith, key, value);
    }
}

__host__ int32_t contract_storage_t::from_json(
    const cJSON *contract_storage_json, int32_t managed) {
    if (cJSON_IsNull(contract_storage_json) ||
        cJSON_IsInvalid(contract_storage_json) /*||
        (!cJSON_IsArray(contract_storage_json))*/
    ) {
        return ERROR_INVALID_JSON;
    }
    size = cJSON_GetArraySize(contract_storage_json);
    if (size == 0) {
        capacity = 0;
        storage = nullptr;
        return ERROR_SUCCESS;
    }
    capacity = CuEVM::initial_storage_capacity;
    do {
        capacity *= 2;
    } while (capacity < size);
    if (managed) {
        CUDA_CHECK(
            cudaMallocManaged(&storage, capacity * sizeof(storage_element_t)));
    } else {
        storage = new storage_element_t[capacity];
    }
    cJSON *element_json = nullptr;
    uint32_t idx = 0;
    cJSON_ArrayForEach(element_json, contract_storage_json) {
        storage[idx].from_json(element_json);
        idx++;
    }
    return 0;
}

__host__ cJSON *contract_storage_t::to_json(int32_t pretty) const {
    cJSON *contract_storage_json = cJSON_CreateObject();
    if (size == 0) {
        return contract_storage_json;
    }
    uint32_t idx = 0;
    char *key_string_ptr = new char[CuEVM::word_size * 2 + 3];
    char *value_string_ptr = new char[CuEVM::word_size * 2 + 3];
    for (idx = 0; idx < size; idx++) {
        storage[idx].add_to_json(contract_storage_json, key_string_ptr,
                                 value_string_ptr, pretty);
    }
    delete[] key_string_ptr;
    delete[] value_string_ptr;
    return contract_storage_json;
}

__host__ __device__ void contract_storage_t::print() const {
    __ONE_GPU_THREAD_WOSYNC_BEGIN__
    printf("Storage size: %u\n", size);
    for (uint32_t idx = 0; idx < size; idx++) {
        printf("Element %u:\n", idx);
        storage[idx].print();
    }
    __ONE_GPU_THREAD_WOSYNC_END__
}

__host__ int32_t contract_storage_t::has_key(const evm_word_t &key,
                                             uint32_t &index) const {
    for (index = 0; index < size; index++) {
        if (storage[index].has_key(key)) {
            return ERROR_SUCCESS;
        }
    }
    return ERROR_STORAGE_KEY_NOT_FOUND;
}

__host__ cJSON *contract_storage_t::merge_json(
    const contract_storage_t &storage1, const contract_storage_t &storage2,
    const int32_t pretty) {
    cJSON *storage_json = cJSON_CreateObject();
    uint8_t *written = new uint8_t[storage2.size];
    memset(written, 0, storage2.size);
    char *key_string_ptr = new char[CuEVM::word_size * 2 + 3];
    char *value_string_ptr = new char[CuEVM::word_size * 2 + 3];
    for (uint32_t idx = 0; idx < storage1.size; idx++) {
        uint32_t jdx;
        if (storage2.has_key(storage1.storage[idx].key, jdx) == ERROR_SUCCESS) {
            storage2.storage[jdx].key.to_hex(key_string_ptr, pretty);
            storage2.storage[jdx].value.to_hex(value_string_ptr, pretty);
            written[jdx] = 1;
        } else {
            storage1.storage[idx].key.to_hex(key_string_ptr, pretty);
            storage1.storage[idx].value.to_hex(value_string_ptr, pretty);
        }

        // if value is different than 0
        if (value_string_ptr[2] != '0' || value_string_ptr[3] != '\0') {
            cJSON_AddStringToObject(storage_json, key_string_ptr,
                                    value_string_ptr);
        }
    }

    for (uint32_t jdx = 0; jdx < storage2.size; jdx++) {
        if (written[jdx] == 0) {
            storage2.storage[jdx].key.to_hex(key_string_ptr, pretty);
            storage2.storage[jdx].value.to_hex(value_string_ptr, pretty);
            if (value_string_ptr[2] != '0' || value_string_ptr[3] != '\0') {
                cJSON_AddStringToObject(storage_json, key_string_ptr,
                                        value_string_ptr);
            }
        }
    }
    delete[] written;
    delete[] key_string_ptr;
    delete[] value_string_ptr;
    return storage_json;
}

__host__ __device__ void contract_storage_t::transfer_memory(
    contract_storage_t &src, contract_storage_t &dst) {
    if ((src.size > 0) && (src.storage != nullptr) && (src.capacity > 0)) {
        memcpy(dst.storage, src.storage, src.size * sizeof(storage_element_t));
        dst.size = src.size;
        dst.capacity = src.size;
    } else {
        // TODO: check if this is necessary
        dst.size = 0;
    }
    src.free();
}
}  // namespace CuEVM