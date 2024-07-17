// cuEVM: CUDA Ethereum Virtual Machine implementation
// Copyright 2023 Stefan-Dan Ciocirlan (SBIP - Singapore Blockchain Innovation Programme)
// Author: Stefan-Dan Ciocirlan
// Data: 2023-11-30
// SPDX-License-Identifier: MIT

#include <CuCrypto/keccak.cuh>

#include "../include/operations/environmental.cuh"
#include "../include/gas_cost.cuh"
#include "../include/utils/error_codes.cuh"
#include "../include/core/byte_array.cuh"

namespace cuEVM::operations {
    __host__ __device__ int32_t SHA3(
        ArithEnv &arith,
        const bn_t &gas_limit,
        bn_t &gas_used,
        cuEVM::stack::evm_stack_t &stack,
        cuEVM::memory::evm_memory_t &memory)
    {
        cgbn_add_ui32(arith.env, gas_used, gas_used, GAS_KECCAK256);
        int32_t error_code = cuEVM::gas_cost::has_gas(
            arith,
            gas_limit,
            gas_used);
        if (error_code == ERROR_SUCCESS) {
            // Get the offset and length from the stack
            bn_t offset, length;
            error_code |= stack.pop(arith, offset);
            error_code |= stack.pop(arith, length);

            cuEVM::gas_cost::keccak_cost(
                arith,
                gas_used,
                length);
            
            bn_t memory_expansion_cost;
            // Get the memory expansion gas cost
            error_code |= cuEVM::gas_cost::memory_grow_cost(
                arith,
                memory,
                offset,
                length,
                memory_expansion_cost,
                gas_used);
            
            error_code |= cuEVM::gas_cost::has_gas(
                arith,
                gas_limit,
                gas_used);

            if (error_code == ERROR_SUCCESS)
            {
                memory.increase_memory_cost(arith, memory_expansion_cost);
                cuEVM::byte_array_t memory_input;
                error_code |= memory.get(
                    arith,
                    offset,
                    length,
                    memory_input);
                cuEVM::byte_array_t hash(cuEVM::hash_size);
                if (error_code == ERROR_SUCCESS)
                {
                    CuCrypto::keccak::sha3(
                        memory_input.data,
                        memory_input.size,
                        hash.data,
                        hash.size);
                    bn_t hash_bn;
                    hash.to_bn_t(
                        arith,
                        hash_bn);

                    error_code |= stack.push(arith, hash_bn);
                }
            }
        }
        return error_code;
    }

    __host__ __device__ int32_t ADDRESS(
        ArithEnv &arith,
        const bn_t &gas_limit,
        bn_t &gas_used,
        cuEVM::stack::evm_stack_t &stack,
        const cuEVM::evm_message_call_t &message)
    {
        cgbn_add_ui32(arith.env, gas_used, gas_used, GAS_BASE);
        int32_t error_code = cuEVM::gas_cost::has_gas(
            arith,
            gas_limit,
            gas_used);
        if (error_code == ERROR_SUCCESS)
        {
            bn_t recipient_address;
            message.get_recipient(arith, recipient_address);

            error_code |= stack.push(arith, recipient_address);
        }
        return error_code;
    }

    __host__ __device__ int32_t BALANCE(
        ArithEnv &arith,
        const bn_t &gas_limit,
        bn_t &gas_used,
        cuEVM::stack::evm_stack_t &stack,
        const cuEVM::state::AccessState &access_state,
        cuEVM::state::TouchState &touch_state)
    {
        // cgbn_add_ui32(arith.env, gas_used, gas_used, GAS_ZERO);
        bn_t address;
        int32_t error_code = stack.pop(arith, address);
        cuEVM::evm_address_conversion(arith, address);
        error_code |= cuEVM::gas_cost::access_account_cost(
            arith,
            gas_used,
            access_state,
            address);
        error_code |= cuEVM::gas_cost::has_gas(
            arith,
            gas_limit,
            gas_used);
        
        if (error_code == ERROR_SUCCESS) {
            bn_t balance;
            touch_state.get_balance(
                arith,
                address,
                balance);

            error_code |= stack.push(arith, balance);
        }
        return error_code;
    }

    __host__ __device__ int32_t ORIGIN(
        ArithEnv &arith,
        const bn_t &gas_limit,
        bn_t &gas_used,
        cuEVM::stack::evm_stack_t &stack,
        const cuEVM::transaction::transaction_t &transaction)
    {
        cgbn_add_ui32(arith.env, gas_used, gas_used, GAS_BASE);
        int32_t error_code = cuEVM::gas_cost::has_gas(
            arith,
            gas_limit,
            gas_used);
        if (error_code == ERROR_SUCCESS)
        {
            bn_t origin;
            transaction.get_sender(arith, origin);

            error_code |= stack.push(arith, origin); 
        }
    }

    __host__ __device__ int32_t CALLER(
        ArithEnv &arith,
        const bn_t &gas_limit,
        bn_t &gas_used,
        cuEVM::stack::evm_stack_t &stack,
        const cuEVM::evm_message_call_t &message)
    {
        cgbn_add_ui32(arith.env, gas_used, gas_used, GAS_BASE);
        int32_t error_code = cuEVM::gas_cost::has_gas(
            arith,
            gas_limit,
            gas_used);
        if (error_code == ERROR_SUCCESS)
        {
            bn_t caller;
            message.get_sender(arith, caller);

            error_code |= stack.push(arith, caller);
        }
    }

    __host__ __device__ int32_t CALLVALUE(
        ArithEnv &arith,
        const bn_t &gas_limit,
        bn_t &gas_used,
        cuEVM::stack::evm_stack_t &stack,
        const cuEVM::evm_message_call_t &message)
    {
        cgbn_add_ui32(arith.env, gas_used, gas_used, GAS_BASE);
        int32_t error_code = cuEVM::gas_cost::has_gas(
            arith,
            gas_limit,
            gas_used);
        if (error_code == ERROR_SUCCESS)
        {
            bn_t call_value;
            message.get_value(arith, call_value);

            error_code |= stack.push(arith, call_value);
        }
    }

    __host__ __device__ int32_t CALLDATALOAD(
        ArithEnv &arith,
        const bn_t &gas_limit,
        bn_t &gas_used,
        cuEVM::stack::evm_stack_t &stack,
        const cuEVM::evm_message_call_t &message)
    {
        cgbn_add_ui32(arith.env, gas_used, gas_used, GAS_VERY_LOW);
        int32_t error_code = cuEVM::gas_cost::has_gas(
            arith,
            gas_limit,
            gas_used);
        if (error_code == ERROR_SUCCESS)
        {
            bn_t index;
            error_code |= stack.pop(arith, index);
            bn_t length;
            cgbn_set_ui32(arith.env, length, cuEVM::word_size);

            cuEVM::byte_array_t data;
            error_code |= message.get_data().get_sub(
                arith,
                index,
                length,
                data);
            error_code |= stack.pushx(
                arith,
                cuEVM::word_size,
                data.data,
                data.size);
        }
        return error_code;
    }

    __host__ __device__ int32_t CALLDATASIZE(
        ArithEnv &arith,
        const bn_t &gas_limit,
        bn_t &gas_used,
        cuEVM::stack::evm_stack_t &stack,
        const cuEVM::evm_message_call_t &message)
    {
        cgbn_add_ui32(arith.env, gas_used, gas_used, GAS_BASE);
        int32_t error_code = cuEVM::gas_cost::has_gas(
            arith,
            gas_limit,
            gas_used);
        if (error_code == ERROR_SUCCESS)
        {
            bn_t length;
            cgbn_set_ui32(arith.env, length, message.get_data().size);

            error_code |= stack.push(arith, length);
        }
        return error_code;
    }

    __host__ __device__ int32_t CALLDATACOPY(
        ArithEnv &arith,
        const bn_t &gas_limit,
        bn_t &gas_used,
        cuEVM::stack::evm_stack_t &stack,
        const cuEVM::evm_message_call_t &message,
        cuEVM::memory::evm_memory_t &memory)
    {
        cgbn_add_ui32(arith.env, gas_used, gas_used, GAS_VERY_LOW);
        int32_t error_code = cuEVM::gas_cost::has_gas(
            arith,
            gas_limit,
            gas_used);

        bn_t memory_offset, data_offset, length;
        error_code |= stack.pop(arith, memory_offset);
        error_code |= stack.pop(arith, data_offset);
        error_code |= stack.pop(arith, length);

        // compute the dynamic gas cost
        cuEVM::gas_cost::memory_cost(
            arith,
            gas_used,
            length);

        // get the memory expansion gas cost
        bn_t memory_expansion_cost;
        error_code |= cuEVM::gas_cost::memory_grow_cost(
            arith,
            memory,
            memory_offset,
            length,
            memory_expansion_cost,
            gas_used);
        
        error_code = cuEVM::gas_cost::has_gas(
            arith,
            gas_limit,
            gas_used);
        
        if (error_code == ERROR_SUCCESS) {
            memory.increase_memory_cost(arith, memory_expansion_cost);
            cuEVM::byte_array_t data;
            error_code |= message.get_data().get_sub(
                arith,
                data_offset,
                length,
                data);
            
            error_code |= memory.set(
                arith,
                data,
                memory_offset,
                length);
        }
        return error_code;
    }

    __host__ __device__ int32_t CODESIZE(
        ArithEnv &arith,
        const bn_t &gas_limit,
        bn_t &gas_used,
        cuEVM::stack::evm_stack_t &stack,
        cuEVM::evm_message_call_t &message)
    {
        cgbn_add_ui32(arith.env, gas_used, gas_used, GAS_BASE);
        int32_t error_code = cuEVM::gas_cost::has_gas(
            arith,
            gas_limit,
            gas_used);
        if (error_code == ERROR_SUCCESS)
        {

            bn_t code_size;
            cgbn_set_ui32(arith.env, code_size, message.get_byte_code().size);

            error_code |= stack.push(arith, code_size);
        }
        return error_code;
    }

    __host__ __device__ int32_t CODECOPY(
        ArithEnv &arith,
        const bn_t &gas_limit,
        bn_t &gas_used,
        cuEVM::stack::evm_stack_t &stack,
        const cuEVM::evm_message_call_t &message,
        cuEVM::memory::evm_memory_t &memory)
    {
        cgbn_add_ui32(arith.env, gas_used, gas_used, GAS_VERY_LOW);
        int32_t error_code = cuEVM::gas_cost::has_gas(
            arith,
            gas_limit,
            gas_used);

        bn_t memory_offset, code_offset, length;
        error_code |= stack.pop(arith, memory_offset);
        error_code |= stack.pop(arith, code_offset);
        error_code |= stack.pop(arith, length);

        // compute the dynamic gas cost
        cuEVM::gas_cost::memory_cost(
            arith,
            gas_used,
            length);

        // get the memory expansion gas cost
        bn_t memory_expansion_cost;
        error_code |= cuEVM::gas_cost::memory_grow_cost(
            arith,
            memory,
            memory_offset,
            length,
            memory_expansion_cost,
            gas_used);
        
        error_code |= cuEVM::gas_cost::has_gas(
            arith,
            gas_limit,
            gas_used);
        
        if (error_code == ERROR_SUCCESS) {
            memory.increase_memory_cost(arith, memory_expansion_cost);
            cuEVM::byte_array_t data;
            error_code |= message.get_data().get_sub(
                arith,
                code_offset,
                length,
                data);
            
            error_code |= memory.set(
                arith,
                data,
                memory_offset,
                length);
        }
        return error_code;
    }

    __host__ __device__ int32_t GASPRICE(
        ArithEnv &arith,
        const bn_t &gas_limit,
        bn_t &gas_used,
        cuEVM::stack::evm_stack_t &stack,
        const cuEVM::block_info_t &block,
        const cuEVM::transaction::transaction_t &transaction)
    {
        cgbn_add_ui32(arith.env, gas_used, gas_used, GAS_BASE);
        int32_t error_code = cuEVM::gas_cost::has_gas(
            arith,
            gas_limit,
            gas_used);
        bn_t gas_price;
        error_code |= transaction.get_gas_price(
            arith,
            block,
            gas_price);
        error_code |= stack.push(arith, gas_price);
        return error_code;
    }

    __host__ __device__ int32_t EXTCODESIZE(
        ArithEnv &arith,
        const bn_t &gas_limit,
        bn_t &gas_used,
        cuEVM::stack::evm_stack_t &stack,
        const cuEVM::state::AccessState &access_state,
        cuEVM::state::TouchState &touch_state)
    {
        // cgbn_add_ui32(arith.env, gas_used, gas_used, GAS_ZERO);
        bn_t address;
        int32_t error_code = stack.pop(arith, address);
        cuEVM::evm_address_conversion(arith, address);
        cuEVM::gas_cost::access_account_cost(
            arith,
            gas_used,
            access_state,
            address);
        error_code |= cuEVM::gas_cost::has_gas(
            arith,
            gas_limit,
            gas_used);
        cuEVM::byte_array_t byte_code;
        error_code |= touch_state.get_code(
            arith,
            address,
            byte_code);
        bn_t code_size;
        cgbn_set_ui32(arith.env, code_size, byte_code.size);
        error_code |= stack.push(
            arith,
            code_size);
        return error_code;
    }

    __host__ __device__ int32_t EXTCODECOPY(
        ArithEnv &arith,
        const bn_t &gas_limit,
        bn_t &gas_used,
        cuEVM::stack::evm_stack_t &stack,
        const cuEVM::state::AccessState &access_state,
        cuEVM::state::TouchState &touch_state,
        cuEVM::memory::evm_memory_t &memory)
    {
        // cgbn_add_ui32(arith.env, gas_used, gas_used, GAS_ZERO);

        bn_t address, memory_offset, code_offset, length;
        int32_t error_code = stack.pop(arith, address);
        cuEVM::evm_address_conversion(arith, address);
        error_code |= stack.pop(arith, memory_offset);
        error_code |= stack.pop(arith, code_offset);
        error_code |= stack.pop(arith, length);

        // compute the dynamic gas cost
        cuEVM::gas_cost::memory_cost(
            arith,
            gas_used,
            length);

        // get the memory expansion gas cost
        bn_t memory_expansion_cost;
        error_code |= cuEVM::gas_cost::memory_grow_cost(
            arith,
            memory,
            memory_offset,
            length,
            memory_expansion_cost,
            gas_used);
        cuEVM::gas_cost::access_account_cost(
            arith,
            gas_used,
            access_state,
            address);

        error_code |= cuEVM::gas_cost::has_gas(
            arith,
            gas_limit,
            gas_used);
        
        if (error_code == ERROR_SUCCESS) {
            memory.increase_memory_cost(arith, memory_expansion_cost);
            cuEVM::byte_array_t byte_code;
            error_code |= touch_state.get_code(
                arith,
                address,
                byte_code);
            cuEVM::byte_array_t data;
            error_code |= byte_code.get_sub(
                arith,
                code_offset,
                length,
                data);
            
            error_code |= memory.set(
                arith,
                data,
                memory_offset,
                length);
        }
        return error_code;
    }

    __host__ __device__ int32_t RETURNDATASIZE(
        ArithEnv &arith,
        const bn_t &gas_limit,
        bn_t &gas_used,
        cuEVM::stack::evm_stack_t &stack,
        const cuEVM::evm_return_data_t &return_data)
    {
        cgbn_add_ui32(arith.env, gas_used, gas_used, GAS_BASE);
        int32_t error_code = cuEVM::gas_cost::has_gas(
            arith,
            gas_limit,
            gas_used);
        if (error_code == ERROR_SUCCESS)
        {
            bn_t length;
            cgbn_set_ui32(arith.env, length, return_data.size);

            error_code |= stack.push(arith, length);
        }
    }

    __host__ __device__ int32_t RETURNDATACOPY(
        ArithEnv &arith,
        const bn_t &gas_limit,
        bn_t &gas_used,
        cuEVM::stack::evm_stack_t &stack,
        cuEVM::memory::evm_memory_t &memory,
        const cuEVM::evm_return_data_t &return_data)
    {
        cgbn_add_ui32(arith.env, gas_used, gas_used, GAS_VERY_LOW);
        int32_t error_code = cuEVM::gas_cost::has_gas(
            arith,
            gas_limit,
            gas_used);

        bn_t memory_offset, data_offset, length;
        error_code |= stack.pop(arith, memory_offset);
        error_code |= stack.pop(arith, data_offset);
        error_code |= stack.pop(arith, length);

        // compute the dynamic gas cost
        cuEVM::gas_cost::memory_cost(
            arith,
            gas_used,
            length);

        // get the memory expansion gas cost
        bn_t memory_expansion_cost;
        error_code |= cuEVM::gas_cost::memory_grow_cost(
            arith,
            memory,
            memory_offset,
            length,
            memory_expansion_cost,
            gas_used);
        
        error_code = cuEVM::gas_cost::has_gas(
            arith,
            gas_limit,
            gas_used);

        if (error_code == ERROR_SUCCESS) {
            memory.increase_memory_cost(arith, memory_expansion_cost);
            cuEVM::byte_array_t data;
            error_code |= return_data.get_sub(
                arith,
                data_offset,
                length,
                data);
            
            error_code |= memory.set(
                arith,
                data,
                memory_offset,
                length);
        }
        return error_code;
    }

    __host__ __device__ int32_t EXTCODEHASH(
        ArithEnv &arith,
        const bn_t &gas_limit,
        bn_t &gas_used,
        cuEVM::stack::evm_stack_t &stack,
        const cuEVM::state::AccessState &access_state,
        cuEVM::state::TouchState &touch_state)
    {
        // cgbn_add_ui32(arith.env, gas_used, gas_used, GAS_ZERO);
        bn_t address;
        int32_t error_code = stack.pop(arith, address);
        cuEVM::evm_address_conversion(arith, address);
        cuEVM::gas_cost::access_account_cost(
            arith,
            gas_used,
            access_state,
            address);
        error_code |= cuEVM::gas_cost::has_gas(
            arith,
            gas_limit,
            gas_used);
        bn_t hash_bn;
        if (touch_state.is_empty_account(arith, address) ||
            touch_state.is_deleted_account(arith, address))
        {
            cgbn_set_ui32(arith.env, hash_bn, 0);
        }
        else
        {
            cuEVM::byte_array_t byte_code;
            error_code |= touch_state.get_code(
                arith,
                address,
                byte_code);
            cuEVM::byte_array_t hash(cuEVM::hash_size);
            CuCrypto::keccak::sha3(
                byte_code.data,
                byte_code.size,
                hash.data,
                hash.size);
            error_code |= hash.to_bn_t(arith, hash_bn);
        }
        error_code |= stack.push(
            arith,
            hash_bn);
        return error_code;
    }

    __host__ __device__ int32_t SELFBALANCE(
        ArithEnv &arith,
        const bn_t &gas_limit,
        bn_t &gas_used,
        cuEVM::stack::evm_stack_t &stack,
        cuEVM::state::TouchState &touch_state,
        const cuEVM::evm_message_call_t &message)
    {
        cgbn_add_ui32(arith.env, gas_used, gas_used, GAS_LOW);
        bn_t address;
        message.get_recipient(arith, address);
        int32_t error_code = cuEVM::gas_cost::has_gas(
            arith,
            gas_limit,
            gas_used);
        if (error_code == ERROR_SUCCESS)
        {

            bn_t balance;
            touch_state.get_balance(
                arith,
                address,
                balance);
            
            error_code |= stack.push(arith, balance);
        }
    }
}